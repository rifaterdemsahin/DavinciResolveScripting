#!/usr/bin/env python3
"""Build a NEW DaVinci Resolve timeline from one or more ranges of a source timeline,
placed back to back, reproducing every video and audio track inside those ranges.
The source timeline is only read, never modified.

How it works
  * Creates an empty timeline (fails if the name already exists), copies the source's
    frame rate / resolution (custom settings only if they differ from the project), start
    timecode, track count, audio track sub-types, track names and enable states.
  * For each range, walks every video/audio track, takes each item overlapping the range,
    trims it to the range, and computes its source in/out:
        src_in = item.GetSourceStartFrame() + (max(item.start, range.in) - item.start) * clipFPS/timelineFPS
    then re-creates it with MediaPool.AppendToTimeline([{mediaPoolItem, startFrame, endFrame,
    mediaType (1=video, 2=audio), trackIndex, recordFrame}]).
    endFrame inclusive/exclusive semantics are self-calibrated on the first append (checked
    against the resulting item duration and redone if off by one).
  * Copies non-default TimelineItem properties (transform, crop, opacity, composite, audio
    volume/pan...), clip colour, Fusion comps (export/import), re-links items that were
    linked in the source (SetClipsLinked) and optionally tries CopyGrades.
  * Adds a marker per range (spanning the range) if COLOR/NAME/NOTE are given, optionally copies
    source markers that fall inside the ranges (--copy-markers), makes the new timeline current
    and optionally saves the project (--save).
  * Reports anything that could not be carried over (items with no media pool item such as
    titles/generators, subtitle tracks, speed changes, keyframes, effects/OFX, grades...).

Ranges: repeated --range "IN|OUT[|COLOR|NAME|NOTE]" where IN/OUT are source-timeline timecodes,
either Resolve 'HH:MM:SS:FF' or SRT 'HH:MM:SS,mmm' (frame = round(sec*fps)). They are ABSOLUTE
timeline timecodes (as displayed in Resolve). OUT is exclusive (range length = OUT - IN frames),
matching the duration markers made by mark_segments.py.
Or --from-markers NAME ... to take IN = marker frame, OUT = marker frame + duration from
markers on the source timeline (their colour/name/note are reused).

Example (2026-09-25, project "maggie"):
  python3 build_section_timeline.py --source "Cho master Timeline" \
     --name "1. Multi-Agent Setup via Chief of Staff" --save \
     --range "01:08:44:16|01:10:04:07|Blue|1. Multi-Agent Setup via Chief of Staff|Intro to creating five agents in bulk using a Chief of Staff agent." \
     --range "01:29:42:15|01:31:33:44|Green|2. Reviewing Blue Dots|Showing how Chief of Staff spawned the agents and explaining the blue dots."
"""
import argparse
import os
import sys
import tempfile

from resolve_env import connect, find_timeline, frames_to_tc, parse_any_tc, timeline_fps

SETTINGS = ["timelineFrameRate", "timelineResolutionWidth", "timelineResolutionHeight",
            "timelineOutputResolutionWidth", "timelineOutputResolutionHeight"]
TRACK_TYPES = ["video", "audio"]


def src_range(item, a, b, tl_fps):
    """Source frames [s_in, s_out) for the part of item lying in timeline frames [a, b)."""
    try:
        s0 = item.GetSourceStartFrame()
    except Exception:
        s0 = None
    if s0 is None:
        s0 = item.GetLeftOffset()
    ratio = 1.0
    mpi = item.GetMediaPoolItem()
    try:
        cf = float(mpi.GetClipProperty("FPS"))
        if cf > 0:
            ratio = cf / tl_fps
    except Exception:
        pass
    lo, hi = max(item.GetStart(), a), min(item.GetEnd(), b)
    return (round(s0 + (lo - item.GetStart()) * ratio), round(s0 + (hi - item.GetStart()) * ratio),
            lo, hi)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", help="Source timeline name (default: current)")
    ap.add_argument("--name", required=True, help="Name of the new timeline")
    ap.add_argument("--range", action="append", default=[], help='"IN|OUT[|COLOR|NAME|NOTE]"')
    ap.add_argument("--from-markers", nargs="*", default=None, help="Build ranges from source marker names")
    ap.add_argument("--copy-markers", action="store_true", help="Also copy source markers inside ranges")
    ap.add_argument("--copy-grades", action="store_true", help="Try TimelineItem.CopyGrades onto new video items")
    ap.add_argument("--start-tc", help="Start TC of new timeline (default: same as source)")
    ap.add_argument("--save", action="store_true", help="Save the project afterwards")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    resolve, pm, project = connect()
    mp = project.GetMediaPool()
    print("Resolve", resolve.GetVersionString(), resolve.GetProductName(), "| project:", project.GetName())
    src = find_timeline(project, a.source)
    if not src:
        sys.exit(f"Source timeline not found: {a.source!r}")
    if find_timeline(project, a.name):
        sys.exit(f"A timeline named {a.name!r} already exists; nothing changed.")
    fps = timeline_fps(src)
    s_start = src.GetStartFrame()
    print(f"Source {src.GetName()!r}: fps={fps} startTC={src.GetStartTimecode()} frames {s_start}-{src.GetEndFrame()}")

    # ---- ranges (absolute source frames, OUT exclusive)
    ranges = []
    for r in a.range:
        p = r.split("|")
        rin, rout = parse_any_tc(p[0], fps), parse_any_tc(p[1], fps)
        mk = tuple(p[2:5]) if len(p) >= 5 else None
        ranges.append((rin, rout, mk))
    if a.from_markers is not None:
        ms = src.GetMarkers()
        for nm in a.from_markers:
            hit = [(f, m) for f, m in ms.items() if m["name"] == nm]
            if not hit:
                sys.exit(f"No source marker named {nm!r}")
            f, m = hit[0]
            ranges.append((s_start + int(f), s_start + int(f) + int(m["duration"]), (m["color"], m["name"], m["note"])))
    if not ranges:
        sys.exit("No ranges given.")
    for rin, rout, _ in ranges:
        if not (s_start <= rin < rout <= src.GetEndFrame()):
            sys.exit(f"Range {frames_to_tc(rin, fps)}-{frames_to_tc(rout, fps)} outside source timeline.")

    # ---- plan
    plan, skipped = [], []
    cursor = 0  # offset within new timeline
    for ri, (rin, rout, _) in enumerate(ranges):
        for tt in TRACK_TYPES:
            for ti in range(1, src.GetTrackCount(tt) + 1):
                for it in src.GetItemListInTrack(tt, ti) or []:
                    if it.GetStart() >= rout or it.GetEnd() <= rin:
                        continue
                    if not it.GetMediaPoolItem():
                        skipped.append(f"{tt}{ti} {it.GetName()!r} @{frames_to_tc(it.GetStart(), fps)} (no media pool item: title/generator/effect?)")
                        continue
                    s_in, s_out, lo, hi = src_range(it, rin, rout, fps)
                    span = None
                    try:
                        span = it.GetSourceEndFrame() - it.GetSourceStartFrame() + 1
                    except Exception:
                        pass
                    if span is not None and span != it.GetDuration():
                        skipped.append(f"{tt}{ti} {it.GetName()!r}: speed change/retime not reproduced (src span {span} vs dur {it.GetDuration()})")
                    plan.append(dict(src=it, tt=tt, ti=ti, s_in=s_in, s_out=s_out,
                                     rec=cursor + (lo - rin), want=hi - lo, rng=ri))
        cursor += rout - rin
    for i in range(1, src.GetTrackCount("subtitle") + 1):
        n = len(src.GetItemListInTrack("subtitle", i) or [])
        if n:
            skipped.append(f"subtitle track {i}: {n} items not copied")
    total = cursor
    print(f"Plan: {len(plan)} items, total {total} frames ({total / fps:.3f}s)")
    for p in plan:
        print(f"  {p['tt']}{p['ti']} {p['src'].GetName()} src[{p['s_in']},{p['s_out']}) -> rec+{p['rec']} len {p['want']}")
    if a.dry_run:
        print("Dry run; nothing changed. Would skip:", skipped)
        return

    # ---- create timeline
    new = mp.CreateEmptyTimeline(a.name)
    if not new:
        sys.exit("CreateEmptyTimeline failed.")
    project.SetCurrentTimeline(new)
    diffs = {k: src.GetSetting(k) for k in SETTINGS if str(new.GetSetting(k)) != str(src.GetSetting(k))}
    if diffs:
        new.SetSetting("useCustomSettings", "1")
        for k, v in diffs.items():
            print(f"  setting {k}={v} ->", new.SetSetting(k, str(v)))
    new.SetStartTimecode(a.start_tc or src.GetStartTimecode())
    n_start = new.GetStartFrame()
    for tt in TRACK_TYPES:
        for ti in range(1, src.GetTrackCount(tt) + 1):
            sub = src.GetTrackSubType(tt, ti) if tt == "audio" else None
            if ti > new.GetTrackCount(tt):
                new.AddTrack(tt, sub) if sub else new.AddTrack(tt)
            elif sub and new.GetTrackSubType(tt, ti) != sub:
                skipped.append(f"audio track {ti}: sub-type {new.GetTrackSubType(tt, ti)} (source {sub}) could not be changed")
            new.SetTrackName(tt, ti, src.GetTrackName(tt, ti))
            new.SetTrackEnable(tt, ti, src.GetIsTrackEnabled(tt, ti))

    # ---- append items
    end_adj = -1  # assume inclusive endFrame; calibrated below
    calibrated = False
    made = {}
    for p in plan:
        info = {"mediaPoolItem": p["src"].GetMediaPoolItem(), "startFrame": p["s_in"],
                "mediaType": 1 if p["tt"] == "video" else 2, "trackIndex": p["ti"],
                "recordFrame": n_start + p["rec"]}
        for attempt in range(3):
            info["endFrame"] = p["s_out"] + end_adj
            res = mp.AppendToTimeline([info])
            item = res[0] if res else None
            if not item:
                break
            got = item.GetDuration()
            if got == p["want"] or calibrated:
                calibrated = True
                break
            new.DeleteClips([item], False)
            end_adj += p["want"] - got
            item = None
        if not item:
            skipped.append(f"{p['tt']}{p['ti']} {p['src'].GetName()!r}: AppendToTimeline failed")
            continue
        made[p["src"].GetUniqueId(), p["rng"]] = (p, item)
        # properties
        try:
            sp, np_ = p["src"].GetProperty() or {}, item.GetProperty() or {}
            for k, v in sp.items():
                if k in np_ and np_[k] != v and not item.SetProperty(k, v):
                    skipped.append(f"{p['src'].GetName()!r}: property {k} not copied")
        except Exception as e:
            skipped.append(f"{p['src'].GetName()!r}: property copy error {e}")
        try:
            c = p["src"].GetClipColor()
            if c:
                item.SetClipColor(c)
        except Exception:
            pass
        try:
            for ci in range(1, (p["src"].GetFusionCompCount() or 0) + 1):
                path = os.path.join(tempfile.gettempdir(), f"resolve_comp_{os.getpid()}_{ci}.comp")
                if p["src"].ExportFusionComp(path, ci) and item.ImportFusionComp(path):
                    pass
                else:
                    skipped.append(f"{p['src'].GetName()!r}: Fusion comp {ci} not copied")
        except Exception as e:
            skipped.append(f"{p['src'].GetName()!r}: Fusion copy error {e}")
        if a.copy_grades and p["tt"] == "video":
            try:
                ok = p["src"].CopyGrades([item])
                print(f"  CopyGrades {p['src'].GetName()} -> {ok}")
            except Exception as e:
                skipped.append(f"{p['src'].GetName()!r}: CopyGrades error {e}")
    print("endFrame semantics:", "inclusive" if end_adj == -1 else f"adjust {end_adj}")

    # ---- relink
    for (sid, rng), (p, item) in made.items():
        try:
            partners = [made[(x.GetUniqueId(), rng)][1] for x in p["src"].GetLinkedItems() or []
                        if (x.GetUniqueId(), rng) in made and x.GetUniqueId() != sid]
        except Exception:
            partners = []
        if partners and p["tt"] == "video":
            print(f"  link {p['src'].GetName()} ->", new.SetClipsLinked([item] + partners, True))

    # ---- markers
    offs, cur = [], 0
    for rin, rout, mk in ranges:
        offs.append(cur)
        if mk:
            print(f"  marker {mk[1]!r} @ {frames_to_tc(n_start + cur, fps)} ->",
                  new.AddMarker(cur, mk[0], mk[1], mk[2], rout - rin, ""))
        cur += rout - rin
    if a.copy_markers:
        for f, m in (src.GetMarkers() or {}).items():
            af = s_start + int(f)
            for (rin, rout, _), o in zip(ranges, offs):
                if rin <= af < rout:
                    d = min(int(m["duration"]), rout - af)
                    new.AddMarker(o + af - rin, m["color"], m["name"], m["note"], d, m.get("customData", ""))

    # ---- verify
    print(f"New timeline {new.GetName()!r}: startTC={new.GetStartTimecode()} frames {new.GetStartFrame()}-{new.GetEndFrame()} "
          f"len {new.GetEndFrame() - new.GetStartFrame()} (expected {total}) fps={new.GetSetting('timelineFrameRate')} "
          f"{new.GetSetting('timelineResolutionWidth')}x{new.GetSetting('timelineResolutionHeight')}")
    for tt in TRACK_TYPES:
        for ti in range(1, new.GetTrackCount(tt) + 1):
            items = new.GetItemListInTrack(tt, ti) or []
            print(f"  {tt}{ti} ({new.GetTrackName(tt, ti)}): {len(items)} items")
            for it in items:
                print(f"     {it.GetName()} {frames_to_tc(it.GetStart(), fps)}-{frames_to_tc(it.GetEnd(), fps)} dur {it.GetDuration()} src {it.GetSourceStartFrame()}-{it.GetSourceEndFrame()}")
    print("  markers:", new.GetMarkers())
    print("Not carried over / warnings:", skipped or "none")
    project.SetCurrentTimeline(new)
    if a.save:
        print("SaveProject ->", pm.SaveProject())


if __name__ == "__main__":
    main()
