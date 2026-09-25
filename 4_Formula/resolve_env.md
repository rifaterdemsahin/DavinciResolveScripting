# resolve_env.py - DaVinci Resolve Connection Helper

## Purpose
Shared helper module that connects to DaVinci Resolve via external scripting and provides timecode conversion utilities. This module is imported by other Resolve scripts to establish the connection and handle timecode math.

## Prerequisites
- **DaVinci Resolve Studio** (the free version does not support external scripting)
- Resolve must be running
- **Preferences > System > General > External scripting using = Local**
- macOS environment variables (set automatically by the script if missing):
  ```bash
  export RESOLVE_SCRIPT_API="/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting"
  export RESOLVE_SCRIPT_LIB="/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so"
  export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"
  ```

## Functions

### connect()
Returns `(resolve, project_manager, project)` tuple or exits with error message if:
- DaVinciResolveScript module cannot be imported
- Resolve is not running
- No project is open

### find_timeline(project, name=None)
Returns the timeline with the exact name, or the current timeline if name is None.

### timeline_fps(timeline)
Returns the timeline frame rate as a float.

### Timecode Conversion Functions

#### srt_to_seconds(tc)
Converts SRT-style timecode to seconds.
- **Input**: `'HH:MM:SS,mmm'` (comma or period accepted for milliseconds)
- **Output**: float seconds
- **Formula**: `seconds = h*3600 + m*60 + s + ms/1000`

#### tc_to_frames(tc, fps)
Converts Resolve non-drop-frame timecode to absolute frame count.
- **Input**: `'HH:MM:SS:FF'` (colon or semicolon separator)
- **Output**: absolute frame number
- **Formula**: `frame = ((h*3600 + m*60 + s) * round(fps)) + FF`

#### frames_to_tc(frames, fps)
Converts absolute frame count to Resolve non-drop-frame timecode.
- **Input**: absolute frame number, fps
- **Output**: `'HH:MM:SS:FF'` string
- **Formula**: inverse of tc_to_frames

#### parse_any_tc(tc, fps)
Accepts either SRT or Resolve timecode formats.
- **SRT format** (contains comma or period): `frame = round(seconds * fps)`
- **Resolve format**: uses `tc_to_frames()`
- **Output**: absolute frame number

## API Conventions
The script handles Resolve's frame numbering conventions:
- **Relative frames**: `AddMarker(frameId, ...)` and `GetMarkers()` keys are relative to timeline start
- **Absolute frames**: `SetMarkInOut()`, `GetMarkInOut()`, and item `GetStart()`/`GetEnd()` use absolute record frames

## Limitations
- Assumes **non-drop-frame** timecode
- Drop-frame TC requires different formulas (accounts for dropped frame numbers at specific intervals)
- macOS paths are hardcoded; other platforms need their own paths

## Dependencies
- Python 3.x
- DaVinciResolveScript module (provided by Resolve installation)
