-- DAVINCI RESOLVE LUA SCRIPT -- mark_cuts.lua
-- Step 3 of the weekly edit plan (Videos/<week>/EDIT_PLAN.md).
--
-- Reads the raw Resolve transcription (raw.srt) and the phrase-based cut list
-- (cut_list.lua) and puts markers on the CURRENT timeline:
--   RED  "CUT Cn" markers  - content cuts (duration = cut length)
--   RED  "SIL"    markers  - silence tightening
--   BLUE "CH n"   markers  - chapters
-- Nothing is deleted or moved. Review the red markers in Resolve, adjust them
-- if needed, then run apply_cuts.lua.
--
-- Safe to re-run: only markers this script created (customData "edit:...")
-- are removed first; your own markers are left alone.

-- ============================================
-- CONFIGURATION
-- ============================================
local VIDEO_DIR = [[c:\projects\DavinciResolveScripting\Videos\2026-W46_Delivery_Pilot_Interview\]]
local SRT_FILE      = VIDEO_DIR .. "raw.srt"
local CUT_LIST_FILE = VIDEO_DIR .. "cut_list.lua"
local REPORT_FILE   = VIDEO_DIR .. "mark_cuts_report.txt"

-- ============================================
-- RESOLVE
-- ============================================
local resolve = Resolve()
if not resolve then print("Could not connect to DaVinci Resolve. Run this from Workspace > Scripts.") return end
local project = resolve:GetProjectManager():GetCurrentProject()
if not project then print("No project is open.") return end
local timeline = project:GetCurrentTimeline()
if not timeline then print("No timeline is open.") return end

local fps = tonumber(timeline:GetSetting("timelineFrameRate")) or 24
local timelineLen = timeline:GetEndFrame() - timeline:GetStartFrame()

-- ============================================
-- HELPERS
-- ============================================
local report = {}
local function log(msg) print(msg); table.insert(report, msg) end

local function srtToSeconds(tc)
    local h, m, s, ms = tc:match("(%d+):(%d+):(%d+)[,%.](%d+)")
    if not h then return nil end
    return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
end

local function tcToSeconds(tc, rate)
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+)[:;](%d+)")
    if not h then return 0 end
    return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(f) / rate
end

local function normalize(text)
    text = text:lower():gsub("[\226\128\153']", "")   -- drop apostrophes (’ and ')
    text = text:gsub("[^%w]+", " ")
    local words = {}
    for w in text:gmatch("%S+") do table.insert(words, w) end
    return words
end

-- ============================================
-- LOAD CUT LIST + SRT
-- ============================================
local ok, cfg = pcall(dofile, CUT_LIST_FILE)
if not ok or type(cfg) ~= "table" then print("Could not load cut list: " .. CUT_LIST_FILE .. "\n" .. tostring(cfg)) return end

local file = io.open(SRT_FILE, "r")
if not file then print("Could not open SRT: " .. SRT_FILE .. "\nExport it from Resolve: File > Export > Subtitle.") return end

local entries = {}   -- { s = seconds, e = seconds, text = "..." }
local cur = nil
local function flush()
    if cur and cur.s and #cur.lines > 0 then
        table.insert(entries, { s = cur.s, e = cur.e, text = table.concat(cur.lines, " ") })
    end
    cur = nil
end
for line in file:lines() do
    line = line:gsub("\r", ""):match("^%s*(.-)%s*$")
    local a, b = line:match("(%d+:%d+:%d+[,%.]%d+)%s*%-%->%s*(%d+:%d+:%d+[,%.]%d+)")
    if a then
        cur = { s = srtToSeconds(a), e = srtToSeconds(b), lines = {} }
    elseif line == "" then
        flush()
    elseif cur then
        table.insert(cur.lines, line)
    end
end
flush()
file:close()
if #entries == 0 then print("No subtitle entries found in " .. SRT_FILE) return end

-- SRT exported from a timeline uses the timeline timecode (usually 01:00:00:00).
-- Markers are placed relative to the timeline start (see 6_Semblance/markers_fix.md),
-- so subtract the start timecode when the SRT uses it.
local tlStartSecs = tcToSeconds(timeline:GetStartTimecode() or "00:00:00:00", fps)
local srtOffset = (entries[1].s >= tlStartSecs - 1) and tlStartSecs or 0
local function secToFrame(sec)
    local f = math.floor((sec - srtOffset) * fps + 0.5)
    if f < 0 then f = 0 end
    if f > timelineLen then f = timelineLen end
    return f
end

-- Word list with per-word timing, spread evenly across each subtitle entry.
local words = {}
for _, en in ipairs(entries) do
    local ws = normalize(en.text)
    local step = (en.e - en.s) / math.max(#ws, 1)
    for k, w in ipairs(ws) do
        table.insert(words, { w = w, s = en.s + (k - 1) * step, e = en.s + k * step })
    end
end

log("Timeline: " .. timeline:GetName() .. " | fps " .. fps .. " | length " .. timelineLen .. " frames")
log("SRT: " .. #entries .. " entries, " .. #words .. " words, offset " .. srtOffset .. " s")

-- Returns first, last word index of the phrase, searching from word index `from`.
local function findPhrase(phrase, from)
    local pw = normalize(phrase)
    local n = #pw
    if n == 0 then return nil end
    local bestI, bestScore = nil, -1
    for i = from, #words - n + 1 do
        local m = 0
        for j = 1, n do
            if words[i + j - 1].w == pw[j] then m = m + 1 end
        end
        if m == n then return i, i + n - 1, 1.0 end
        local score = m / n
        if score > bestScore then bestI, bestScore = i, score end
    end
    local threshold = (n >= 4) and 0.75 or 1.0
    if bestI and bestScore >= threshold then return bestI, bestI + n - 1, bestScore end
    return nil
end

-- ============================================
-- CLEAR OUR OLD MARKERS
-- ============================================
local removed = 0
for frame, mk in pairs(timeline:GetMarkers() or {}) do
    if mk.customData and tostring(mk.customData):sub(1, 5) == "edit:" then
        timeline:DeleteMarkerAtFrame(frame)
        removed = removed + 1
    end
end
log("Removed " .. removed .. " old edit markers.")

-- ============================================
-- CUTS
-- ============================================
local keep = (cfg.silence and cfg.silence.keep_s) or 0.4
local cursor = 1
local cutRanges = {}   -- { s, e } in frames, for the summary
local failures = 0

local function addRange(color, name, note, data, s, e)
    local fs, fe = secToFrame(s), secToFrame(e)
    if fe <= fs then return false end
    -- If a marker already sits on this frame (e.g. silence inside a cut), nudge by a frame.
    local okAdd = timeline:AddMarker(fs, color, name, note, fe - fs, data)
    if not okAdd then okAdd = timeline:AddMarker(fs + 1, color, name, note, fe - fs - 1, data) end
    if okAdd then table.insert(cutRanges, { fs, fe }) end
    return okAdd
end

for _, c in ipairs(cfg.cuts or {}) do
    local startSec, endSec, why
    local sIdx, eIdx
    -- start anchor
    if c.from == "START" then
        startSec, sIdx = entries[1].s - 1, cursor
    elseif c.from then
        local i, j = findPhrase(c.from, cursor)
        if i then startSec, sIdx = words[i].s, i else why = "start phrase not found: \"" .. c.from .. "\"" end
    elseif c.after then
        local i, j = findPhrase(c.after, cursor)
        if i then startSec, sIdx = words[j].e, j + 1 else why = "after phrase not found: \"" .. c.after .. "\"" end
    end
    -- end anchor
    if startSec then
        if c.to == "END" then
            endSec = entries[#entries].e + 2
        elseif c.to then
            local i, j = findPhrase(c.to, sIdx)
            if i then endSec, cursor = words[j].e, j + 1 else why = "end phrase not found: \"" .. c.to .. "\"" end
        elseif c.before then
            local i, j = findPhrase(c.before, sIdx)
            if i then endSec, cursor = words[i].s, i else why = "before phrase not found: \"" .. c.before .. "\"" end
        end
    end
    if startSec and endSec and c.pad then
        startSec, endSec = startSec + keep / 2, endSec - keep / 2
    end
    if startSec and endSec and endSec > startSec then
        if c.from == "START" then startSec = srtOffset end   -- from the very first frame
        if c.to == "END" then endSec = srtOffset + timelineLen / fps end
        local okAdd = addRange("Red", "CUT " .. c.id, c.note or "", "edit:cut", startSec, endSec)
        log(string.format("%-4s %s  %6.2fs  %s", c.id, okAdd and "OK  " or "FAIL", endSec - startSec, c.note or ""))
        if not okAdd then failures = failures + 1 end
    elseif not why and c.pad then
        -- Both phrases found but the pause is already <= keep_s: nothing to close.
        log(string.format("%-4s SKIP  no pause longer than %.1fs to close  %s", c.id, keep, c.note or ""))
    else
        failures = failures + 1
        log(string.format("%-4s FAIL  %s", c.id, why or "range is empty"))
    end
end

-- ============================================
-- SILENCE (gaps between subtitle entries)
-- ============================================
local sil = cfg.silence or {}
local silCount, silSecs = 0, 0
if sil.enabled then
    for i = 1, #entries - 1 do
        local gap = entries[i + 1].s - entries[i].e
        if gap > (sil.min_gap_s or 0.8) then
            local s, e = entries[i].e + keep / 2, entries[i + 1].s - keep / 2
            if addRange("Red", "SIL", string.format("%.2fs gap -> %.2fs", gap, keep), "edit:silence", s, e) then
                silCount, silSecs = silCount + 1, silSecs + (e - s)
            end
        end
    end
    log(string.format("Silence: %d gaps tightened, %.1fs removed (gaps > %.1fs kept at %.1fs).",
        silCount, silSecs, sil.min_gap_s or 0.8, keep))
end

-- ============================================
-- CHAPTERS
-- ============================================
local chCursor = 1
for _, ch in ipairs(cfg.chapters or {}) do
    local i, j = findPhrase(ch.at, chCursor)
    if i then
        chCursor = j + 1
        local name = "CH " .. ch.n .. " " .. ch.title
        local fr = secToFrame(words[i].s)
        if not timeline:AddMarker(fr, "Blue", name, ch.at, 1, "edit:chapter") then
            timeline:AddMarker(fr + 1, "Blue", name, ch.at, 1, "edit:chapter")
        end
        log(string.format("CH %-2d OK    %s", ch.n, ch.title))
    else
        failures = failures + 1
        log(string.format("CH %-2d FAIL  phrase not found: \"%s\"", ch.n, ch.at))
    end
end

-- ============================================
-- SUMMARY
-- ============================================
table.sort(cutRanges, function(a, b) return a[1] < b[1] end)
local total, lastEnd = 0, -1
for _, r in ipairs(cutRanges) do
    local s = math.max(r[1], lastEnd)
    if r[2] > s then total = total + (r[2] - s) end
    if r[2] > lastEnd then lastEnd = r[2] end
end
log(string.format("TOTAL cut: %d frames (%.1fs) of %d (%.1f%%). Expected edit length: %.1fs",
    total, total / fps, timelineLen, 100 * total / math.max(timelineLen, 1), (timelineLen - total) / fps))
log(failures == 0 and "All phrases matched. Review the red markers, then run apply_cuts.lua."
                   or (failures .. " item(s) FAILED - fix the phrases in cut_list.lua and re-run."))

local rf = io.open(REPORT_FILE, "w")
if rf then rf:write(table.concat(report, "\n") .. "\n"); rf:close(); print("Report: " .. REPORT_FILE) end
