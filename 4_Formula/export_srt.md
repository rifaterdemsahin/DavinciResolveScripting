# How to Export an SRT from DaVinci Resolve

One-page guide for getting `raw.srt` out of Resolve for the weekly edit scripts (`mark_cuts.lua`, `build_captions.lua`), and for bringing the corrected captions back in.

Written for Resolve 18.5–20. Menu names can differ slightly between versions.

---

## Before you start

- The interview is on a timeline, ideally **one clip on V1** with its audio.
- The timeline starts at the default **01:00:00:00**. Other start times work too, because the scripts detect the offset.
- The output goes in the week's video folder, named **`raw.srt`**. For example:
  `c:\projects\DavinciResolveScripting\Videos\2026-W46_Delivery_Pilot_Interview\raw.srt`

---

## Step 1 — Create subtitles from the audio

1. Open the **Edit** page and select the interview timeline.
2. Menu: **Timeline → Create Subtitles from Audio…**
3. Settings:

   | Setting | Value |
   |---------|-------|
   | Language | English |
   | Caption preset | Default / Subtitle |
   | Max characters per line | 42 |
   | Lines | Single *or* Double (either works) |
   | Gap between subtitles | **0 frames** |

4. Click **Create**. A subtitle track (**ST1**) appears above the video tracks.

> *Create Subtitles from Audio* is a **Resolve Studio** feature. On the free version, see "No Studio?" at the end.

**Do not fix the text by hand.** Leave the raw words ("cloud code", "NEM", ...). The cut list matches the raw words, and `corrections.lua` fixes them in the captions automatically.

---

## Step 2 — Export the SRT

### Option A — File menu (quickest)

1. Stay on the **Edit** page with the timeline open.
2. Menu: **File → Export → Subtitle…**
3. Format: **SRT**.
4. Save as **`raw.srt`** in the week's video folder.

If the menu item is greyed out, click the subtitle track (ST1) header first, or check that the track is enabled (the eye icon is on).

### Option B — Deliver page

1. Open the **Deliver** page.
2. Render Settings → **Subtitle Settings** → tick **Export Subtitle**.
3. Format: **SRT**, Export as: **Separate file**.
4. Add to the Render Queue and render. The `.srt` is written next to the video.
5. Rename it to `raw.srt` and move it into the week's video folder.

---

## Step 3 — Check the file

Open `raw.srt` in Notepad. It should look like this:

```
1
01:00:00,500 --> 01:00:03,192
More, more. No, when I sit

2
01:00:03,192 --> 01:00:05,885
my head will be up. Okay,
```

- [ ] The times start around **01:00:00**, the timeline start (00:00:00 is also fine).
- [ ] The first lines are the pre-roll ("More, more…") and the last lines are the post-roll ("This could be very long…").
- [ ] Each block is a number, a time line, then text, with a blank line between blocks.

---

## Step 4 — Run the scripts

With the **original** timeline open: **Workspace → Console → Lua**, then run the scripts in this order:

1. `mark_cuts.lua` adds the red cut markers and blue chapter markers. Then review them.
2. `apply_cuts.lua` creates `W46_edit_v1` and `youtube_chapters.txt`.
3. `build_captions.lua` creates **`captions_corrected.srt`** (corrected, re-timed to the edit).

---

## Step 5 — Import the corrected captions

1. **File → Import → Subtitle…** → choose `captions_corrected.srt`. It lands in the Media Pool.
2. Open **`W46_edit_v1`** and drag the subtitle file onto the timeline at **01:00:00:00**. Resolve creates a subtitle track.
3. Spot-check chapters 1, 7 and 14 to make sure the text lines up with the speech.
4. To burn the captions in or upload them separately: **Deliver → Subtitle Settings** → Export Subtitle → *Burn into video*, or *Separate file* for a YouTube upload.

---

## No Studio? (free version)

The free version can't transcribe. Any tool that writes a standard SRT from the audio works instead (for example a Whisper-based transcriber).

- Export the audio from the original timeline and transcribe it.
- Save the result as `raw.srt`. If its times start at 00:00:00, that's fine: the scripts detect the offset.
- Leave the words raw, as above.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| *Create Subtitles from Audio* missing | Needs Resolve Studio 18.5+. Use the free-version route above |
| *Export → Subtitle* greyed out | Select the ST1 track header, make sure it is enabled, and be on the Edit page |
| `mark_cuts.lua` says "Could not open SRT" | Check the file name is exactly `raw.srt` and `VIDEO_DIR` at the top of the script points to the folder |
| Many cuts FAIL | The transcription wording differs. Edit the phrases in `cut_list.lua` to match `raw.srt` |
| Few `SIL` (silence) markers | Resolve wrote the subtitles back-to-back with no gaps. Use Resolve's silence removal on `W46_edit_v1` instead |
| Captions drift late or early | The SRT came from a different timeline than the one with the markers. Re-export from the original timeline |
