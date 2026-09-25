# 5_Symbols - Core Source Code

## Directory Structure

Code should be organized by module/functionality:

* `./workflow_manager.py` - Main entry point.
* `./visuals/`
  * `overlays.py` - Handling video overlays.
  * `graphics.py` - Importing and placing static images/graphics.
* `./metadata/`
  * `markers.py` - Marker generation logic.
  * `chapters.py` - Chapter export/import.
* `./audio/`
  * `normalization.py` - Audio leveling logic.
* `./resolve/` - **DaVinci Resolve external scripting** (Python 3)
  * `resolve_env.py` - Connection helper and timecode conversion
  * `mark_segments.py` - Add duration markers from timecodes
  * `build_section_timeline.py` - Build timelines from ranges
  * See `./resolve/README.md` for usage and `4_Formula/resolve_*.md` for specs

## Setup

Ensure `PYTHONPATH` includes the Resolve scripting modules.
