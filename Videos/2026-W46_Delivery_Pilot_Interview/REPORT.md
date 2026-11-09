# Work Report — 2026-W46 Delivery Pilot Interview

**Date:** 9 November 2026 · **Branch:** `claude/pensive-pascal-gjnrml` · **Time:** 14:13 → 14:47 (~35 min wall clock, including review replies)

## Summary

Starting from a raw DaVinci Resolve transcript, I built a repeatable weekly edit pipeline:

- a chaptered, corrected interview script
- an approved cut list
- three Resolve Lua scripts that mark the cuts, build the edited timeline and generate corrected captions
- guides for exporting the SRT and for time estimates

All of it was tested against the real exported `raw.srt` using a mock of the Resolve API. **It has not yet been run inside DaVinci Resolve itself.**

| Result (real SRT, mock Resolve) | Value |
|---|---|
| Recording length | 27.6 min (810 subtitles) |
| Cuts matched | 11 / 11 |
| Chapters matched | 14 / 14 |
| Caption corrections applied | 17 / 17 |
| Material cut | 112 s (6.8%), giving an edit of **≈ 25:45** |
| Captions produced | 384, max 2 × 42 chars, 1–6 s, 0 overlaps |

---

## What was done, step by step

| # | Time | Request | What I did | Commit |
|---|------|---------|------------|--------|
| 1 | 14:18 | Create a folder for this week's video and place the script | Created `Videos/2026-W46_Delivery_Pilot_Interview/`. Split the transcript into 14 chapters with speaker turns and listed the likely mishearings | `e6d6776` |
| 2 | 14:20 | Apply confirmed corrections; Marianna = guest, Rifat = host | Applied the 10 confirmed word fixes and the speaker names. Started a change log | `b439a06` |
| 3 | 14:24 | Skool, abstracted/disrupted, "hello Marianna"; plan the cuts | Applied the second round of fixes. Wrote `EDIT_PLAN.md`: 12 cut candidates, chapter markers, workflow, validation checklist | `1b454ce` |
| 4 | 14:36 | Decisions: cut C5 + C10, no Shorts, 0.4 s pauses, Rifat says hello | Marked cuts C1–C11 in `script.md`. Wrote `cut_list.lua`, `mark_cuts.lua` and `apply_cuts.lua`, and tested them on a mock | `a90a9a2` |
| 5 | 14:38 | Estimate the editing time | Wrote `TIME_ESTIMATE.md`: about 45–60 min per video end to end, against 2–4 h by hand (rule of thumb) | `7689e33` |
| 6 | 14:42 | Build the corrected captions; one doc on exporting SRT | Wrote `build_captions.lua`, `corrections.lua` and `4_Formula/export_srt.md` | `d6d8df4` |
| 7 | 14:45 | *(Rifat)* Uploaded `Subtitle 1.srt` via GitHub | — | `91ad4e9` |
| 8 | 14:47 | Use the real SRT | Renamed it to `raw.srt` and stripped Resolve's `<b>` tags. Matched C6 and 5 corrections to the real wording. Produced preview captions and chapters | `c2166ee` |

---

## Files

### In `Videos/2026-W46_Delivery_Pilot_Interview/`

| File | Purpose |
|------|---------|
| `script.md` | Chaptered interview script with Marianna / Rifat labels, corrections applied, cuts shown as ~~strikethrough~~ ✂ |
| `README.md` | Folder index, people, chapter list, change log (Updates 1–5), unconfirmed words |
| `EDIT_PLAN.md` | Cut list, chapters, workflow, test results, how to run in Resolve |
| `cut_list.lua` | Approved cuts and chapters (phrase-anchored) and silence settings |
| `corrections.lua` | 17 caption corrections (5 unconfirmed listed, disabled) |
| `raw.srt` | Resolve transcription export (uploaded by Rifat) |
| `captions_corrected_preview.srt` | Preview captions: corrected, cut, re-timed |
| `youtube_chapters_preview.txt` | Preview YouTube chapters (00:00 → 24:43) |
| `TIME_ESTIMATE.md` | Measured and estimated editing time |
| `REPORT.md` | This report |

### Scripts in `5_Symbols/` (Lua, run from Resolve's console)

| Script | What it does | Changes media? |
|--------|--------------|----------------|
| `mark_cuts.lua` | Finds each cut and chapter phrase in `raw.srt`. Adds RED cut and silence markers and BLUE chapter markers. Writes a match report | No. It only replaces its own markers |
| `apply_cuts.lua` | Builds a new timeline `W46_edit_v1` from everything outside the red markers. Copies the chapters across and writes `youtube_chapters.txt` | No. The original timeline is untouched |
| `build_captions.lua` | Applies the corrections, drops words inside cuts, re-times the rest to the edit and wraps the lines. Writes `captions_corrected.srt` | No |

### Guide

- `4_Formula/export_srt.md`: export the SRT from Resolve, check it, run the scripts and import the captions. Includes a free-version route and troubleshooting.

---

## Decisions made with Rifat

| Topic | Decision |
|-------|----------|
| Speakers | Rifat Erdem Sahin = main host (answers); Marianna = guest (asks). Rifat says "Okay, hello, Marianna." |
| Cuts | C1 pre-roll, C2/C4 redirects, C3 repeated question, C5 "Yes" back-and-forth, C6 stumble, C7 pause, C8 long question, C9 "Great.", C10 managed-service sentence, C11 post-roll |
| Shorts | Removed from scope |
| Silence | Gaps > 0.8 s trimmed to 0.4 s |
| Words | Claude Code, daemons, Voltron, Skool, 300 bots, COBALTS, sixth-form college, Muse, Grokbot, Dots, abstracted, disrupted |

---

## Testing

There is no Lua interpreter or DaVinci Resolve in the cloud session. Instead:

- The scripts ran in **LuaJIT**, the engine Resolve uses, through `lupa`.
- They ran against a **mock Resolve API**: timelines, markers, media pool, AppendToTimeline. The mock asserts that clip pieces don't overlap and leave no gaps.
- They were tested first on a synthetic SRT, then on the **real `raw.srt`**.

Problems the tests caught and fixed:

- `//` integer division isn't valid in LuaJIT, so it was replaced with `math.floor`.
- The last caption ran 0.24 s past the end of the edit, so it is now clamped.
- Resolve's `<b>…</b>` tags would have broken phrase matching, so they are now stripped.
- C6 and 5 corrections used the pasted transcript's wording rather than the SRT's, so they were matched to the real text.
- C7 now reports SKIP rather than FAIL when there is no pause to close.

---

## Open items

1. **Run in Resolve.** Run `mark_cuts.lua`, review the markers, then run `apply_cuts.lua` and `build_captions.lua`. Things that are still unverified:
   - AppendToTimeline `recordFrame` (needs Resolve 18+)
   - the source in/out offsets on the real media
   - the real frame rate (the mock assumed 25 fps)
2. **Silence trimming saves very little (1.5 s).** Resolve's SRT has almost no gaps over 0.8 s. Use Resolve's own silence removal on `W46_edit_v1`, or lower `min_gap_s` (0.6 s → 7.8 s; 0.5 s → 12 s).
3. **Check against the audio:** "the news at home" → "the Muses at home" (inferred).
4. **Unconfirmed words, still off:** test cross → Tesco, top nails → thumbnails, loss of → lots of, stand boxes → sandboxes, I taught → I thought.
5. **Preview files** are valid only if the red markers aren't moved. Otherwise regenerate them in Resolve.
6. The branch is pushed. **No pull request has been opened.**
