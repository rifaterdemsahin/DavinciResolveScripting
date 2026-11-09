# Run a Lua script from Workspace > Scripts > Edit (DaVinci Resolve Studio, macOS)

Use this when external scripting (`fuscript`) cannot connect. Scripts run inside Resolve, so no connection is needed.

## 1. Put the script in the Edit scripts folder
Resolve lists files from:

```
~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Edit/
```

(In Finder: **Go > Go to Folder...** (`Shift+Cmd+G`), paste the path above.)

For this project the copies are already installed there, with `VIDEO_DIR` set to this Mac's path:
- `W46_mark_cuts.lua`
- `W46_apply_cuts.lua`
- `W46_build_captions.lua`

Any `.lua` or `.py` file placed in that folder appears in the menu. Restart Resolve if a new file does not show up.

## 2. Open the right page and timeline
1. Open the project.
2. Go to the **Edit** page (bottom bar). The "Edit" submenu is for scripts that work on the timeline.
3. Make the **original interview timeline** the current timeline (double-click it in the Media Pool).

## 3. Run the script
1. Top menu bar: **Workspace > Scripts > Edit**.
2. Click the script name, e.g. **W46_mark_cuts**.
3. Wait for it to finish (markers appear on the timeline).

## 4. See the output
- Open **Workspace > Console** (or `Cmd+Shift+C` if shown in the menu) to read printed messages and errors.
- Choose the **Lua** tab if messages seem missing.

## Order for the W46 video
1. `W46_mark_cuts` then STOP and review `mark_cuts_report.txt` and the red markers.
2. `W46_apply_cuts`
3. `W46_build_captions`

## Troubleshooting
- **Scripts menu is greyed out or has no Edit entry:** the folder is missing or empty. Recheck the path in step 1.
- **Script missing from the menu:** restart Resolve.
- **"No such file" error in the Console:** `VIDEO_DIR` at the top of the script does not match the real folder.
- **No project or timeline error:** open the project and set the timeline current, then rerun.
