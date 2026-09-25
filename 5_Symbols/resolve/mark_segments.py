#!/usr/bin/env python3
"""Add duration markers (and optionally the timeline In/Out) to a DaVinci Resolve timeline
from SRT-style timecodes (HH:MM:SS,mmm).

Frame conversion: frame = round(seconds * fps).
Interpretation of timecodes (--mode):
  absolute : values are timeline timecode (timeline usually starts at 01:00:00:00), i.e.
             offset_frames = round(sec*fps) - timeline.GetStartFrame()
  offset   : values are offsets from the start of the video (e.g. transcript time), i.e.
             offset_frames = round(sec*fps)
  auto     : (default) use whichever places ALL segments inside the timeline; if both fit prefer
             'offset'; if neither fits, abort without changing anything.

AddMarker(frameId, ...) takes frames relative to the timeline start; SetMarkInOut takes absolute
record frames. Marker duration = out - in (frames). The In/Out is set to the segment chosen by
--inout (1-based; 0 = don't touch). Existing markers are never deleted; a marker frame that is
already occupied makes AddMarker fail and is reported.

Segments are given as repeated --seg "IN|OUT|COLOR|NAME|NOTE".

Example (the values used on 2026-09-25, project "maggie"):
  python3 mark_segments.py --timeline "Cho master Timeline" --inout 1 \
    --seg "01:08:44,266|01:10:04,116|Blue|1. Multi-Agent Setup via Chief of Staff|Intro to creating five agents in bulk using a Chief of Staff agent." \
    --seg "01:29:42,250|01:31:33,733|Green|2. Reviewing Blue Dots|Showing how Chief of Staff spawned the agents and explaining the blue dots."
"""
import argparse
import sys

from resolve_env import connect, find_timeline, frames_to_tc, srt_to_seconds, timeline_fps


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--timeline", help="Timeline name (default: current timeline)")
    ap.add_argument("--seg", action="append", required=True, help='"IN|OUT|COLOR|NAME|NOTE"')
    ap.add_argument("--mode", choices=["auto", "absolute", "offset"], default="auto")
    ap.add_argument("--inout", type=int, default=1, help="Segment number to set as timeline In/Out (0 = skip)")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    resolve, pm, project = connect()
    print("Resolve", resolve.GetVersionString(), resolve.GetProductName(), "| project:", project.GetName())
    tl = find_timeline(project, a.timeline)
    if not tl:
        sys.exit(f"Timeline not found: {a.timeline!r}")
    if a.timeline and project.GetCurrentTimeline().GetName() != tl.GetName():
        project.SetCurrentTimeline(tl)
    fps = timeline_fps(tl)
    start, end = tl.GetStartFrame(), tl.GetEndFrame()
    length = end - start
    print(f"Timeline {tl.GetName()!r}: fps={fps} startTC={tl.GetStartTimecode()} frames {start}-{end} ({length})")

    segs = []
    for s in a.seg:
        parts = s.split("|")
        if len(parts) != 5:
            sys.exit(f"Bad --seg (need 5 '|' fields): {s}")
        i, o, color, name, note = parts
        segs.append((round(srt_to_seconds(i) * fps), round(srt_to_seconds(o) * fps), color, name, note))

    def fits(shift):
        return all(0 <= i - shift < o - shift <= length for i, o, *_ in segs)

    mode = a.mode
    if mode == "auto":
        fa, fo = fits(start), fits(0)
        print(f"fits absolute={fa} offset={fo}")
        if not (fa or fo):
            sys.exit("Neither interpretation places all segments inside the timeline; nothing changed.")
        mode = "offset" if fo else "absolute"
    shift = start if mode == "absolute" else 0
    if not fits(shift):
        sys.exit(f"Segments do not fit the timeline in {mode} mode; nothing changed.")
    print("Using interpretation:", mode)

    for n, (i, o, color, name, note) in enumerate(segs, 1):
        fi, fo_ = i - shift, o - shift
        print(f"Seg {n}: {name!r} in {frames_to_tc(fi + start, fps)} (rel {fi}) "
              f"out {frames_to_tc(fo_ + start, fps)} (rel {fo_}) dur {fo_ - fi} {color}")
        if not a.dry_run:
            ok = tl.AddMarker(fi, color, name, note, fo_ - fi, "")
            print("   AddMarker ->", ok)
    if a.inout and not a.dry_run:
        i, o = segs[a.inout - 1][:2]
        print("previous In/Out:", tl.GetMarkInOut())
        print("SetMarkInOut ->", tl.SetMarkInOut(i - shift + start, o - shift + start))
    print("Markers:", tl.GetMarkers())
    print("In/Out:", tl.GetMarkInOut())


if __name__ == "__main__":
    main()
