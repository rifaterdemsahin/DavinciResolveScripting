-- DAVINCI RESOLVE LUA SCRIPT -- apply_cuts.lua
-- Step 5 of the weekly edit plan (Videos/<week>/EDIT_PLAN.md).
--
-- Run on the ORIGINAL timeline after reviewing the markers from mark_cuts.lua.
-- It builds a NEW timeline from everything outside the RED cut markers.
-- The original timeline is never modified, so to roll back just delete the new one.
--
--   * Cut ranges  = RED markers with customData "edit:cut" / "edit:silence"
--                   (their position + duration, so dragging/resizing them in
--                   Resolve during review changes the cut)
--   * Keep ranges = everything else
--   * Chapter markers (customData "edit:chapter") are copied to the new
--     timeline, shifted left by the material cut before them
--   * youtube_chapters.txt is written from those chapter markers
--
-- Assumptions: source clips sit on video track 1 (with linked audio) at the
-- timeline frame rate and normal speed. Separate audio on other tracks can be
-- carried over with EXTRA_AUDIO_TRACKS.

-- ============================================
-- CONFIGURATION
-- ============================================
local VIDEO_DIR = [[c:\projects\DavinciResolveScripting\Videos\2026-W46_Delivery_Pilot_Interview\]]
local CUT_LIST_FILE  = VIDEO_DIR .. "cut_list.lua"
local CHAPTERS_FILE  = VIDEO_DIR .. "youtube_chapters.txt"
local NEW_TIMELINE   = "W46_edit_v1"     -- overridden by cut_list.lua timeline_name
local EXTRA_AUDIO_TRACKS = {}            -- e.g. {2} if a separate mic recording sits on A2

-- ============================================
-- RESOLVE
-- ============================================
local resolve = Resolve()
if not resolve then print("Could not connect to DaVinci Resolve.") return end
local project = resolve:GetProjectManager():GetCurrentProject()
if not project then print("No project is open.") return end
local mediaPool = project:GetMediaPool()
local src = project:GetCurrentTimeline()
if not src then print("No timeline is open.") return end

local okCfg, cfg = pcall(dofile, CUT_LIST_FILE)
if okCfg and type(cfg) == "table" and cfg.timeline_name then NEW_TIMELINE = cfg.timeline_name end

if src:GetName() == NEW_TIMELINE then print("You are on " .. NEW_TIMELINE .. ". Switch to the ORIGINAL timeline first.") return end
for i = 1, project:GetTimelineCount() do
    if project:GetTimelineByIndex(i):GetName() == NEW_TIMELINE then
        print("Timeline '" .. NEW_TIMELINE .. "' already exists. Delete or rename it, or change timeline_name in cut_list.lua.")
        return
    end
end

local fps = tonumber(src:GetSetting("timelineFrameRate")) or 24
local srcStart = src:GetStartFrame()
local srcLen = src:GetEndFrame() - srcStart

-- ============================================
-- CUT RANGES (relative frames) -> KEEP RANGES
-- ============================================
local cuts, chapters = {}, {}
for frame, mk in pairs(src:GetMarkers() or {}) do
    local data = tostring(mk.customData or "")
    if data == "edit:cut" or data == "edit:silence" then
        table.insert(cuts, { frame, frame + math.max(mk.duration or 1, 1) })
    elseif data == "edit:chapter" then
        table.insert(chapters, { frame = frame, name = mk.name, note = mk.note })
    end
end
if #cuts == 0 then print("No cut markers found. Run mark_cuts.lua first.") return end

table.sort(cuts, function(a, b) return a[1] < b[1] end)
local merged = {}
for _, c in ipairs(cuts) do
    local last = merged[#merged]
    if last and c[1] <= last[2] then
        if c[2] > last[2] then last[2] = c[2] end
    else
        table.insert(merged, { c[1], c[2] })
    end
end

local keeps, pos, cutTotal = {}, 0, 0
for _, c in ipairs(merged) do
    local cs, ce = math.max(c[1], 0), math.min(c[2], srcLen)
    if cs > pos then table.insert(keeps, { pos, cs }) end
    if ce > cs then cutTotal = cutTotal + (ce - cs) end
    if ce > pos then pos = ce end
end
if pos < srcLen then table.insert(keeps, { pos, srcLen }) end

-- Frames removed before a given source frame (frames inside a cut snap to the cut start).
local function mapFrame(f)
    local removed = 0
    for _, c in ipairs(merged) do
        if f >= c[2] then removed = removed + (c[2] - c[1])
        elseif f > c[1] then removed = removed + (f - c[1]) end
    end
    return f - removed
end

print(string.format("Source: %s | %d frames (%.1fs) | %d cut ranges -> %d keep ranges",
    src:GetName(), srcLen, srcLen / fps, #merged, #keeps))

-- ============================================
-- SOURCE CLIPS
-- ============================================
local function trackClips(kind, index)
    local out = {}
    for _, item in ipairs(src:GetItemListInTrack(kind, index) or {}) do
        local mpi = item:GetMediaPoolItem()
        if mpi then
            -- GetSourceStartFrame exists in Resolve 19+; fall back to GetLeftOffset.
            local okSrc, srcIn = pcall(function() return item:GetSourceStartFrame() end)
            if not okSrc or type(srcIn) ~= "number" then srcIn = item:GetLeftOffset() end
            table.insert(out, { s = item:GetStart() - srcStart, e = item:GetEnd() - srcStart, srcIn = srcIn, mpi = mpi })
        end
    end
    return out
end

local layers = { { clips = trackClips("video", 1), track = 1, mediaType = nil } }   -- nil = video + linked audio
for _, a in ipairs(EXTRA_AUDIO_TRACKS) do
    table.insert(layers, { clips = trackClips("audio", a), track = a, mediaType = 2 })
end
if #layers[1].clips == 0 then print("No clips on video track 1.") return end

-- ============================================
-- BUILD NEW TIMELINE
-- ============================================
local dst = mediaPool:CreateEmptyTimeline(NEW_TIMELINE)
if not dst then print("Could not create timeline " .. NEW_TIMELINE) return end
project:SetCurrentTimeline(dst)
dst:SetStartTimecode(src:GetStartTimecode())
local dstStart = dst:GetStartFrame()

local infos = {}
for _, layer in ipairs(layers) do
    local rec = 0
    for _, k in ipairs(keeps) do
        for _, clip in ipairs(layer.clips) do
            local s, e = math.max(k[1], clip.s), math.min(k[2], clip.e)
            if e > s then
                local info = {
                    mediaPoolItem = clip.mpi,
                    startFrame    = clip.srcIn + (s - clip.s),
                    endFrame      = clip.srcIn + (e - clip.s) - 1,   -- inclusive
                    recordFrame   = dstStart + mapFrame(s),
                    trackIndex    = layer.track,
                }
                if layer.mediaType then info.mediaType = layer.mediaType end
                table.insert(infos, info)
            end
        end
    end
end

local appended = mediaPool:AppendToTimeline(infos) or {}
print(string.format("Appended %d of %d clip pieces.", #appended, #infos))

-- ============================================
-- CHAPTER MARKERS + YOUTUBE CHAPTERS
-- ============================================
table.sort(chapters, function(a, b) return a.frame < b.frame end)
local lines = {}
for idx, ch in ipairs(chapters) do
    local nf = mapFrame(ch.frame)
    if idx == 1 and nf < fps * 2 then nf = 0 end   -- YouTube needs the first chapter at 00:00
    dst:AddMarker(nf, "Blue", ch.name, ch.note or "", 1, "edit:chapter")
    local secs = math.floor(nf / fps)
    local stamp = secs >= 3600 and string.format("%d:%02d:%02d", math.floor(secs / 3600), math.floor((secs % 3600) / 60), secs % 60)
                               or string.format("%02d:%02d", math.floor(secs / 60), secs % 60)
    local title = (ch.name or ""):gsub("^CH %d+%s*", "")
    table.insert(lines, stamp .. " " .. title)
end
if #lines > 0 then
    if not lines[1]:match("^00:00 ") then print("WARNING: first chapter is not at 00:00 - YouTube will ignore the chapters.") end
    local f = io.open(CHAPTERS_FILE, "w")
    if f then f:write(table.concat(lines, "\n") .. "\n"); f:close(); print("Chapters written: " .. CHAPTERS_FILE) end
    print(table.concat(lines, "\n"))
end

-- ============================================
-- CHECK
-- ============================================
local expected = srcLen - cutTotal
local actual = dst:GetEndFrame() - dst:GetStartFrame()
print(string.format("Cut %.1fs (%.1f%%). Expected length %d frames, new timeline %d frames%s",
    cutTotal / fps, 100 * cutTotal / srcLen, expected, actual,
    math.abs(actual - expected) <= #merged and "  OK" or "  <-- MISMATCH, check the timeline"))
print("Original timeline '" .. src:GetName() .. "' was not modified.")
