-- pause_menu.lua
-- In-game pause overlay with Resume, Sound toggle, and Quit options.

local PauseMenu = {}
PauseMenu.__index = PauseMenu

local SCREEN_W = 800
local SCREEN_H = 450

local PANEL_W = 280
local PANEL_H = 268
local PANEL_X = (SCREEN_W - PANEL_W) / 2
local PANEL_Y = (SCREEN_H - PANEL_H) / 2

local ITEMS = { "Resume", "Sound", "Main Menu", "Quit Game" }
local ITEM_H = 44

local function itemRect(i)
    local x = PANEL_X + 30
    local y = PANEL_Y + 70 + (i - 1) * ITEM_H
    local w = PANEL_W - 60
    local h = 34
    return x, y, w, h
end

function PauseMenu.new(soundEnabled)
    local self = setmetatable({}, PauseMenu)
    self.selected     = 1
    self.soundEnabled = soundEnabled
    self.font         = love.graphics.newFont(18)
    self.fontTitle    = love.graphics.newFont(28)
    return self
end

-- Returns action string: "resume", "sound_toggle", "quit", or nil
function PauseMenu:keypressed(key)
    if key == "up" or key == "w" then
        self.selected = (self.selected - 2) % #ITEMS + 1
    elseif key == "down" or key == "s" then
        self.selected = self.selected % #ITEMS + 1
    elseif key == "escape" then
        return "resume"
    elseif key == "return" or key == "space" then
        return self:_activate(self.selected)
    end
    return nil
end

function PauseMenu:mousepressed(mx, my, button)
    if button ~= 1 then return nil end
    for i = 1, #ITEMS do
        local x, y, w, h = itemRect(i)
        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            self.selected = i
            return self:_activate(i)
        end
    end
    return nil
end

function PauseMenu:mousemoved(mx, my)
    for i = 1, #ITEMS do
        local x, y, w, h = itemRect(i)
        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            self.selected = i
            return
        end
    end
end

function PauseMenu:_activate(i)
    if i == 1 then
        return "resume"
    elseif i == 2 then
        self.soundEnabled = not self.soundEnabled
        return "sound_toggle"
    elseif i == 3 then
        return "mainmenu"
    elseif i == 4 then
        return "quit_game"
    end
end

function PauseMenu:draw()
    -- Dim the world behind
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    -- Panel background
    love.graphics.setColor(0.08, 0.08, 0.18, 0.97)
    love.graphics.rectangle("fill", PANEL_X, PANEL_Y, PANEL_W, PANEL_H, 10, 10)

    -- Panel border
    love.graphics.setColor(0.4, 0.4, 0.6, 1)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", PANEL_X, PANEL_Y, PANEL_W, PANEL_H, 10, 10)
    love.graphics.setLineWidth(1)

    -- Title
    love.graphics.setFont(self.fontTitle)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    local title = "PAUSED"
    love.graphics.print(
        title,
        PANEL_X + (PANEL_W - self.fontTitle:getWidth(title)) / 2,
        PANEL_Y + 18
    )

    -- Menu items
    love.graphics.setFont(self.font)
    for i, name in ipairs(ITEMS) do
        local x, y, w, h = itemRect(i)
        local sel = (i == self.selected)

        -- Button background
        if sel then
            love.graphics.setColor(0.2, 0.2, 0.45, 1)
        else
            love.graphics.setColor(0.12, 0.12, 0.25, 0.8)
        end
        love.graphics.rectangle("fill", x, y, w, h, 5, 5)

        -- Button border
        if sel then
            love.graphics.setColor(1, 0.85, 0.2, 1)
            love.graphics.setLineWidth(1.5)
        else
            love.graphics.setColor(0.35, 0.35, 0.5, 0.8)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", x, y, w, h, 5, 5)
        love.graphics.setLineWidth(1)

        -- Label
        local label
        if name == "Sound" then
            label = "Sound: " .. (self.soundEnabled and "ON" or "OFF")
        else
            label = name
        end

        if name == "Quit Game" then
            love.graphics.setColor(sel and {1, 0.4, 0.4, 1} or {0.7, 0.3, 0.3, 1})
        elseif sel then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
        end
        love.graphics.print(
            label,
            x + (w - self.font:getWidth(label)) / 2,
            y + (h - self.font:getHeight()) / 2
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return PauseMenu
