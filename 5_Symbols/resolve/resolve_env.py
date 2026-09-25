"""Shared helpers: connect to DaVinci Resolve via external scripting and convert timecodes.

macOS external-scripting environment (set automatically below if missing):
  RESOLVE_SCRIPT_API="/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting"
  RESOLVE_SCRIPT_LIB="/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so"
  PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"
Requires DaVinci Resolve *Studio* running, with Preferences > System > General >
"External scripting using" = Local.
"""
import os
import re
import sys

MAC_API = "/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting"
MAC_LIB = "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so"


def connect():
    """Return (resolve, project_manager, project). Exits with a message on failure."""
    if sys.platform == "darwin":
        os.environ.setdefault("RESOLVE_SCRIPT_API", MAC_API)
        os.environ.setdefault("RESOLVE_SCRIPT_LIB", MAC_LIB)
    mod_dir = os.path.join(os.environ.get("RESOLVE_SCRIPT_API", MAC_API), "Modules")
    if mod_dir not in sys.path:
        sys.path.append(mod_dir)
    try:
        import DaVinciResolveScript as dvr  # noqa: E402
    except ImportError as e:
        sys.exit(f"Cannot import DaVinciResolveScript ({e}). Check RESOLVE_SCRIPT_API/PYTHONPATH.")
    resolve = dvr.scriptapp("Resolve")
    if not resolve:
        sys.exit("scriptapp('Resolve') returned None: Resolve not running, not Studio, "
                 "or External scripting is not set to Local.")
    pm = resolve.GetProjectManager()
    project = pm.GetCurrentProject()
    if not project:
        sys.exit("No project is open in Resolve.")
    return resolve, pm, project


def find_timeline(project, name=None):
    """Return the timeline with this exact name, or the current timeline if name is None."""
    if not name:
        return project.GetCurrentTimeline()
    for i in range(1, project.GetTimelineCount() + 1):
        tl = project.GetTimelineByIndex(i)
        if tl.GetName() == name:
            return tl
    return None


def timeline_fps(timeline):
    return float(timeline.GetSetting("timelineFrameRate"))


def srt_to_seconds(tc):
    """'HH:MM:SS,mmm' (SRT; '.' also accepted) -> float seconds."""
    m = re.fullmatch(r"\s*(\d+):(\d{1,2}):(\d{1,2})[,.](\d{1,3})\s*", tc)
    if not m:
        raise ValueError(f"Not an SRT timecode: {tc!r}")
    h, mi, s, ms = m.groups()
    return int(h) * 3600 + int(mi) * 60 + int(s) + int(ms.ljust(3, "0")) / 1000.0


def tc_to_frames(tc, fps):
    """'HH:MM:SS:FF' (non-drop) -> absolute frame count."""
    h, m, s, f = (int(x) for x in re.split(r"[:;]", tc.strip()))
    nominal = int(round(fps))
    return ((h * 3600 + m * 60 + s) * nominal) + f


def frames_to_tc(frames, fps):
    """Absolute frame count -> 'HH:MM:SS:FF' (non-drop)."""
    nominal = int(round(fps))
    secs, ff = divmod(int(frames), nominal)
    return "%02d:%02d:%02d:%02d" % (secs // 3600, secs // 60 % 60, secs % 60, ff)


def parse_any_tc(tc, fps):
    """Accept SRT 'HH:MM:SS,mmm' (-> round(seconds*fps)) or Resolve 'HH:MM:SS:FF'. Returns absolute frames."""
    if "," in tc or "." in tc:
        return round(srt_to_seconds(tc) * fps)
    return tc_to_frames(tc, fps)
