-- DAVINCI RESOLVE LUA SCRIPT --
-- SYNCED FOR 60 FPS WITH TIMELINE & SRT DURATION MAPPING --

local resolve = Resolve()
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then print("No project is open.") return end

-- ============================================
-- CONFIGURATION - YOUR EXACT TIMECODE DATA
-- ============================================

local targetTimelineName = "Timeline 1"
local TIMELINE_FPS = 60

-- Timeline boundaries
local TIMELINE_START_TC = "01:00:00:00"
local TIMELINE_END_TC = "01:02:17:29"

-- SRT boundaries
local SRT_START_TC = "01:00:00,000"
local SRT_END_TC = "01:02:11,716"

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function srtToSeconds(tc_string)
    -- SRT format: HH:MM:SS,mmm
    local h, m, s, ms = tc_string:match("(%d+):(%d+):(%d+),(%d+)")
    if not h then return 0 end
    return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) + (tonumber(ms) / 1000)
end

function timecodeTcToSeconds(tc_string, fps)
    -- Timecode format: HH:MM:SS:FF
    local h, m, s, f = tc_string:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end
    return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) + (tonumber(f) / fps)
end

function isSemanticEnd(text)
    local clean = text:gsub("%s+$", "")
    local lastChar = clean:sub(-1)
    if lastChar == '"' or lastChar == "'" then lastChar = clean:sub(-2, -2) end
    if not (lastChar == "." or lastChar == "?" or lastChar == "!") then return false end
    
    if lastChar == "." then
        local lastWord = clean:lower():match("(%a+)%.['\"]?$")
        local abbrList = {"mr", "mrs", "ms", "dr", "prof", "sr", "jr", "st", "vs", "etc", "no", "fig", "approx"}
        if lastWord then
            for _, val in ipairs(abbrList) do
                if lastWord == val then return false end
            end
        end
    end
    return true
end

-- ============================================
-- CALCULATE SCALING FACTOR
-- ============================================

-- Convert all boundaries to seconds
local timeline_start_secs = timecodeTcToSeconds(TIMELINE_START_TC, TIMELINE_FPS)
local timeline_end_secs = timecodeTcToSeconds(TIMELINE_END_TC, TIMELINE_FPS)
local srt_start_secs = srtToSeconds(SRT_START_TC)
local srt_end_secs = srtToSeconds(SRT_END_TC)

-- Calculate durations
local timeline_duration = timeline_end_secs - timeline_start_secs
local srt_duration = srt_end_secs - srt_start_secs

-- Calculate scale factor (if SRT is shorter/longer than timeline)
local scale_factor = timeline_duration / srt_duration

-- Offset from SRT start to timeline start
local offset_secs = timeline_start_secs - (srt_start_secs * scale_factor)

print("========================================")
print("SYNCHRONIZATION CALCULATION")
print("========================================")
print("Timeline: " .. TIMELINE_START_TC .. " → " .. TIMELINE_END_TC)
print("Timeline Duration: " .. string.format("%.3f", timeline_duration) .. " seconds")
print("")
print("SRT: " .. SRT_START_TC .. " → " .. SRT_END_TC)
print("SRT Duration: " .. string.format("%.3f", srt_duration) .. " seconds")
print("")
print("Scale Factor: " .. string.format("%.6f", scale_factor))
print("Global Offset: " .. string.format("%.3f", offset_secs) .. " seconds")
print("========================================")

-- ============================================
-- FIND & CLEAR TIMELINE
-- ============================================

local timeline = nil
local timelineCount = project:GetTimelineCount()

for i = 1, timelineCount do
    local t = project:GetTimelineByIndex(i)
    if t:GetName() == targetTimelineName then timeline = t break end
end

if not timeline then print("Error: Could not find '" .. targetTimelineName .. "'") return end

print("Target Timeline: " .. timeline:GetName())

-- GET TIMELINE START FRAME IN PROJECT
-- The timeline's first frame in the project (not the first frame of content)
local timelineStartFrame = timeline:GetStartFrame()
print("Timeline Start Frame (in project): " .. timelineStartFrame)

-- Clear old markers
local markers = timeline:GetMarkers()
for frame, _ in pairs(markers) do timeline:DeleteMarkerAtFrame(frame) end
print("Cleared old markers.")

-- ============================================
-- MARKER COLORS
-- ============================================

local markerColors = {"Blue", "Cyan", "Green", "Yellow", "Red", "Pink", "Purple", "Fuchsia", "Rose", "Lavender", "Mint", "Teal", "Cream", "Cocoa", "Sand"}

-- ============================================
-- SRT DATA
-- ============================================

local srt_content = [[
1
01:00:00,000 --> 01:00:02,150
and plate structure that we are using on

2
01:00:02,150 --> 01:00:05,166
the delivery pilot workshops is we take

3
01:00:05,166 --> 01:00:06,916
on any project and we

4
01:00:06,916 --> 01:00:08,416
focus on delivering it.

5
01:00:08,416 --> 01:00:10,366
We really don't know what we are going to

6
01:00:10,366 --> 01:00:13,349
take on, but we have a generic method to

7
01:00:13,349 --> 01:00:16,050
be able to capture our goals, our

8
01:00:16,050 --> 01:00:18,800
imaginary world, the user interfaces that

9
01:00:18,800 --> 01:00:20,916
we go to, the environments that we are

10
01:00:20,916 --> 01:00:23,383
using, the formulas that we are getting

11
01:00:23,383 --> 01:00:26,366
from the AI, the symbols that are created

12
01:00:26,366 --> 01:00:28,833
by the AI and the semblance, the errors

13
01:00:29,033 --> 01:00:31,533
that are getting fixed, we create a

14
01:00:31,533 --> 01:00:32,466
gamified environment

15
01:00:32,466 --> 01:00:34,233
where we connect all the dots.

16
01:00:38,116 --> 01:00:39,916
That's a really interesting concept.

17
01:00:40,666 --> 01:00:43,599
So the delivery pilot is about navigating

18
01:00:43,599 --> 01:00:46,533
unknown projects using a generic

19
01:00:46,533 --> 01:00:49,050
template-based approach that includes

20
01:00:49,050 --> 01:00:51,150
gamified elements to connect all the

21
01:00:51,150 --> 01:00:54,316
dots, from imaginary worlds to formulas

22
01:00:54,316 --> 01:00:56,833
from AI and even fixing errors.

23
01:00:57,250 --> 01:00:59,500
That sounds like a very immersive and

24
01:00:59,500 --> 01:01:00,533
practical way to learn.

25
01:01:01,066 --> 01:01:03,616
So what specific gamified elements are

26
01:01:03,616 --> 01:01:04,616
you planning to incorporate?

27
01:01:05,716 --> 01:01:08,966
So what I'm trying to incorporate is such

28
01:01:08,966 --> 01:01:10,966
as in this talk, you are asking me

29
01:01:10,966 --> 01:01:12,150
questions that are not

30
01:01:12,150 --> 01:01:13,683
written on the prompter.

31
01:01:14,133 --> 01:01:17,033
The gamified elements are solving the

32
01:01:17,033 --> 01:01:19,099
problems and coming back to the real.

33
01:01:19,550 --> 01:01:22,500
If my goal is running a Python web

34
01:01:22,500 --> 01:01:26,933
server, my goal has to become deploying

35
01:01:26,933 --> 01:01:29,916
this on code spaces and turning it on.

36
01:01:30,266 --> 01:01:32,866
Could be an example or deploying it to my

37
01:01:32,866 --> 01:01:34,449
local or deploying to my

38
01:01:34,449 --> 01:01:36,466
premise and turning it on.

39
01:01:36,466 --> 01:01:38,133
And I'm going to do this as an

40
01:01:38,133 --> 01:01:40,216
enterprise, not just single entity

41
01:01:40,216 --> 01:01:42,566
myself, but everybody in the company.

42
01:01:44,000 --> 01:01:48,516
That's a really insightful comparison.

43
01:01:49,150 --> 01:01:51,650
So the gamified elements are like the

44
01:01:51,650 --> 01:01:53,883
unscripted questions you're getting now.

45
01:01:54,416 --> 01:01:56,433
They push you to solve problems and

46
01:01:56,433 --> 01:01:58,533
relate everything back to the real world,

47
01:01:58,866 --> 01:02:00,916
like getting a Python web server up and

48
01:02:00,916 --> 01:02:02,933
running across an entire enterprise.

49
01:02:03,550 --> 01:02:05,550
It sounds like a very dynamic approach.

50
01:02:06,183 --> 01:02:08,333
So what's the biggest challenge you

51
01:02:08,333 --> 01:02:10,300
anticipate people will face while going

52
01:02:10,300 --> 01:02:11,716
through these gamified workshops?
]]

-- ============================================
-- PROCESS SRT & CREATE MARKERS
-- ============================================

local sentenceCount = 1
local colorIndex = 1
local currentEndTime = ""
local currentSentenceAccumulator = ""

for line in srt_content:gmatch("[^\r\n]+") do
    if line:find("%-%->") then
        local _, endStr = line:match("(%d+:%d+:%d+,%d+) %-%-> (%d+:%d+:%d+,%d+)")
        if endStr then currentEndTime = endStr end
        
    elseif not line:match("^%d+$") and not line:find("%-%->") then
        if currentSentenceAccumulator == "" then
            currentSentenceAccumulator = line
        else
            currentSentenceAccumulator = currentSentenceAccumulator .. " " .. line
        end
        
        if isSemanticEnd(line) then
            -- Convert SRT end time to seconds
            local srt_secs = srtToSeconds(currentEndTime)
            
            -- Apply scaling and offset
            local timeline_secs = (srt_secs * scale_factor) + offset_secs
            
            -- Convert to frame number at 60 FPS, then add timeline's absolute start frame
            local relativeFrame = math.floor(timeline_secs * TIMELINE_FPS)
            local frameID = timelineStartFrame + relativeFrame
            
            -- Get marker color
            local assignedColor = markerColors[colorIndex]
            colorIndex = colorIndex + 1
            if colorIndex > #markerColors then colorIndex = 1 end
            
            -- Add marker to timeline
            timeline:AddMarker(frameID, assignedColor, "Sentence " .. sentenceCount, currentSentenceAccumulator, 1)
            
            currentSentenceAccumulator = ""
            sentenceCount = sentenceCount + 1
        end
    end
end

print("")
print("✓ Successfully created " .. (sentenceCount - 1) .. " markers")
print("✓ Synced to timeline with duration-based scaling")
print("Done.")