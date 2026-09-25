# DaVinci Resolve External Scripting

This directory contains Python scripts for DaVinci Resolve Studio external scripting via the API. These scripts work together as a set.

## Prerequisites

- **DaVinci Resolve Studio** (external scripting not available in free version)
- Resolve must be running
- **Preferences > System > General > External scripting using = Local**
- Python 3.x

Environment variables are set automatically on macOS by `resolve_env.py`.

## Scripts

### resolve_env.py
Shared helper module that:
- Connects to DaVinci Resolve via the external scripting API
- Sets macOS environment variables if needed
- Provides timecode conversion utilities (SRT ↔ Resolve TC ↔ frames)
- Handles timeline lookup and frame rate detection

**Imported by**: `mark_segments.py`, `build_section_timeline.py`

### mark_segments.py
Adds duration markers to a timeline from SRT-style or Resolve timecodes.

**Features**:
- Auto-detects whether timecodes are absolute (timeline TC) or offset (video start)
- Supports multiple colored markers with names and notes
- Optionally sets timeline In/Out to a selected segment
- Dry-run mode for preview

**Usage**:
```bash
python3 mark_segments.py --timeline "Timeline Name" --inout 1 \
  --seg "01:08:44,266|01:10:04,116|Blue|Segment Name|Description"
```

### build_section_timeline.py
Creates a new timeline from ranges of a source timeline.

**Features**:
- Extracts and reassembles segments back-to-back
- Reproduces all video/audio tracks with properties
- Re-links V/A pairs, copies clip colors and Fusion comps
- Optional grade copying
- Adds range markers
- Self-calibrates API endFrame semantics

**Usage**:
```bash
python3 build_section_timeline.py --source "Source Timeline" \
  --name "New Timeline" --copy-grades --save \
  --range "01:08:44:16|01:10:04:07|Blue|Name|Note"
```

Or from existing markers:
```bash
python3 build_section_timeline.py --source "Source Timeline" \
  --name "New Timeline" --copy-grades --save \
  --from-markers "Marker Name 1" "Marker Name 2"
```

## Documentation

Full specifications are in `4_Formula/`:
- `resolve_env.md` - Helper module spec
- `mark_segments.md` - Marker script spec
- `build_section_timeline.md` - Timeline builder spec
- `resolve_session_2026-09-25.md` - Detailed run log with verified examples

## Known Limitations

- Non-drop-frame timecode only
- Cannot reproduce keyframes, effects, speed changes, or transitions
- Existing markers not deleted (conflicts reported)
- Timeline names must be unique (won't overwrite)
- Audio track sub-types cannot be changed after creation

See individual specs in `4_Formula/` for complete limitation details.
