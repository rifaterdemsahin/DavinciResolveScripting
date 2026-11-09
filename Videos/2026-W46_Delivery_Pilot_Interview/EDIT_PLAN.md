# Edit Plan — 2026-W46 Delivery Pilot Interview

Goal: turn the raw recording into a tight, chaptered long-form video with correct captions. Use the DaVinci Resolve scripting already in `5_Symbols/` so this can be repeated every week.

Status: **PLAN — nothing implemented yet.** Review the cut list in section 2, mark each row Keep or Cut, then the build steps in section 4 can go ahead.

---

## 1. Workflow overview

```
Raw clip on timeline
   │  (Resolve: Transcribe → Export subtitles as SRT, with timecodes)
   ▼
raw.srt  ──►  cut_list.json  (cuts defined by start/end PHRASES, not timecodes)
   │                │
   │                ▼
   │        mark_cuts.lua      → RED markers on cut ranges, BLUE markers on chapters
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

## 2. Cut list (needs approval)

Legend: **CUT** = remove · **TRIM** = shorten, keep the meaning · **KEEP?** = your call.

| # | Ch. | Speaker | From (phrase) | To (phrase) | Action | Reason |
|---|-----|---------|---------------|-------------|--------|--------|
| C1 | Pre-roll | both | "More, more." | "Yes, it's recording." | **CUT** | Setup chatter before the interview starts |
| C2 | 4 | Marianna | "Okay, you jumped already to bots." | "I think it's too fast." | **TRIM** | Redirect. Start the chapter at "Let's talk about AI skills." |
| C3 | 4 | Marianna | "Let's talk about AI skills. What does it mean?" | "AI can do much more than that." | **CUT** (keep 2nd ask) | The question is asked twice. Keep "Let's talk about AI skills first. How do you understand AI skills and why it's important?" |
| C4 | 6 | Marianna | "Ok, but let's come back a little bit. Again," | — | **TRIM** | Redirect filler. Start at "There are software programs, there are bots…" |
| C5 | 6 | both | "Yes." / "But this chatbot can create a code." / "Yes." … | "Where is agent in between?" | **KEEP?** | Quick back-and-forth. It feels natural, but tightening the pauses would help |
| C6 | 8 | Rifat | "A car driver has more places than a go than a rider" | — | **TRIM** | Verbal stumble. Cut to "A pilot has more places to go than a car driver." if the audio allows |
| C7 | 8 | Rifat | "To answer your question." (1st) | "The engineering has to be learned" | **TRIM** | Likely pause/restart between the two paragraphs. Close the gap |
| C8 | 11 | Marianna | "I mean that it takes time and as early as we are starting to work…" | "…You have to adopt your mind to that, right?" | **TRIM** | Long question. Keep the case of asking the AI how long it takes to absorb the information, then the closing question |
| C9 | 11 | Marianna | "Great." | — | **CUT** | Filler before the next chapter |
| C10 | 12 | Rifat | "And if the business is not, they can get managed service…" | — | **KEEP?** | Unclear sentence. Re-record a voice-over line, or cut it |
| C11 | Post-roll | both | "This could be very long." | "Because our..." | **CUT** | After the close |
| C12 | all | both | silences > 0.8 s | — | **TRIM** | Tighten dead air: cut silences to 0.3 s (Resolve: Edit → Remove Silence, or done by script) |

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

Also add **YELLOW** markers for shorts/clip candidates:

- "I have 300 bots running at the same time… I write one bot to write other bots" (Ch. 3)
- The Rider / Driver / Pilot explanation (Ch. 4)
- "If they can't find the food in Tesco, they will go to Sainsbury…" (Ch. 7)
- "Stay like an Amish… the greatest investment of humanity" (Ch. 14)

---

## 4. Implementation steps

### Step 1 — Get timecodes (manual, in Resolve)
1. Select the clip, then **Timeline → Create Subtitles from Audio** (or Transcribe).
2. **File → Export → Subtitle** as `raw.srt` and save it in this folder.

### Step 2 — `cut_list.json` (new file, this folder)
Turn the approved rows from section 2 into data:
```json
{
  "fps_source": "timeline",
  "cuts":     [{"id": "C1", "from": "More, more.", "to": "Yes, it's recording.", "action": "cut"}],
  "chapters": [{"n": 1, "at": "Let's talk about technologies, AI, progress", "title": "Why technology?"}],
  "clips":    [{"at": "I have 300 bots running", "to": "write other bots"}],
  "silence":  {"min_gap_s": 0.8, "keep_s": 0.3}
}
```

### Step 3 — `5_Symbols/mark_cuts.lua` (new)
- Reuse the SRT parser and `timecodeToFrames` from `5_Symbols/add_srt_markers.lua`, and the sentence joining from `markers_sentences.lua`.
- Fuzzy-match each `from`/`to` phrase against the joined SRT text (lowercase, punctuation stripped) to get start and end frames.
- `timeline:AddMarker(frame, "Red", "CUT C1", note, durationFrames)` for cuts, `"Blue"` for chapters and `"Yellow"` for clips.
- Print a report: every phrase found or **not found**, so nothing is skipped silently.
- Uses only marker APIs and changes no media, so it is safe to run more than once. Run `delete_all_markers` first (see `3_Simulation/delete_all_markers.png`).

### Step 4 — Review pass (manual)
Scrub through every red marker in Resolve and adjust marker in/out points by hand where a breath or word ending needs it. The marker positions are what gets cut.

### Step 5 — `5_Symbols/apply_cuts.lua` (new)
- Read the RED markers back with `timeline:GetMarkers()` and work out the keep ranges as the complement of the cut ranges.
- Create a new timeline `W46_edit_v1` with `mediaPool:CreateEmptyTimeline()`. Then call `mediaPool:AppendToTimeline({{mediaPoolItem=..., startFrame=a, endFrame=b}, ...})` once per keep range, for both the video and audio items.
- This is non-destructive: the original timeline stays as the master, and you can roll back by deleting `W46_edit_v1`.
- Copy the BLUE and YELLOW markers onto the new timeline, shifted by the total length cut before each one.

### Step 6 — Silence tightening
Do this on `W46_edit_v1` only, after the content cuts, so silence trimming can't move the phrase matching. Use Resolve's built-in silence removal, or detect silences from the SRT gaps (gaps between subtitle entries longer than `min_gap_s`) and add them as extra cut ranges in Step 5.

### Step 7 — Captions
- `captions_corrected.srt`: apply the README change-log replacements to `raw.srt` (Claude Code, daemons, Voltron, Skool, COBALTS, sixth-form college, Muse, Grokbot, Dots, Marianna, abstracted, disrupted, 300 bots), then shift the timings to match the edit.
- Import it onto `W46_edit_v1` as a subtitle track.

### Step 8 — Exports
- `youtube_chapters.txt`: generated from the BLUE markers on `W46_edit_v1` (`00:00 Why technology?` …). The first chapter must be at 00:00.
- Render the long-form video, plus one vertical short per YELLOW marker.

---

## 5. Validation (to `7_Testing_known/`)

- [ ] Every cut phrase and every chapter phrase was matched (the report shows nothing not found)
- [ ] `W46_edit_v1` duration = original − sum of cuts (± 1 frame per cut)
- [ ] No audio pops at the cut points (listen at each former red marker)
- [ ] Captions line up with speech after the cuts; spot-check chapters 1, 7 and 14
- [ ] Chapter list pastes into YouTube and creates chapters (first one at 00:00, at least 3 chapters, each ≥ 10 s)
- [ ] Original timeline is unchanged

---

## 6. Open decisions for Rifat

1. C5 and C10: keep or cut?
2. Do the YouTube shorts from the YELLOW markers belong in this week's scope, or next week's?
3. Silence threshold: is 0.8 s → 0.3 s right for your pacing?
4. Opening line: who says "Okay, hello, Marianna"? (This decides the speaker label and whether the cold open starts on Rifat.)
