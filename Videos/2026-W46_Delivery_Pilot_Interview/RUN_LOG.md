# W46 Resolve scripting run log — 2026-11-09

Goal: run `5_Symbols/mark_cuts.lua` -> `apply_cuts.lua` -> `build_captions.lua` against the open
Resolve project, stopping after `mark_cuts.lua` for review of the red markers.

## Environment
- macOS (Darwin), Resolve running (PID 17712), TCP 15000 and 49152 listening on Resolve.
- Scripts' `VIDEO_DIR` is the Windows path `c:\projects\DavinciResolveScripting\Videos\2026-W46_Delivery_Pilot_Interview\`
  (as requested); it does not exist on this Mac.
- fuscript: `/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fuscript`

## Stages
| # | Stage | Result |
|---|-------|--------|
| 1 | `git pull origin claude/pensive-pascal-gjnrml` | OK, already up to date (branch is an ancestor of `main`) |
| 2 | Verify `VIDEO_DIR` in the 3 scripts | Windows path, as requested; needed a Mac-path copy to run here |
| 3 | `mark_cuts.lua` via fuscript (scratch copy, Mac `VIDEO_DIR`, `Resolve = Resolve or ...` prepended) | FAILED: connection |
| 4 | Diagnostic probe `bmd.scriptapp("Resolve")` / `("Fusion")` | both `nil` |
| 5 | Python API (`DaVinciResolveScript.scriptapp('Resolve')`) with RESOLVE_SCRIPT_API/LIB set | `None` |
| 6 | `apply_cuts.lua`, `build_captions.lua` | NOT RUN (blocked by 3) |
| 7 | `mark_cuts_report.txt`, `youtube_chapters.txt`, `captions_corrected.srt` | NOT GENERATED |

## Error output
```
DaVinci Resolve Script Interpreter
Copyright (C) 2005 - 2026 Blackmagic Design Pty. Ltd.

Could not connect to DaVinci Resolve. Run this from Workspace > Scripts.
```
Probe: `bmd: table`, `scriptapp Resolve: nil`, `scriptapp Fusion: nil`.
`nc -z 127.0.0.1 15000` succeeds, so the port is open but the scripting handshake is refused.

## Likely causes / next steps
1. Preferences > System > General > External scripting using must be **Local** (and Resolve restarted after changing it).
2. DaVinci Resolve **Free** only permits scripts launched inside Resolve (Workspace > Scripts or Console), not external.
3. A project must be open with the ORIGINAL interview timeline current.
4. Fallback: copy the scripts into `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Edit/`
   with `VIDEO_DIR` set to this repo's `Videos/2026-W46_Delivery_Pilot_Interview/` and run from Workspace > Scripts.
Then rerun `mark_cuts.lua` and stop to review the red markers before `apply_cuts.lua`.

## Update — retry after confirming Studio edition + open project
- Edition ruled out: user confirmed Resolve **Studio**, project open.
- Re-ran the `bmd.scriptapp("Resolve")` probe **outside the shell sandbox**: still `nil` (so it is not a sandbox/network restriction).
- `davinci_resolve.log` (this session, 2026-11-09 13:41): "Started listener socket at port 15000", "Started script server: 17760"
  — the script server is up, but Resolve rejects external clients. No scripting-level value is readable from prefs files.
- Remaining cause: **Preferences > System > General > External scripting using** is not "Local" (or Resolve was not
  restarted after changing it). Set to Local, quit and reopen Resolve + the project, then rerun `mark_cuts.lua`.
- Alternative that needs no setting: run from Workspace > Scripts inside Resolve.
