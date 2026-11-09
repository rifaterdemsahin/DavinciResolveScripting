# Resolve connection scan report — 2026-11-09

Scope: the three open items (macOS privacy, Studio licence, full quit/relaunch). Read-only scan from a terminal session.

## Summary
| Item | Finding | Verdict |
|------|---------|---------|
| Full quit + relaunch | Resolve PID 49544 started 16:13:05, after the Local setting was saved; log shows "Started script server: 49585" | OK |
| Studio licence | Log: "Running DaVinci Resolve **Studio** v21.2.0.0006", "Checking Licenses"; no licence/dongle/activation errors | No evidence of a problem |
| macOS privacy (TCC) | `TCC.db` is unreadable from here (needs Full Disk Access), so Local Network / Automation grants could **not** be scanned | Unverified, still the top suspect |
| Scripting listeners | Resolve listening on `*:15000` and `*:49152`; `nc 127.0.0.1 15000` connects | Port open |
| App integrity | Signed (Team 9ZGFBWLSYP, hardened runtime), `codesign --verify --deep` clean | OK |
| Python | Resolve bundles Python 3.14.4 (`Resources/ResolvePython`); external Python 3.10/3.11/3.12 and 3.15 all gave `None` | Not a Python-version issue |
| Scripting API module | `Developer/Scripting/Modules/DaVinciResolveScript.py` present (Nov 5); loads and finds `fusionscript.so` | OK |
| `PYTHON3HOME` / `/usr/local/bin/python3` | Neither set/present (only matters for the in-app Python scripts) | Note |
| Installed scripts | `W46_*.lua` in `Fusion/Scripts/Edit/` (created after the 16:13 launch) | Restart Resolve once if the menu doesn't list them |

## Detail
- Resolve 21.2.0 (build 27.0.1 bundle), macOS 27.0.1, arm64.
- Connection attempts, all negative: fuscript Lua `bmd.scriptapp("Resolve")` = nil; Python API with 3.10/3.11/3.12/3.15 = None;
  inside and outside the command sandbox.
- Log noise unrelated to scripting: decoder errors `-12906` (codec plugins), `Failed to parse key (beta)`.
- Other apps hold ports 49152/49153 (Antigravity), unrelated.

## Conclusion
Nothing in the scan shows a licence or relaunch fault. The remaining likely cause is a macOS privacy/permission block that
this scan cannot read, or a Resolve 21.2 behaviour change for external clients.

## Next steps (in order)
1. **Decisive in-app test:** Workspace > Console (Lua tab) and type `print(Resolve())`. If it prints an object, scripting works
   inside Resolve and only the *external* handshake is blocked; then run `W46_mark_cuts` from Workspace > Scripts > Edit.
2. System Settings > Privacy & Security > **Local Network**: enable the terminal app (and Claude Code host app).
   Also check **Automation** and **Files and Folders / Full Disk Access** for DaVinci Resolve and the terminal.
3. To let a scan read TCC: grant the terminal **Full Disk Access**, then rerun `sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "select service,client,auth_value from access"`.
4. If still failing, try the MCP's in-app bridge (`scripts/install_resolve_bridge.py` in `~/mcp/davinci-resolve-mcp`).
