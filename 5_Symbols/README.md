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
