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

## Setup

Ensure `PYTHONPATH` includes the Resolve scripting modules.

## Weekly video edit scripts (Lua, run in Resolve's console)

* `mark_cuts.lua` - reads `Videos/<week>/raw.srt` + `cut_list.lua`, adds RED cut/silence markers and BLUE chapter markers. Non-destructive, re-runnable.
* `apply_cuts.lua` - builds a new edited timeline from everything outside the RED markers, copies chapters, writes `youtube_chapters.txt`. Original timeline untouched.

See `Videos/2026-W46_Delivery_Pilot_Interview/EDIT_PLAN.md` for the workflow. Set `VIDEO_DIR` at the top of each script for a new week.
