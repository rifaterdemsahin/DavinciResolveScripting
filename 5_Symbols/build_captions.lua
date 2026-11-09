-- DAVINCI RESOLVE LUA SCRIPT -- build_captions.lua
-- Step 7 of the weekly edit plan (Videos/<week>/EDIT_PLAN.md).
--
-- Builds captions_corrected.srt for the EDITED timeline:
--   1. reads raw.srt (Resolve transcription of the ORIGINAL timeline)
--   2. applies corrections.lua (Claude Code, Skool, COBALTS, ...)
--   3. drops every word inside a RED cut/silence marker
--   4. shifts the remaining words left by the material cut before them
--   5. regroups words into readable captions (max 2 lines x 42 chars, max 6 s)
--
-- Run it with the ORIGINAL timeline open (the one with the red markers from
-- mark_cuts.lua), after apply_cuts.lua. If the current timeline has no cut
-- markers, it looks for the timeline that has them.
-- Then: File > Import > Subtitle > captions_corrected.srt, drag onto W46_edit_v1.

-- ============================================
-- CONFIGURATION
-- ============================================
local VIDEO_DIR = [[c:\projects\DavinciResolveScripting\Videos\2026-W46_Delivery_Pilot_Interview\]]
local SRT_FILE         = VIDEO_DIR .. "raw.srt"
local CORRECTIONS_FILE = VIDEO_DIR .. "corrections.lua"
local OUT_FILE         = VIDEO_DIR .. "captions_corrected.srt"

local MAX_LINE_CHARS = 42     -- per line
local MAX_LINES      = 2
local MAX_DURATION_S = 6.0
local MIN_DURATION_S = 1.0
local BREAK_GAP_S    = 0.6    -- start a new caption after a pause this long

-- ============================================
-- RESOLVE
-- ============================================
local resolve = Resolve()
if not resolve then print("Could not connect to DaVinci Resolve.") return end
local project = resolve:GetProjectManager():GetCurrentProject()
if not project then print("No project is open.") return end

local function cutMarkers(tl)
    local out = {}
    for frame, mk in pairs(tl:GetMarkers() or {}) do
        local data = tostring(mk.customData or "")
        if data == "edit:cut" or data == "edit:silence" then
            table.insert(out, { frame, frame + math.max(mk.duration or 1, 1) })
        end
    end
    return out
end

local timeline = project:GetCurrentTimeline()
local cuts = timeline and cutMarkers(timeline) or {}
if #cuts == 0 then
    for i = 1, project:GetTimelineCount() do
        local tl = project:GetTimelineByIndex(i)
        local c = cutMarkers(tl)
        if #c > 0 then timeline, cuts = tl, c break end
    end
end
if not timeline then print("No timeline found.") return end
if #cuts == 0 then print("WARNING: no cut markers found - captions will be corrected but NOT retimed.") end
print("Cut markers from timeline: " .. timeline:GetName() .. " (" .. #cuts .. " ranges)")

local fps = tonumber(timeline:GetSetting("timelineFrameRate")) or 24

-- Merge cut ranges (frames relative to timeline start).
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
local function insideCut(f)
    for _, c in ipairs(merged) do
        if f >= c[1] and f < c[2] then return true end
        if c[1] > f then return false end
    end
    return false
end
local function mapFrame(f)
    local removed = 0
    for _, c in ipairs(merged) do
        if f >= c[2] then removed = removed + (c[2] - c[1])
        elseif f > c[1] then removed = removed + (f - c[1]) end
    end
    return f - removed
end

-- ============================================
-- HELPERS
-- ============================================
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
local function secondsToSrt(t)
    if t < 0 then t = 0 end
    local ms = math.floor(t * 1000 + 0.5)
    return string.format("%02d:%02d:%02d,%03d",
        math.floor(ms / 3600000), math.floor(ms / 60000) % 60, math.floor(ms / 1000) % 60, ms % 1000)
end
local function key(token)  -- "Code," -> "code", "sixth-born" -> "sixthborn"
    return (token:lower():gsub("[^%w]", ""))
end
local function splitWords(s)
    local t = {}
    for w in s:gmatch("%S+") do table.insert(t, w) end
    return t
end

-- ============================================
-- LOAD
-- ============================================
local okC, corrections = pcall(dofile, CORRECTIONS_FILE)
if not okC or type(corrections) ~= "table" then
    print("Could not load " .. CORRECTIONS_FILE .. " - continuing without corrections.")
    corrections = {}
end

local file = io.open(SRT_FILE, "r")
if not file then print("Could not open SRT: " .. SRT_FILE) return end
local entries, cur = {}, nil
local function flush()
    if cur and cur.s and #cur.lines > 0 then
        table.insert(entries, { s = cur.s, e = cur.e, text = table.concat(cur.lines, " ") })
    end
    cur = nil
end
for line in file:lines() do
    line = line:gsub("\r", ""):match("^%s*(.-)%s*$")
    local a, b = line:match("(%d+:%d+:%d+[,%.]%d+)%s*%-%->%s*(%d+:%d+:%d+[,%.]%d+)")
    if a then cur = { s = srtToSeconds(a), e = srtToSeconds(b), lines = {} }
    elseif line == "" then flush()
    elseif cur then
        line = line:gsub("<[^>]*>", ""):gsub("{\\[^}]*}", "")   -- strip <b> / {\an8} tags
        if line ~= "" then table.insert(cur.lines, line) end
    end
end
flush()
file:close()
if #entries == 0 then print("No subtitle entries in " .. SRT_FILE) return end

local tlStartSecs = tcToSeconds(timeline:GetStartTimecode() or "00:00:00:00", fps)
local srtOffset = (entries[1].s >= tlStartSecs - 1) and tlStartSecs or 0

-- Word list with timing spread evenly inside each subtitle entry.
local words = {}
for _, en in ipairs(entries) do
    local ws = splitWords(en.text)
    local step = (en.e - en.s) / math.max(#ws, 1)
    for k, w in ipairs(ws) do
        table.insert(words, { w = w, s = en.s + (k - 1) * step, e = en.s + k * step })
    end
end

-- ============================================
-- 1. CORRECTIONS (word-sequence replace, across subtitle boundaries)
-- ============================================
local applied = {}
for _, pair in ipairs(corrections) do
    local from, to = splitWords(pair[1]), splitWords(pair[2])
    local fk = {}
    for i, w in ipairs(from) do fk[i] = key(w) end
    local n, count, i = #from, 0, 1
    while i <= #words - n + 1 do
        local match = true
        for j = 1, n do
            if key(words[i + j - 1].w) ~= fk[j] then match = false break end
        end
        if match then
            local first, last = words[i], words[i + n - 1]
            local trail = last.w:match("[%p]+$") or ""
            local lead = first.w:match("^[%p]+") or ""
            local repl = {}
            for j, w in ipairs(to) do
                local txt = w
                if j == 1 then
                    txt = lead .. txt
                    if first.w:gsub("^[%p]+", ""):match("^%u") then txt = txt:gsub("^(%p*)(%l)", function(p, c) return p .. c:upper() end) end
                end
                if j == #to and not txt:match("[%p]$") then txt = txt .. trail end
                local frac0, frac1 = (j - 1) / #to, j / #to
                table.insert(repl, { w = txt, s = first.s + (last.e - first.s) * frac0, e = first.s + (last.e - first.s) * frac1 })
            end
            for _ = 1, n do table.remove(words, i) end
            for j = #repl, 1, -1 do table.insert(words, i, repl[j]) end
            i, count = i + #repl, count + 1
        else
            i = i + 1
        end
    end
    if count > 0 then table.insert(applied, string.format("  %3dx  %s -> %s", count, pair[1], pair[2])) end
end
print("Corrections applied:")
print(#applied > 0 and table.concat(applied, "\n") or "  (none matched)")

-- ============================================
-- 2. DROP CUT WORDS + 3. RETIME
-- ============================================
local kept, dropped = {}, 0
for _, w in ipairs(words) do
    local mid = math.floor(((w.s + w.e) / 2 - srtOffset) * fps)
    if insideCut(mid) then
        dropped = dropped + 1
    else
        local fs = math.floor((w.s - srtOffset) * fps + 0.5)
        local fe = math.floor((w.e - srtOffset) * fps + 0.5)
        local ms, me = mapFrame(fs), mapFrame(fe)
        if me <= ms then me = ms + 1 end
        table.insert(kept, { w = w.w, s = ms / fps, e = me / fps })
    end
end
print(string.format("Words: %d kept, %d dropped (inside cuts).", #kept, dropped))

-- ============================================
-- 4. REGROUP INTO CAPTIONS
-- ============================================
local function wrap(ws)   -- returns lines or nil if it doesn't fit
    local lines, line = {}, ""
    for _, w in ipairs(ws) do
        local cand = (line == "") and w or (line .. " " .. w)
        if #cand <= MAX_LINE_CHARS then line = cand
        else
            table.insert(lines, line); line = w
            if #lines >= MAX_LINES then return nil end
        end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

local caps, group = {}, {}
local function close()
    if #group == 0 then return end
    local ws = {}
    for _, g in ipairs(group) do table.insert(ws, g.w) end
    table.insert(caps, { s = group[1].s, e = group[#group].e, lines = wrap(ws) })
    group = {}
end
for idx, w in ipairs(kept) do
    if #group > 0 then
        local prev = group[#group]
        local test = {}
        for _, g in ipairs(group) do table.insert(test, g.w) end
        table.insert(test, w.w)
        if (w.s - prev.e) > BREAK_GAP_S or (w.e - group[1].s) > MAX_DURATION_S or not wrap(test) then
            close()
        end
    end
    table.insert(group, w)
    -- end a caption at sentence end once it has some length
    if w.w:match("[%.%?!]$") and (w.e - group[1].s) >= 1.5 then close() end
end
close()

-- Minimum duration, without overlapping the next caption or running past the edit.
local editEnd = mapFrame(timeline:GetEndFrame() - timeline:GetStartFrame()) / fps
for i, c in ipairs(caps) do
    local nextS = caps[i + 1] and caps[i + 1].s or editEnd
    if c.e - c.s < MIN_DURATION_S then c.e = math.min(c.s + MIN_DURATION_S, nextS) end
    if c.e > nextS then c.e = nextS end
end

-- ============================================
-- WRITE
-- ============================================
local out = io.open(OUT_FILE, "w")
if not out then print("Could not write " .. OUT_FILE) return end
for i, c in ipairs(caps) do
    out:write(string.format("%d\n%s --> %s\n%s\n\n", i,
        secondsToSrt(c.s + srtOffset), secondsToSrt(c.e + srtOffset), table.concat(c.lines, "\n")))
end
out:close()
print(string.format("Wrote %d captions (%.1fs) to %s", #caps, caps[#caps] and caps[#caps].e or 0, OUT_FILE))
print("Import: File > Import > Subtitle, then drag onto the edited timeline's subtitle track.")
