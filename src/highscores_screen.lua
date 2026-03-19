-- highscores_screen.lua
-- Full top-10 leaderboard, accessible from the main menu.

local HighScoresScreen = {}
HighScoresScreen.__index = HighScoresScreen

local IS_MOBILE  = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

local HighScores = require("src.highscores")

local SCREEN_W = 800
local SCREEN_H = 450

-- Deterministic starfield (same seed as main_menu for visual consistency)
local STARS = {}
do
    math.randomseed(9113)
    for i = 1, 70 do
        STARS[i] = {
            x     = math.random() * SCREEN_W,
            y     = math.random() * SCREEN_H,
            phase = math.random() * math.pi * 2,
            speed = 0.7 + math.random() * 1.2,
        }
    end
end

function HighScoresScreen.new()
    local self     = setmetatable({}, HighScoresScreen)
    self.fontBig   = love.graphics.newFont(32)
    self.fontMid    = love.graphics.newFont(17)
    self.fontSm     = love.graphics.newFont(13)
    self.time = 0
    return self
end

function HighScoresScreen:update(dt)
    self.time = self.time + dt
end

-- Returns "back" or nil
function HighScoresScreen:keypressed(key)
    if key == "escape" or key == "return" or key == "space" then
        return "back"
    end
end

function HighScoresScreen:mousepressed(mx, my, btn)
    return "back"
end

function HighScoresScreen:draw()
    local t = self.time

    -- Dark background
    love.graphics.setColor(0.04, 0.04, 0.14, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    -- Starfield
    for _, s in ipairs(STARS) do
        local alpha = 0.1 + 0.18 * math.sin(t * s.speed + s.phase)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.rectangle("fill", s.x, s.y, 2, 2)
    end

    -- Title
    love.graphics.setFont(self.fontBig)
    local title = "HIGH SCORES"
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print(title, (SCREEN_W - self.fontBig:getWidth(title)) / 2, 22)

    local all    = HighScores.getAll()
    local panelX = 130
    local startY = 90
    local rowH   = 30

    -- Column headers
    love.graphics.setFont(self.fontSm)
    love.graphics.setColor(0.45, 0.45, 0.58, 1)
    love.graphics.print("#",      panelX,       startY)
    love.graphics.print("CHAR",   panelX + 60,  startY)
    love.graphics.print("SCORE",  panelX + 230, startY)
    love.graphics.print("DIST",   panelX + 340, startY)

    -- Divider
    love.graphics.setColor(0.25, 0.25, 0.45, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.line(panelX, startY + 18, panelX + 450, startY + 18)
    love.graphics.setLineWidth(1)

    if #all == 0 then
        love.graphics.setFont(self.fontMid)
        love.graphics.setColor(0.40, 0.40, 0.52, 1)
        local msg = "No scores yet — play a run!"
        love.graphics.print(msg, (SCREEN_W - self.fontMid:getWidth(msg)) / 2, startY + rowH * 2)
    else
        love.graphics.setFont(self.fontMid)
        for i, e in ipairs(all) do
            local y   = startY + 24 + (i - 1) * rowH
            local col = HighScores.charColor(e.charPath)
            local lbl = HighScores.charLabel(e.charPath)

            -- Row highlight for top 3
            if i <= 3 then
                local rowAlpha = 0.08
                love.graphics.setColor(col[1], col[2], col[3], rowAlpha)
                love.graphics.rectangle("fill", panelX - 6, y - 4, 462, rowH - 2, 4, 4)
            end

            -- Rank number (medal colours)
            if     i == 1 then love.graphics.setColor(1.00, 0.84, 0.10, 1)
            elseif i == 2 then love.graphics.setColor(0.75, 0.75, 0.75, 1)
            elseif i == 3 then love.graphics.setColor(0.80, 0.50, 0.20, 1)
            else               love.graphics.setColor(0.50, 0.50, 0.58, 1)
            end
            love.graphics.print(i .. ".", panelX, y)

            -- Character colour dot
            love.graphics.setColor(col[1], col[2], col[3], 0.92)
            love.graphics.circle("fill", panelX + 72, y + 9, 9)
            -- First-letter initial inside dot
            love.graphics.setColor(0, 0, 0, 0.80)
            love.graphics.setFont(self.fontSm)
            local abbr = lbl:sub(1, 1)
            love.graphics.print(abbr, panelX + 72 - self.fontSm:getWidth(abbr) / 2, y + 1)
            love.graphics.setFont(self.fontMid)

            -- Character name
            love.graphics.setColor(0.85, 0.85, 0.88, 1)
            love.graphics.print(lbl, panelX + 88, y)

            -- Score (amber)
            love.graphics.setColor(1, 0.88, 0.45, 1)
            love.graphics.print(tostring(e.score), panelX + 230, y)

            -- Distance (light blue)
            love.graphics.setColor(0.65, 0.82, 1, 1)
            love.graphics.print(e.dist .. " m", panelX + 340, y)
        end
    end

    -- Bottom divider
    local bottomY = startY + 24 + math.max(#all, 1) * rowH + 4
    love.graphics.setColor(0.25, 0.25, 0.45, 0.7)
    love.graphics.setLineWidth(1)
    love.graphics.line(panelX, bottomY, panelX + 450, bottomY)

    -- Back hint
    love.graphics.setFont(self.fontSm)
    love.graphics.setColor(0.38, 0.38, 0.50, 0.85)
    local hint = IS_MOBILE and "Tap anywhere to go back" or "Press Esc  or  click to go back"
    love.graphics.print(hint, (SCREEN_W - self.fontSm:getWidth(hint)) / 2, SCREEN_H - 22)

    love.graphics.setColor(1, 1, 1, 1)
end

return HighScoresScreen
