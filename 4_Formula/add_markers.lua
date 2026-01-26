-- Add Markers to Footage (Lua Version)
-- This script adds a global marker to the timeline and individual markers to all clips on Video Track 1.

-- Try to get the Resolve object
local resolve = Resolve()
if not resolve then
    -- Fallback for external execution context if 'Resolve' isn't global (rarely works without fuscript setup, but good practice)
    print("Could not connect to DaVinci Resolve. Please run this script within the DaVinci Resolve Console or using fuscript.")
    return
end

local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then
    print("No project is loaded.")
    return
end

local timeline = project:GetCurrentTimeline()

if not timeline then
    print("No current timeline found. Please open a timeline.")
    return
end

print("Working on timeline: " .. timeline:GetName())

-- 1. Add a marker to the Timeline (Global)
-- Frame 48 (approx 2 seconds @ 24fps)
local timelineFrame = 48
-- AddMarker(frameId, color, name, note, duration, customData)
if timeline:AddMarker(timelineFrame, "Cyan", "Timeline Marker (Lua)", "Added by Lua script", 1) then
    print("Added Cyan marker at global frame " .. timelineFrame)
else
    print("Failed to add global marker")
end

-- 2. Add markers to Clips (Footage) on Video Track 1
local trackType = "video"
local trackIndex = 1
-- GetItemListInTrack returns a table (list) of TimelineItems
local items = timeline:GetItemListInTrack(trackType, trackIndex)

if not items or #items == 0 then
    print("No clips found on Video Track 1.")
    return
end

print("Found " .. #items .. " clips on Video Track 1.")

for i, item in ipairs(items) do
    -- Add a marker at the halfway point of the clip
    local duration = item:GetDuration()
    
    -- Calculate middle (local frame), ensure it's an integer
    local midPoint = math.floor(duration / 2)
    
    local success = item:AddMarker(midPoint, "Yellow", "Clip Middle (Lua)", "Checked by Lua", 1)
    
    if success then
        print("Added Yellow marker to clip '" .. item:GetName() .. "' at local frame " .. midPoint)
    else
        print("Failed to add marker to clip '" .. item:GetName() .. "'")
    end
end
