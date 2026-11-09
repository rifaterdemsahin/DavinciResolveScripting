# Resolve MCP setup log — 2026-11-09

## What was done
1. Confirmed Resolve Studio, project open, **External scripting using = Local**, Automatic scripted actions = Allow all,
   and restarted Resolve (new PID 49544, log 16:13 "Started script server").
2. Cloned `samuelgursky/davinci-resolve-mcp` (MIT) to `~/mcp/davinci-resolve-mcp` (outside this repo).
3. Ran the installer by hand (the Claude Code auto-mode classifier blocks running downloaded installers):
   `cd ~/mcp/davinci-resolve-mcp && python3 install.py --clients claude-code --update-policy never`
   - Created venv with **Python 3.15.2**, installed `mcp[cli]` and Node deps.
   - Wrote Claude Code config to `~/mcp/davinci-resolve-mcp/.mcp.json` (server `davinci-resolve`,
     `src/server.py`, with RESOLVE_SCRIPT_API / RESOLVE_SCRIPT_LIB / PYTHONPATH env).
   - Update checks disabled (`--update-policy never`).
4. Installer result: "API: Module loads OK" but "Resolve: Running, but the scripting bridge returned no connection".
   A first attempt had a `BEGIN failed--compilation aborted.` error before this successful run (cause not captured).

## Retry result (Python version test)
Probed `DaVinciResolveScript.scriptapp('Resolve')` with Homebrew **Python 3.12, 3.11 and 3.10**,
outside the shell sandbox: all returned `None`. So the Python 3.15 hint from the installer is **not** the cause.
Lua `bmd.scriptapp("Resolve")` via fuscript also returns `nil`.

## Still open
- Resolve's scripting server starts (log: "Started script server") but rejects external clients.
- Not yet checked: macOS Privacy (Local Network / Automation), Studio license activation, and whether Resolve was
  launched in a way that blocks external scripting.
- Note: Claude Code only loads the MCP from the project/user config; `~/mcp/davinci-resolve-mcp/.mcp.json` is local to that
  folder. To use it here, register it with `claude mcp add` (or copy the entry to this repo's `.mcp.json`).
- Working fallback: Workspace > Scripts > Edit with the `W46_*.lua` copies (see RUN_FROM_WORKSPACE_SCRIPTS.md).
