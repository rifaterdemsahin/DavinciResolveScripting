# Enable External Scripting in DaVinci Resolve (macOS and Windows)

External scripts (`fuscript`, Python) can only control Resolve when **External scripting using** is set to **Local**
(or **Network**). With **None**, `bmd.scriptapp("Resolve")` returns `nil` and fuscript prints
`Could not connect to DaVinci Resolve`.

## Steps
1. Open **DaVinci Resolve Studio** (external scripting is a Studio feature).
2. Open Preferences:
   - macOS: menu **DaVinci Resolve > Preferences...** (shortcut `Cmd + ,`)
   - Windows: menu **DaVinci Resolve > Preferences...** (shortcut `Ctrl + ,`)
3. Go to the **System** tab, then **General** in the left list.
4. Find **External scripting using** (under "General" / "Remote"). Change the dropdown from **None** to **Local**.
   - Local = scripts on this computer only (what we need).
   - Network = scripts from other computers too (not needed, less safe).
5. Click **Save**.
6. **Quit Resolve completely** (macOS: `Cmd + Q`; Windows: close and check the Task Manager) and reopen it.
   The setting is read at startup, so skipping the restart is the most common reason it still fails.
7. Reopen the project and make the **original interview timeline** the current timeline.

## Verify
Run this probe with fuscript (macOS path shown):

```
"/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fuscript" -l lua probe.lua
```

`probe.lua`:
```lua
print(bmd.scriptapp("Resolve"))
```

- Prints something like `Resolve (table)`: connected, you can run `mark_cuts.lua`.
- Prints `nil`: still not enabled; recheck steps 4 to 6.

## Alternative (no setting needed)
Run the script from inside Resolve: **Workspace > Scripts** (copy the `.lua` into
`~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Edit/` on macOS first), or paste it
into **Workspace > Console** (Lua tab). Set `VIDEO_DIR` at the top of the script to this machine's path to the
`Videos/2026-W46_Delivery_Pilot_Interview/` folder.
