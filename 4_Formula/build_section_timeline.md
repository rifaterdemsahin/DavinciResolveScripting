# build_section_timeline.py - Build Timeline from Ranges

## Purpose
Creates a NEW DaVinci Resolve timeline from one or more ranges of a source timeline, placing segments back-to-back and reproducing all video and audio tracks. The source timeline is read-only and never modified.

## How It Works

### 1. Timeline Creation
- Creates empty timeline (fails if name already exists)
- Copies source settings: frame rate, resolution, start timecode
- Recreates track structure: track count, audio sub-types, names, enable states

### 2. Item Reconstruction
For each range, walks every video/audio track:
- Takes each item overlapping the range
- Trims to range boundaries
- Computes source in/out with clip-speed compensation:
  ```
  src_in = item.GetSourceStartFrame() + (max(item.start, range.in) - item.start) * (clipFPS / timelineFPS)
  ```
- Re-creates via `MediaPool.AppendToTimeline([clipInfo])`

### 3. clipInfo Structure
```python
{
  "mediaPoolItem": item.GetMediaPoolItem(),
  "startFrame": src_in,
  "endFrame": src_out + end_adj,  # inclusive/exclusive semantics calibrated on first append
  "mediaType": 1,  # 1=video, 2=audio
  "trackIndex": ti,
  "recordFrame": absolute_record_frame
}
```

### 4. Property Copying
- Non-default TimelineItem properties (transform, crop, opacity, composite, audio volume/pan)
- Clip color
- Fusion comps (export/import via temp files)
- Re-links items that were linked in source (`SetClipsLinked`)
- Optionally copies grades (`CopyGrades`)

### 5. Markers
- Adds one marker per range spanning the range (if COLOR/NAME/NOTE provided)
- Optionally copies source markers inside ranges (`--copy-markers`)

### 6. Finalization
- Makes new timeline current
- Optionally saves project (`--save`)

## Inputs / CLI Arguments

### Required
- `--name NAME` - Name of the new timeline (must not exist)
- One of:
  - `--range "IN|OUT[|COLOR|NAME|NOTE]"` (repeatable) - Absolute timeline timecodes
  - `--from-markers NAME...` - Takes IN=marker frame, OUT=marker+duration from source markers

### Optional
- `--source NAME` - Source timeline name (default: current timeline)
- `--copy-markers` - Also copy source markers inside ranges
- `--copy-grades` - Try `TimelineItem.CopyGrades()` on new video items
- `--start-tc TC` - Start timecode of new timeline (default: same as source)
- `--save` - Save project after build
- `--dry-run` - Preview plan without creating timeline

## Timecode Formats
- **Resolve**: `HH:MM:SS:FF` (non-drop-frame)
- **SRT**: `HH:MM:SS,mmm` converted via `frame = round(seconds * fps)`
- All timecodes are **absolute timeline timecodes** (as displayed in Resolve)
- OUT is **exclusive**: `length = OUT - IN` frames

## API Calls Used

### Timeline Creation
- `mediaPool.CreateEmptyTimeline(name)`
- `project.SetCurrentTimeline(timeline)`
- `timeline.SetSetting(key, value)`
- `timeline.SetStartTimecode(tc)`
- `timeline.AddTrack(type, subtype)`
- `timeline.SetTrackName/SetTrackEnable/SetTrackSubType()`

### Item Reconstruction
- `mediaPool.AppendToTimeline([clipInfo])`
- `timeline.GetItemListInTrack(type, index)`
- `item.GetMediaPoolItem()`
- `item.GetSourceStartFrame()`, `item.GetLeftOffset()`
- `item.GetStart()`, `item.GetEnd()`, `item.GetDuration()`
- `mediaPoolItem.GetClipProperty("FPS")`

### Property Copying
- `item.GetProperty()`, `item.SetProperty(key, value)`
- `item.GetClipColor()`, `item.SetClipColor(color)`
- `item.ExportFusionComp(path, compIndex)`, `item.ImportFusionComp(path)`
- `item.GetLinkedItems()`, `timeline.SetClipsLinked(items, linked)`
- `item.GetUniqueId()` - stable item identifier across API proxies
- `item.CopyGrades([targetItems])`

### Markers
- `timeline.AddMarker(frameId, color, name, note, duration, customData)`
- `timeline.GetMarkers()`

### Project
- `projectManager.SaveProject()`

## endFrame Semantics Calibration
The script self-calibrates whether `clipInfo["endFrame"]` is inclusive or exclusive:
1. First append assumes inclusive (`endFrame = src_out - 1`)
2. Checks resulting item duration
3. If off by one, adjusts and redoes append
4. All subsequent appends use the calibrated offset

Verified behavior in Resolve Studio 21.1: **exclusive** (endFrame not included).

## Verification Steps
1. Run with `--dry-run` to review the plan
2. Check console output:
   - Number of items and total frames
   - Each item's source range and record position
3. Run without `--dry-run` to create timeline
4. Verify new timeline properties:
   - Frame count matches expected total
   - Track structure matches source
   - Items are correctly positioned
5. Check markers match ranges
6. Verify linked items (V/A pairs)

## Prerequisites
- DaVinci Resolve Studio running with External scripting = Local
- An open project with a source timeline
- Media pool items must be accessible (no offline clips in ranges)
- `resolve_env.py` module in the same directory or PYTHONPATH

## Known Limitations

### Not Reproduced
- Keyframes/animation
- OFX/ResolveFX and Fairlight effects
- Audio clip gain keyframes/EQ
- Speed changes/retime curves (warned)
- Transitions
- Titles/generators and other items with no media pool item (listed as skipped)
- Subtitle tracks (listed)
- Grades use `CopyGrades()` (current layer only; untested on complex grades)

### Other Limitations
- Cannot change existing audio track sub-types (reported if different)
- Assumes non-drop-frame timecode
- `GetSourceEndFrame()` can read one frame past actual end (trust `GetDuration()`)
- Refuses to overwrite existing timeline name - delete or rename old one first
- No partial copying of effects - it's all or nothing per category

### Alternative Approach Not Used
`DuplicateTimeline()` + deleting content outside ranges would preserve effects, but:
- API cannot razor/trim items
- Only works when ranges align with clip edges
- More destructive workflow

## Example Usage
```bash
python3 build_section_timeline.py --source "Cho master Timeline" \
  --name "1. Multi-Agent Setup via Chief of Staff" --copy-grades --save \
  --range "01:08:44:16|01:10:04:07|Blue|1. Multi-Agent Setup via Chief of Staff|Intro to creating five agents in bulk using a Chief of Staff agent." \
  --range "01:29:42:15|01:31:33:44|Green|2. Reviewing Blue Dots|Showing how Chief of Staff spawned the agents and explaining the blue dots."
```

Or using markers:
```bash
python3 build_section_timeline.py --source "Cho master Timeline" \
  --name "1. Multi-Agent Setup via Chief of Staff" --copy-grades --save \
  --from-markers "1. Multi-Agent Setup via Chief of Staff" "2. Reviewing Blue Dots"
```
