-- highscores.lua
-- Persists the top-10 scores via love.filesystem.
-- Each entry: { score, dist, charPath }

local HS   = {}
local FILE = "highscores.dat"
local MAX  = 10

local entries = {}

-- "assets/Main Characters/Mask Dude/" → "Mask Dude"
local function charLabel(path)
    local p = (path or ""):gsub("/$", "")
    return p:match("([^/]+)$") or "?"
end

-- Colour keyed by display name
local CHAR_COLORS = {
    ["Mask Dude"]   = {1.0,  0.75, 0.20, 1},  -- amber
    ["Ninja Frog"]  = {0.30, 0.85, 0.40, 1},  -- green
    ["Pink Man"]    = {0.90, 0.40, 0.80, 1},  -- pink
    ["Virtual Guy"] = {0.40, 0.60, 1.00, 1},  -- blue
}
local DEFAULT_COLOR = {0.70, 0.70, 0.70, 1}

local function load()
    if not love.filesystem.getInfo(FILE) then return end
    local data = love.filesystem.read(FILE)
    if not data then return end
    for line in data:gmatch("[^\n]+") do
        local s, d, c = line:match("^(%d+)\t(%d+)\t(.*)$")
        if s then
            entries[#entries + 1] = {
                score    = tonumber(s),
                dist     = tonumber(d),
                charPath = c,
            }
        end
    end
end

local function save()
    local lines = {}
    for _, e in ipairs(entries) do
        lines[#lines + 1] = string.format("%d\t%d\t%s", e.score, e.dist, e.charPath)
    end
    love.filesystem.write(FILE, table.concat(lines, "\n"))
end

function HS.init()
    entries = {}
    load()
end

function HS.addScore(score, dist, charPath)
    entries[#entries + 1] = { score = score, dist = dist, charPath = charPath }
    table.sort(entries, function(a, b) return a.score > b.score end)
    while #entries > MAX do entries[#entries] = nil end
    save()
end

function HS.getAll()
    return entries
end

function HS.charLabel(path)
    return charLabel(path)
end

function HS.charColor(path)
    local lbl = charLabel(path)
    return CHAR_COLORS[lbl] or DEFAULT_COLOR
end

return HS
