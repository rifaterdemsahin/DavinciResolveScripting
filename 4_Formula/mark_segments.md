# mark_segments.py - Add Duration Markers to Timeline

## Purpose
Adds duration markers (with color, name, and note) to a DaVinci Resolve timeline from SRT-style timecodes, and optionally sets the timeline In/Out points to a selected segment.

## Inputs / CLI Arguments

### Required
- `--seg "IN|OUT|COLOR|NAME|NOTE"` (repeatable) - Segment definitions
  - **IN**: Start timecode (SRT format `HH:MM:SS,mmm` or Resolve format `HH:MM:SS:FF`)
  - **OUT**: End timecode (same formats)
  - **COLOR**: Marker color (e.g. Blue, Green, Yellow, Red, Cyan, etc.)
  - **NAME**: Marker name/title
  - **NOTE**: Marker description/note

### Optional
- `--timeline NAME` - Timeline name (default: current timeline)
- `--mode {auto|absolute|offset}` - Timecode interpretation mode (default: `auto`)
- `--inout N` - Set timeline In/Out to segment N (1-based; 0 = don't touch, default: 1)
- `--dry-run` - Preview without making changes

## Timecode Interpretation Modes

### Frame Conversion Formula
For SRT timecodes: `frame = round(seconds * fps)`

### Modes
1. **absolute**: Values are timeline timecode (timeline usually starts at 01:00:00:00)
   - `offset_frames = round(sec*fps) - timeline.GetStartFrame()`

2. **offset**: Values are offsets from video start (e.g. transcript timestamps)
   - `offset_frames = round(sec*fps)`

3. **auto** (default): 
   - Uses whichever mode places ALL segments inside the timeline
   - If both fit, prefers `offset`
   - If neither fits, aborts without changes

## API Calls Used
- `project.GetCurrentProject()` / `project.SetCurrentTimeline()`
- `timeline.GetStartFrame()`, `timeline.GetEndFrame()`, `timeline.GetStartTimecode()`
- `timeline.GetSetting("timelineFrameRate")`
- `timeline.AddMarker(frameId, color, name, note, duration, customData)` - frameId is **relative to timeline start**
- `timeline.SetMarkInOut(inFrame, outFrame)` - frames are **absolute record frames**
- `timeline.GetMarkInOut()`, `timeline.GetMarkers()`

## Range Semantics
- Marker duration uses **OUT exclusive**: `duration = OUT - IN` frames
- Matches the duration markers made by this script

## Verification Steps
1. Run the script with `--dry-run` to preview marker placements
2. Check the console output shows:
   - Interpretation mode selected (absolute/offset)
   - Each segment's relative and absolute frame positions
   - Duration in frames
3. Run without `--dry-run` to apply markers
4. Verify with `timeline.GetMarkers()` output
5. Check timeline In/Out if `--inout` was set

## Prerequisites
- DaVinci Resolve Studio running with External scripting = Local
- An open project with a timeline
- `resolve_env.py` module in the same directory or PYTHONPATH

## Known Limitations
- **Does not delete existing markers** - if a marker already exists at a frame, `AddMarker()` fails and reports the conflict
- Only handles non-drop-frame timecode
- Previous timeline In/Out is replaced (not merged)
- No undo mechanism - markers must be manually deleted to revert

## Example Usage
```bash
python3 mark_segments.py --timeline "Cho master Timeline" --inout 1 \
  --seg "01:08:44,266|01:10:04,116|Blue|1. Multi-Agent Setup via Chief of Staff|Intro to creating five agents in bulk using a Chief of Staff agent." \
  --seg "01:29:42,250|01:31:33,733|Green|2. Reviewing Blue Dots|Showing how Chief of Staff spawned the agents and explaining the blue dots."
```
