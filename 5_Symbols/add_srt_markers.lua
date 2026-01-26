-- Script to import SRT subtitles as Timeline Markers in DaVinci Resolve
-- Path to the SRT file is hardcoded for this specific task but can be modified.

local resolve = Resolve()
if not resolve then
    print("Could not connect to DaVinci Resolve. Please run this script within the DaVinci Resolve Console.")
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

print("Current Timeline: " .. timeline:GetName())

-- Get Timeline Framerate
local fps = tonumber(timeline:GetSetting("timelineFrameRate"))
if not fps then
    print("Could not retrieve timeline frame rate. Defaulting to 24.")
    fps = 24
end
print("Timeline FPS: " .. fps)

-- Helper function to convert SRT timecode to Frame IDs
-- SRT Format: HH:MM:SS,ms (e.g., 01:00:00,000)
local function timecodeToFrames(tc, fps)
    local h, m, s, ms = tc:match("(%d+):(%d+):(%d+),(%d+)")
    if h and m and s and ms then
        h = tonumber(h)
        m = tonumber(m)
        s = tonumber(s)
        ms = tonumber(ms)
        
        local totalSeconds = (h * 3600) + (m * 60) + s + (ms / 1000)
        return math.floor(totalSeconds * fps)
    else
        return nil
    end
end

-- Path to the SRT file
local srtPath = [[c:\projects\DavinciResolveScripting\5_Symbols\timeline_tester.srt]]
local file = io.open(srtPath, "r")

if not file then
    print("Error: Could not open file at " .. srtPath)
    return
end

print("Reading SRT file: " .. srtPath)

-- Variables for parsing
local currentStartTime = nil
local currentEndTime = nil
local currentText = {}
local markerCount = 0

for line in file:lines() do
    -- Trim whitespace
    line = line:match("^%s*(.-)%s*$")
    
    if line:find("%-%->") then
        -- This is the timecode line
        -- Example: 01:00:00,000 --> 01:00:02,150
        local startStr, endStr = line:match("(%d%d:%d%d:%d%d,%d%d%d)%s*-%->%s*(%d%d:%d%d:%d%d,%d%d%d)")
        if startStr and endStr then
            currentStartTime = startStr
            currentEndTime = endStr
        end
    elseif line == "" then
        -- Empty line indicates end of a subtitle block. Process it.
        if currentStartTime and #currentText > 0 then
            local frameStart = timecodeToFrames(currentStartTime, fps)
            local frameEnd = timecodeToFrames(currentEndTime, fps)
            
            if frameStart then
                -- Join the text lines
                local noteContent = table.concat(currentText, " ")
                
                -- Marker properties
                -- Using "Cyan" for subtitle markers
                local color = "Cyan"
                local name = "Subtitle"
                local duration = 1
                if frameEnd and frameEnd > frameStart then
                    duration = frameEnd - frameStart
                end
                
                -- AddMarker(frameId, color, name, note, duration, customData)
                local success = timeline:AddMarker(frameStart, color, name, noteContent, duration)
                
                if success then
                    -- print("Added marker at frame " .. frameStart .. ": " .. noteContent)
                    markerCount = markerCount + 1
                else
                    print("Failed to add marker at frame " .. frameStart)
                end
            end
        end
        
        -- Reset for next block
        currentStartTime = nil
        currentEndTime = nil
        currentText = {}
        
    elseif not tonumber(line) then
        -- If it's not a number (index), it's text content
        -- (Indices are usually just "1", "2", etc., so tonumber checks that)
        -- Note: Sometimes text lines start with numbers, but usually indices are on their own line.
        -- A robust parser checks if the previous line was empty, but SRT structure is fairly rigid.
        -- We just assume stray text is content.
        table.insert(currentText, line)
    end
end

-- Handle the last block if the file doesn't end with a newline
if currentStartTime and #currentText > 0 then
    local frameStart = timecodeToFrames(currentStartTime, fps)
    local frameEnd = timecodeToFrames(currentEndTime, fps)
    
    if frameStart then
        local noteContent = table.concat(currentText, " ")
        local duration = 1
        if frameEnd and frameEnd > frameStart then
            duration = frameEnd - frameStart
        end
        timeline:AddMarker(frameStart, "Cyan", "Subtitle", noteContent, duration)
        markerCount = markerCount + 1
    end
end

file:close()
print("Finished. Added " .. markerCount .. " markers to the timeline.")
