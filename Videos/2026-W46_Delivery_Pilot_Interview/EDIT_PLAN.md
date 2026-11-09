# Edit Plan — 2026-W46 Delivery Pilot Interview

Goal: turn the raw recording into a tight, chaptered long-form video with correct captions. Use the DaVinci Resolve scripting already in `5_Symbols/` so this can be repeated every week.

Status: **Decisions made, scripts written** (`5_Symbols/mark_cuts.lua`, `5_Symbols/apply_cuts.lua`, `cut_list.lua`). They were tested against a mock Resolve API with a synthetic SRT. The next step is to run them in Resolve on the real `raw.srt` (section 4).

---

## 1. Workflow overview

```
Raw clip on timeline
   │  (Resolve: Transcribe → Export subtitles as SRT, with timecodes)
   ▼
raw.srt  ──►  cut_list.lua   (cuts defined by start/end PHRASES, not timecodes)
   │                │
   │                ▼
   │        mark_cuts.lua      → RED markers on cut ranges + silences, BLUE markers on chapters
   │                │            (review pass in Resolve; nothing deleted yet)
   │                ▼
   │        apply_cuts.lua     → builds NEW timeline "W46_edit_v1" from the keep ranges
   │                             (original timeline left untouched)
   ▼
captions_corrected.srt  (raw.srt + corrections from README change log, re-timed to edit)
   ▼
youtube_chapters.txt    (generated from the BLUE chapter markers on the edited timeline)
```

Why phrases instead of timecodes: the script text already exists and has been reviewed. Matching phrases against the SRT finds the frame numbers automatically, so the cut list stays readable and survives a re-transcribe.

---

## 2. Cut list (approved)

Legend: **CUT** = remove · **TRIM** = shorten, keep the meaning 

| # | Ch. | Speaker | From (phrase) | To (phrase) | Action | Reason |
|---|-----|---------|---------------|-------------|--------|--------|
| C1 | Pre-roll | both | "More, more." | "Yes, it's recording." | **CUT** | Setup chatter before the interview starts |
| C2 | 4 | Marianna | "Okay, you jumped already to bots." | "I think it's too fast." | **TRIM** | Redirect. Start the chapter at "Let's talk about AI skills." |
| C3 | 4 | Marianna | "Let's talk about AI skills. What does it mean?" | "AI can do much more than that." | **CUT** (keep 2nd ask) | The question is asked twice. Keep "Let's talk about AI skills first. How do you understand AI skills and why it's important?" |
| C4 | 6 | Marianna | "Ok, but let's come back a little bit. Again," | — | **TRIM** | Redirect filler. Start at "There are software programs, there are bots…" |
| C5 | 6 | both | "Yes." / "But this chatbot can create a code." / "Yes." … | "Where is agent in between?" | **CUT** | Back-and-forth. Rifat: cut |
| C6 | 8 | Rifat | "A car driver has more places than a go than a rider" | — | **TRIM** | Verbal stumble. Cut to "A pilot has more places to go than a car driver." if the audio allows |
| C7 | 8 | Rifat | "To answer your question." (1st) | "The engineering has to be learned" | **TRIM** | Likely pause/restart between the two paragraphs. Close the gap |
| C8 | 11 | Marianna | "I mean that it takes time and as early as we are starting to work…" | "…You have to adopt your mind to that, right?" | **TRIM** | Long question. Keep the case of asking the AI how long it takes to absorb the information, then the closing question |
| C9 | 11 | Marianna | "Great." | — | **CUT** | Filler before the next chapter |
| C10 | 12 | Rifat | "And if the business is not, they can get managed service…" | — | **CUT** | Unclear sentence. Rifat: cut |
| C11 | Post-roll | both | "This could be very long." | "Because our..." | **CUT** | After the close |
| C12 | all | both | silences > 0.8 s | — | **TRIM** | Tighten dead air: cut silences to **0.4 s** (Rifat) |

Expected result: roughly 8–12% shorter, with no content lost.

---

## 3. Chapter markers (BLUE)

Placed at the first word of each chapter's opening question, after the cuts:

| Marker | Starts at phrase | YouTube chapter title |
|--------|------------------|-----------------------|
| 1 | "Let's talk about technologies, AI, progress" | Why technology? |
| 2 | "Can you help us to understand the history" | 40 years of technology |
| 3 | "Right, it seems that today we don't need programmers" | Do we still need programmers? |
| 4 | "Let's talk about AI skills first" | Rider → Driver → Pilot |
| 5 | "Okay, can you help us to understand the journey" | The journey to pilot |
| 6 | "There are software programs, there are bots" | Software vs chatbots vs agents |
| 7 | "This bot, when you are saying \"bot\"" | Agent vs bot |
| 8 | "Let's talk a little bit about coding" | Do we need to learn coding? |
| 9 | "Then we are turning to the subject why continuous learning" | Continuous learning |
| 10 | "I know that you like to learn a lot" | Why teach? |
| 11 | "Let's talk a little bit about the mind digestion system" | Self-learning & COBALTS |
| 12 | "Let's talk a few sentences about the workshop" | Cambridge workshops & Skool |
| 13 | "Are there any requirements" | Requirements to join |
| 14 | "If someone is thinking, \"Oh, AI isn't for me,\"" | "AI isn't for me" |

Shorts / YELLOW clip markers: **removed from scope** (Rifat).

---

## 4. Implementation steps

### Step 1 — Get timecodes (manual, in Resolve)
Full guide: [`4_Formula/export_srt.md`](../../4_Formula/export_srt.md)
1. Select the clip, then **Timeline → Create Subtitles from Audio** (or Transcribe).
2. **File → Export → Subtitle** as `raw.srt` and save it in this folder.

### Step 2 — `cut_list.lua` ✅ written
This is plain Lua data rather than JSON, because Resolve's Lua console has no JSON library. Each cut has a start anchor (`from` / `after` / `START`) and an end anchor (`to` / `before` / `END`).

The phrases must match the **raw** transcription, not the corrected `script.md`. For example, the opening is anchored on "Okay, hello" because the raw text says "NEM".

### Step 3 — `5_Symbols/mark_cuts.lua` ✅ written
- Reuse the SRT parser and `timecodeToFrames` from `5_Symbols/add_srt_markers.lua`, and the sentence joining from `markers_sentences.lua`.
- Fuzzy-match each `from`/`to` phrase against the joined SRT text (lowercase, punctuation stripped) to get start and end frames.
- `timeline:AddMarker(frame, "Red", "CUT C1", note, durationFrames, "edit:cut")` for cuts, `"SIL"` markers for silences and `"Blue"` markers for chapters.
- Frames are relative to the timeline start: the 01:00:00:00 SRT offset is subtracted (see `6_Semblance/markers_fix.md`).
- Writes `mark_cuts_report.txt` next to the cut list.
- Print a report: every phrase found or **not found**, so nothing is skipped silently.
- Uses only marker APIs and changes no media, so it is safe to run more than once. It removes only its own markers (`customData` starting with `edit:`), so your own markers stay.
- Pad cuts (C7, C9) report SKIP rather than FAIL if there is no pause to close.

### Step 4 — Review pass (manual)
Scrub through every red marker in Resolve and adjust marker in/out points by hand where a breath or word ending needs it. The marker positions are what gets cut.

### Step 5 — `5_Symbols/apply_cuts.lua` ✅ written
- Read the RED markers back with `timeline:GetMarkers()` and work out the keep ranges as the complement of the cut ranges.
- Create a new timeline `W46_edit_v1` with `mediaPool:CreateEmptyTimeline()`. Then call `mediaPool:AppendToTimeline({{mediaPoolItem=..., startFrame=a, endFrame=b}, ...})` once per keep range, for both the video and audio items.
- This is non-destructive: the original timeline stays as the master, and you can roll back by deleting `W46_edit_v1`.
- Copies the BLUE markers onto the new timeline, shifted by the total length cut before each one, and writes `youtube_chapters.txt`.
- Refuses to run if `W46_edit_v1` already exists, or if you are on it.
- If a separate mic recording sits on its own audio track, set `EXTRA_AUDIO_TRACKS = {2}`.

### Step 6 — Silence tightening ✅ built into Step 3
`mark_cuts.lua` adds a red `SIL` marker for every gap between subtitle entries longer than 0.8 s, trimming it to 0.4 s.

Limitation: this only finds pauses that show up as gaps in the SRT. If Resolve's subtitles run back-to-back with no gaps, few silences will be found. In that case, run Resolve's own silence removal on `W46_edit_v1` instead.

### Step 7 — Captions ✅ `5_Symbols/build_captions.lua` written
- Run it on the **original** timeline after `apply_cuts.lua`.
- It reads `raw.srt` and applies `corrections.lua`, matching word by word across subtitle boundaries and keeping punctuation.
- It drops the words inside red markers and shifts the rest onto the edited timeline.
- It regroups the words into captions: max 2 lines × 42 chars, 1–6 s each, with a break at a sentence end or a pause over 0.6 s.
- Output: `captions_corrected.srt`. Import it with File → Import → Subtitle and drag it onto `W46_edit_v1`.
- Mock test: all 16 corrections applied, no cut text left, 0 overlaps, no line over 42 chars, and the last caption ends exactly at the edit's end.

### Step 8 — Exports
- `youtube_chapters.txt`: generated from the BLUE markers on `W46_edit_v1` (`00:00 Why technology?` …). The first chapter must be at 00:00.
- Render the long-form video.

---

## 5. Validation (to `7_Testing_known/`)

- [ ] Every cut phrase and every chapter phrase was matched (the report shows nothing not found)
- [ ] `W46_edit_v1` duration = original − sum of cuts (± 1 frame per cut)
- [ ] No audio pops at the cut points (listen at each former red marker)
- [ ] Captions line up with speech after the cuts; spot-check chapters 1, 7 and 14
- [ ] Chapter list pastes into YouTube and creates chapters (first one at 00:00, at least 3 chapters, each ≥ 10 s)
- [ ] Original timeline is unchanged

---

## 6. Decisions (answered 2026-11-09)

1. C5 and C10: **cut both**
2. Shorts / YELLOW markers: **removed**
3. Silence: gaps > 0.8 s are tightened to **0.4 s**
4. "Okay, hello, Marianna" is said by **Rifat**. The line is split off as his in `script.md`, and the video opens on Rifat.

## 7. Test run (mock Resolve, synthetic SRT)

`mark_cuts.lua` and `apply_cuts.lua` were run in LuaJIT (the same Lua engine Resolve uses) against a mock of the Resolve API. The mock used a 30-minute synthetic SRT built from the original wording, with pauses between speaker turns.

- All 10 content cuts and 14 chapters were matched (C7 was skipped: there was no pause).
- The new timeline length was exactly the original length minus the cuts.
- The pieces were placed with no gaps or overlaps.
- The first chapter was at 00:00.
- A user marker on the original timeline survived re-runs.

Timings in the real video will differ. These still need checking in Resolve: AppendToTimeline `recordFrame` support (Resolve 18+), and source frame offsets on your media.

## 7b. Test run on the real `raw.srt`

| Check | Result |
|-------|--------|
| Cuts matched | 11 / 11, after fixing C6 to the raw wording |
| Chapters matched | 14 / 14 |
| Corrections applied | 17 / 17 |
| Content cut | ~110 s |
| Silence cut (gaps > 0.8 s → 0.4 s) | **only 2 gaps, 1.5 s** |
| Total cut | 112 s of 27.6 min (6.8%), giving an edit of about 25:45 |
| Captions | 384, max 2 × 42 chars, 1–6 s each, 0 overlaps |

**Silence finding:** Resolve trims subtitle timings tightly, so almost no SRT gaps are over 0.8 s. Gaps measured in `raw.srt`:

| Gaps over | Count | Seconds saved by trimming to 0.4 s |
|-----------|-------|-----------------------------------|
| 0.5 s | 55 | 12.0 s |
| 0.6 s | 24 | 7.8 s |
| 0.8 s | 2 | 1.5 s |

Even trimming every gap would save only ~15 s. Longer pauses inside a subtitle line can't be seen in the SRT. To tighten pacing further, run Resolve's own silence removal on `W46_edit_v1`, or lower `min_gap_s` in `cut_list.lua`.

The preview files (`captions_corrected_preview.srt`, `youtube_chapters_preview.txt`) come from this run. They match the real edit only if the red markers are not moved. Otherwise re-run `build_captions.lua` and `apply_cuts.lua` in Resolve.

## 8. How to run (in Resolve)

1. ✅ Done: `raw.srt` is in the repo. Pull the branch so your local folder has it.
2. Check `VIDEO_DIR` at the top of both scripts. It defaults to `c:\projects\DavinciResolveScripting\Videos\2026-W46_Delivery_Pilot_Interview\`.
3. With the original timeline open, go to Workspace → Console → Lua and run `mark_cuts.lua`. Fix any FAIL lines in `cut_list.lua`, then re-run.
4. Scrub through the red markers and drag or resize any that clip a word.
5. Run `apply_cuts.lua`. This creates `W46_edit_v1` and `youtube_chapters.txt`.
