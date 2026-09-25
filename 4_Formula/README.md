# 4_Formula - Guides and Best Practices

## DaVinci Resolve Scripting API References

* Refer to the official "README.txt" and examples in `%PROGRAMDATA%\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting\`.

## Implementation Guides (Planned)

1. **Adding Overlays**: How to use `AppendToTimeline` effectively.
2. **Markers**: Understanding the `AddMarker` method parameters (frameId, color, name, note, duration).
3. **Audio**: methods for accessing audio clips and applying simple gain or effects (Note: API access to deep audio plugins may be limited, verify `GetAutomation` capabilities).

## Best Practices

* Always check for `resolve` object existence.
* Use `Lock()` on timeline manipulations if performing batch operations to prevent UI refresh lag.
* Handle timecode conversion accurately (frames vs strings).

## Console Scripting Examples

### Add Markers to Footage (`add_markers.py`)

This script demonstrates how to:

1. Connect to the Resolve API from an external Python console.
2. Add a global marker to the active timeline.
3. Iterate through video clips on Track 1 and add markers to the middle of each clip.

**Usage:**

```bash
python add_markers.py
```

*Ensure DaVinci Resolve is open and scripting is active.*

### Add Markers to Footage (`add_markers.lua`)

The Lua equivalent of the above script. Useful for running directly inside the DaVinci Resolve Console's "Lua" tab or via `fuscript`.

**Usage:**

1. Open DaVinci Resolve.
2. Go to `Workspace` > `Console` > `Lua`.
3. Paste the contents of `add_markers.lua` or run it using `dofile()`.

## External Scripting (2026-09-25)

### resolve_env.md
Specification for the shared connection and timecode conversion helper module (`5_Symbols/resolve/resolve_env.py`).

### mark_segments.md
Specification for adding duration markers from SRT-style timecodes with auto-detection of absolute vs offset interpretation (`5_Symbols/resolve/mark_segments.py`).

### build_section_timeline.md
Specification for building new timelines from ranges of a source timeline, reproducing all tracks and properties (`5_Symbols/resolve/build_section_timeline.py`).

### resolve_session_2026-09-25.md
Detailed run log for the 2026-09-25 session: environment, commands executed, exact values, results, and verification.
