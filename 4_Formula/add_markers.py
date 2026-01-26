#!/usr/bin/env python
import sys

def get_resolve():
    """
    Attempt to load the DaVinciResolveScript module.
    Checks standard environment variables and default Windows paths.
    """
    try:
        # Try importing if PYTHONPATH is already set
        import DaVinciResolveScript as dvr_script
        return dvr_script.scriptapp("Resolve")
    except ImportError:
        # Fallback to default Windows installation path
        default_path = "C:\\Program Files\\Blackmagic Design\\DaVinci Resolve\\Developer\\Scripting\\Modules"
        if default_path not in sys.path:
            sys.path.append(default_path)
        
        try:
            import DaVinciResolveScript as dvr_script
            return dvr_script.scriptapp("Resolve")
        except ImportError:
            print("Error: Could not import 'DaVinciResolveScript'.")
            print("Ensure %RESOLVE_SCRIPT_API% is set or standard paths are accessible.")
            return None

def add_markers_to_footage():
    resolve = get_resolve()
    if not resolve:
        print("Could not connect to DaVinci Resolve. Ensure it is running.")
        sys.exit(1)

    project_manager = resolve.GetProjectManager()
    project = project_manager.GetCurrentProject()
    
    if not project:
        print("No project is loaded.")
        sys.exit(1)
        
    timeline = project.GetCurrentTimeline()
    
    if not timeline:
        print("No current timeline found. Please open a timeline.")
        sys.exit(1)
        
    print(f"Working on timeline: {timeline.GetName()}")
    
    # 1. Add a marker to the Timeline (Global)
    # Let's add one at frame 48 (approx 2 seconds @ 24fps)
    timeline_frame = 48
    timeline.AddMarker(timeline_frame, "Cyan", "Timeline Marker", "Added by Python script", 1)
    print(f"Added Cyan marker at global frame {timeline_frame}")

    # 2. Add markers to Clips (Footage) on Video Track 1
    # This iterates through clips and adds a marker to the actual clip instance
    items = timeline.GetItemListInTrack("video", 1)
    
    if not items:
        print("No clips found on Video Track 1.")
        return

    for item in items:
        # We can add markers to the TimelineItem (the clip on the timeline)
        # Note: The frameId for a generic TimelineItem marker is relative to the start of the item (0 = start of clip event)
        
        # Add a marker at the halfway point of the clip
        start = item.GetStart()
        end = item.GetEnd()
        duration = item.GetDuration()
        
        # Safely calculate middle (local frame)
        mid_point = int(duration / 2)
        
        success = item.AddMarker(mid_point, "Yellow", "Clip Middle", "Checked", 1)
        
        if success:
            print(f"Added Yellow marker to clip '{item.GetName()}' at local frame {mid_point}")
        else:
            print(f"Failed to add marker to clip '{item.GetName()}'")

if __name__ == "__main__":
    add_markers_to_footage()
