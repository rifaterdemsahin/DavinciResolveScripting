
-- DAVINCI RESOLVE LUA SCRIPT --
-- FIXED FOR 60 FPS MASTER SETTINGS --

local resolve = Resolve()
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then print("No project is open.") return end

-- CONFIGURATION
local targetTimelineName = "Timeline 1"

-- [1] HARDCODED FPS FROM YOUR SCREENSHOT
local FPS = 60

-- [2] SYNC TARGET
-- We use the end time you provided to align everything perfectly at 60fps.
local TARGET_END_TIMECODE = "01:02:17:29"

local timeline = nil
local timelineCount = project:GetTimelineCount()

-- Find Timeline
for i = 1, timelineCount do
    local t = project:GetTimelineByIndex(i)
    if t:GetName() == targetTimelineName then timeline = t break end
end

if not timeline then print("Error: Could not find '" .. targetTimelineName .. "'") return end

print("Target Timeline: " .. timeline:GetName())
print("Using Fixed Frame Rate: " .. FPS)

-- Clear Old Markers
local markers = timeline:GetMarkers()
for frame, _ in pairs(markers) do timeline:DeleteMarkerAtFrame(frame) end
print("Cleared old markers.")

local markerColors = {"Blue", "Cyan", "Green", "Yellow", "Red", "Pink", "Purple", "Fuchsia", "Rose", "Lavender", "Mint", "Teal", "Cream", "Cocoa", "Sand"}

-- SRT DATA
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

-- HELPERS
function srtToSeconds(tc_string)
    local h, m, s, ms = tc_string:match("(%d+):(%d+):(%d+),(%d+)")
    if not h then return 0 end
    return (tonumber(h) *3600) + (tonumber(m)* 60) + tonumber(s) + (tonumber(ms) / 1000)
end

function timelineTcToSeconds(tc_string, fps)
    local h, m, s, f = tc_string:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end
    return (tonumber(h) *3600) + (tonumber(m)* 60) + tonumber(s) + (tonumber(f) / fps)
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

-- CALCULATION: SYNC TO END
-- We find the LAST timestamp in the SRT, and calculate the offset to match your Target End Time.
local srt_last_time_str = ""
for line in srt_content:gmatch("[^\r\n]+") do
    if line:find("%-%->") then
        local _, endStr = line:match("(%d+:%d+:%d+,%d+) %-%-> (%d+:%d+:%d+,%d+)")
        if endStr then srt_last_time_str = endStr end
    end
end

local srt_end_seconds = srtToSeconds(srt_last_time_str)
local target_end_seconds = timelineTcToSeconds(TARGET_END_TIMECODE, FPS)
local GLOBAL_OFFSET_SECONDS = target_end_seconds - srt_end_seconds

print("SRT Ends at: " .. srt_last_time_str)
print("Target End:  " .. TARGET_END_TIMECODE)
print("Offset:      " .. GLOBAL_OFFSET_SECONDS .. "s")

-- EXECUTE
local sentenceCount = 1
local colorIndex = 1
local currentEndTime = ""
local currentSentenceAccumulator = ""

for line in srt_content:gmatch("[^\r\n]+") do
    if line:find("%-%->") then
        local_, endStr = line:match("(%d+:%d+:%d+,%d+) %-%-> (%d+:%d+:%d+,%d+)")
        if endStr then currentEndTime = endStr end

    elseif not line:match("^%d+$") and not line:find("%-%->") then
        if currentSentenceAccumulator == "" then
            currentSentenceAccumulator = line
        else
            currentSentenceAccumulator = currentSentenceAccumulator .. " " .. line
        end
        
        if isSemanticEnd(line) then
            local srt_secs = srtToSeconds(currentEndTime)
            local final_secs = srt_secs + GLOBAL_OFFSET_SECONDS
            local frameID = math.floor(final_secs * FPS) -- USING 60 FPS
            
            local assignedColor = markerColors[colorIndex]
            colorIndex = colorIndex + 1
            if colorIndex > #markerColors then colorIndex = 1 end
            
            timeline:AddMarker(frameID, assignedColor, "Sentence " .. sentenceCount, currentSentenceAccumulator, 1)
            
            currentSentenceAccumulator = ""
            sentenceCount = sentenceCount + 1
        end
    end
end

print("Done. Synced to 60 FPS.")
Based on the screenshot you provided, the issue is clear: **Your Timeline is running at 60 Frames Per Second (FPS).**

Most default scripts (and likely the API auto-detection in some versions) assume 24 or 30 FPS. This caused the markers to "drift" significantly—at 60 FPS, there are twice as many frames per second, so a script calculating for 30 FPS would place markers at completely wrong times.

Here is the fixed script. I have **hardcoded the FPS to 60** and set the synchronization to the **End Timecode** (`01:02:17:29`) you provided earlier. This should now align perfectly.

### Instructions

1. Open **DaVinci Resolve > Console > Lua**.
2. Copy and Paste the code below.
3. Press **Execute**.

```lua
-- DAVINCI RESOLVE LUA SCRIPT --
-- FIXED FOR 60 FPS MASTER SETTINGS --

local resolve = Resolve()
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then print("No project is open.") return end

-- CONFIGURATION
local targetTimelineName = "Timeline 1"

-- [1] HARDCODED FPS FROM YOUR SCREENSHOT
local FPS = 60 

-- [2] SYNC TARGET
-- We use the end time you provided to align everything perfectly at 60fps.
local TARGET_END_TIMECODE = "01:02:17:29" 

local timeline = nil
local timelineCount = project:GetTimelineCount()

-- Find Timeline
for i = 1, timelineCount do
    local t = project:GetTimelineByIndex(i)
    if t:GetName() == targetTimelineName then timeline = t break end
end

if not timeline then print("Error: Could not find '" .. targetTimelineName .. "'") return end

print("Target Timeline: " .. timeline:GetName())
print("Using Fixed Frame Rate: " .. FPS)

-- Clear Old Markers
local markers = timeline:GetMarkers()
for frame, _ in pairs(markers) do timeline:DeleteMarkerAtFrame(frame) end
print("Cleared old markers.")

local markerColors = {"Blue", "Cyan", "Green", "Yellow", "Red", "Pink", "Purple", "Fuchsia", "Rose", "Lavender", "Mint", "Teal", "Cream", "Cocoa", "Sand"}

-- SRT DATA
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

-- HELPERS
function srtToSeconds(tc_string)
    local h, m, s, ms = tc_string:match("(%d+):(%d+):(%d+),(%d+)")
    if not h then return 0 end
    return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) + (tonumber(ms) / 1000)
end

function timelineTcToSeconds(tc_string, fps)
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

-- CALCULATION: SYNC TO END
-- We find the LAST timestamp in the SRT, and calculate the offset to match your Target End Time.
local srt_last_time_str = ""
for line in srt_content:gmatch("[^\r\n]+") do
    if line:find("%-%->") then
        local _, endStr = line:match("(%d+:%d+:%d+,%d+) %-%-> (%d+:%d+:%d+,%d+)")
        if endStr then srt_last_time_str = endStr end
    end
end

local srt_end_seconds = srtToSeconds(srt_last_time_str)
local target_end_seconds = timelineTcToSeconds(TARGET_END_TIMECODE, FPS)
local GLOBAL_OFFSET_SECONDS = target_end_seconds - srt_end_seconds

print("SRT Ends at: " .. srt_last_time_str)
print("Target End:  " .. TARGET_END_TIMECODE)
print("Offset:      " .. GLOBAL_OFFSET_SECONDS .. "s")


-- EXECUTE
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
            local srt_secs = srtToSeconds(currentEndTime)
            local final_secs = srt_secs + GLOBAL_OFFSET_SECONDS
            local frameID = math.floor(final_secs * FPS) -- USING 60 FPS
            
            local assignedColor = markerColors[colorIndex]
            colorIndex = colorIndex + 1
            if colorIndex > #markerColors then colorIndex = 1 end
            
            timeline:AddMarker(frameID, assignedColor, "Sentence " .. sentenceCount, currentSentenceAccumulator, 1)
            
            currentSentenceAccumulator = ""
            sentenceCount = sentenceCount + 1
        end
    end
end

print("Done. Synced to 60 FPS.")

```

---

If the markers are still drifting or offset, the issue usually lies in one of three specific places. Here is where you should look, followed by a script that uses a **Single Point Sync** method (the most accurate way to fix this).

### Where to look (Troubleshooting)

1. **Frame Rate Mismatch (The "Drift"):**

* **The Issue:** Your Timeline might be **24 fps**, but the SRT was generated at **29.97 fps** (or vice versa).
* **The Symptom:** The markers start correctly but slowly get further and further away from the audio as the clip goes on.
* **The Fix:** Check your Timeline Settings (Shift+9) to see your exact FPS.

1. **Timeline Start Time (The "Offset"):**

* **The Issue:** The SRT file starts at `01:00:00:00`. Your timeline might start at `00:00:00:00` or `10:00:00:00`.
* **The Symptom:** The markers are consistently off by exactly 1 hour or 10 hours.

1. **"End of Footage" vs. "End of Audio" (The "Gap"):**

* **The Issue:** You synced to the "End of footage" (`01:02:17:29`). However, the speaker might have stopped talking at `01:02:15:00`, and there are 2 seconds of silence/video at the end.
* **The Result:** Aligning the text to the *video* end pushes all the text 2 seconds too late.

---

### The Solution: "The First Word Anchor"

The most reliable way to fix this is to ignore the end and **sync to the first sentence**.

**Step-by-Step Instructions:**

1. Go to your Timeline.
2. Listen to the very first phrase: **"...and plate structure that we are using on"**
3. Park your playhead exactly where the speaker finishes the word **"on"**.
4. **Copy that Timecode** (e.g., `01:00:02:05`).
5. Paste it into the `REAL_TIMELINE_POSITION` variable in the script below.

This script will calculate the offset based on the start, which eliminates the "silence at the end" error.

```lua
-- DAVINCI RESOLVE LUA SCRIPT --
-- FIXED SYNC: Uses the First Subtitle as an Anchor Point --

local resolve = Resolve()
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then print("No project is open.") return end

-- ========================================================
--  CONFIGURATION: THE ANCHOR POINT
-- ========================================================

-- 1. Look at the FIRST LINE in the data below.
--    It ends with the word: "...using on"
--    The SRT says this happens at: 01:00:02,150

-- 2. Go to your Timeline. Find exactly where the speaker says "on".
--    ENTER THAT TIMECODE HERE:
local REAL_TIMELINE_POSITION = "01:01:10:20" -- <--- REPLACE THIS WITH YOUR EXACT TIMECODE

-- 3. Target Timeline
local targetTimelineName = "Timeline 1"

-- ========================================================

local timeline = nil
local timelineCount = project:GetTimelineCount()

-- Find Timeline
for i = 1, timelineCount do
    local t = project:GetTimelineByIndex(i)
    if t:GetName() == targetTimelineName then timeline = t break end
end

if not timeline then print("Error: Could not find '" .. targetTimelineName .. "'") return end

-- Get FPS
local fps = timeline:GetSetting("timelineFrameRate")
if type(fps) == "string" then fps = tonumber(fps) end
print("FPS: " .. fps)

-- Clear Old Markers
local markers = timeline:GetMarkers()
for frame, _ in pairs(markers) do timeline:DeleteMarkerAtFrame(frame) end

local markerColors = {"Blue", "Cyan", "Green", "Yellow", "Red", "Pink", "Purple", "Fuchsia", "Rose", "Lavender", "Mint", "Teal", "Cream", "Cocoa", "Sand"}

-- DATA
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

-- HELPERS
function srtToSeconds(tc_string)
    local h, m, s, ms = tc_string:match("(%d+):(%d+):(%d+),(%d+)")
    if not h then return 0 end
    return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) + (tonumber(ms) / 1000)
end

function timelineTcToSeconds(tc_string, fps)
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

-- ========================================================
-- SYNC LOGIC
-- ========================================================

-- 1. Identify Anchor Point in SRT (The first entry)
-- Index 1, End Time: 01:00:02,150
local ANCHOR_SRT_TIME = "01:00:02,150"

-- 2. Calculate Offset
local srt_anchor_secs = srtToSeconds(ANCHOR_SRT_TIME)
local timeline_anchor_secs = timelineTcToSeconds(REAL_TIMELINE_POSITION, fps)
local GLOBAL_OFFSET = timeline_anchor_secs - srt_anchor_secs

print("Syncing based on anchor...")
print("SRT expects 'using on' at: " .. ANCHOR_SRT_TIME)
print("You saw 'using on' at:     " .. REAL_TIMELINE_POSITION)
print("Offset applied: " .. GLOBAL_OFFSET .. " seconds")

-- 3. Execute
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
            local srt_secs = srtToSeconds(currentEndTime)
            local final_secs = srt_secs + GLOBAL_OFFSET
            local frameID = math.floor(final_secs * fps)
            
            local assignedColor = markerColors[colorIndex]
            colorIndex = colorIndex + 1
            if colorIndex > #markerColors then colorIndex = 1 end
            
            timeline:AddMarker(frameID, assignedColor, "Sentence " .. sentenceCount, currentSentenceAccumulator, 1)
            currentSentenceAccumulator = ""
            sentenceCount = sentenceCount + 1
        end
    end
end

print("Done. Synced to your manual anchor point.")

```
