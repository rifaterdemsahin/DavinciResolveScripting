# Time Estimate — Weekly Video Edit

Covers how long this week's edit took, and an estimate for future weeks now that the scripts exist.

## 1. This week (2026-W46) — measured from commit times

Wall-clock times, **including the time Rifat spent reviewing and replying** between rounds.

| Round | What | Done at | Wall clock |
|-------|------|---------|-----------|
| 1 | Folder + chaptered script from the raw transcript | 14:18 | ~5 min |
| 2 | Confirmed corrections + speaker names | 14:20 | ~2 min |
| 3 | Second corrections + edit plan | 14:24 | ~4 min |
| 4 | Decisions applied, cut list, `mark_cuts.lua`, `apply_cuts.lua`, mock test | 14:36 | ~12 min |
| | **Total (Claude + review)** | | **~25 min** |

Round 4 was a one-off, because it built the scripts. Future weeks reuse them.

## 2. Future weeks — estimate per video (~30 min interview)

### Claude (in this repo)

| Step | Estimate |
|------|----------|
| Folder, chaptered script, speaker labels, list of likely mishearings | 3–5 min |
| Apply your corrections + change log | 1–2 min per round |
| Cut list (`cut_list.lua`) from the agreed cuts + chapters | 3–5 min |
| Captions with corrections (`captions_corrected.srt`), once built | 3–5 min |
| Commit + push | < 1 min |
| **Claude total** | **~10–20 min** |

### You (in DaVinci Resolve)

| Step | Estimate |
|------|----------|
| Transcribe + export `raw.srt` | 2–5 min (transcription depends on machine) |
| Run `mark_cuts.lua` | < 1 min (the script itself takes seconds) |
| Review the red markers (~10 content cuts + ~40 silence markers) | 10–15 min |
| Run `apply_cuts.lua` | < 1 min |
| Checks from `EDIT_PLAN.md` §5 (pops at cuts, captions, chapters) | 10 min |
| Render | Depends on hardware (often 0.3–1× video length) |
| **Your total (excluding render)** | **~25–35 min** |

### End to end

**About 45–60 min per weekly video**, plus render time and your review/reply gaps.

For comparison, editing a 30-min interview by hand with cuts, silence tightening, chapters and corrected captions typically takes **2–4 hours**. That figure is a rough industry rule of thumb, not something measured here.

## 3. What would change these numbers

- **First real Resolve run (this week): add ~15–30 min** for fixing phrases that don't match the real `raw.srt`, and checking that the clip in/out points line up. That cost is paid once.
- **Few silence gaps in the SRT:** add 5 min to run Resolve's own silence removal instead.
- **Fewer review rounds:** confirming corrections in one reply saves ~5 min of back-and-forth.
- **Longer recordings** scale roughly linearly for review and checks; Claude's part barely changes.
