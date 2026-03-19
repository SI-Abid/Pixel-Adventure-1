-- options_menu.lua
-- Options screen: Sound FX toggle, Music toggle (BGM placeholder), Back.

local OptionsMenu = {}
OptionsMenu.__index = OptionsMenu

local IS_MOBILE = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

local SCREEN_W = 800
local SCREEN_H = 450

local BTN_W   = 300
local BTN_H   = 46
local BTN_GAP = 14
local BTN_X   = (SCREEN_W - BTN_W) / 2
local BTN_Y0  = 180

local ITEMS = { "sound", "music", "back" }

local function btnRect(i)
    return BTN_X, BTN_Y0 + (i - 1) * (BTN_H + BTN_GAP), BTN_W, BTN_H
end

function OptionsMenu.new(soundEnabled, musicEnabled)
    local self        = setmetatable({}, OptionsMenu)
    self.selected     = 1
    self.soundEnabled = soundEnabled
    self.musicEnabled = musicEnabled
    self.fontTitle    = love.graphics.newFont(36)
    self.fontBtn      = love.graphics.newFont(20)
    self.fontNote     = love.graphics.newFont(13)
    return self
end

-- Returns action string or nil
function OptionsMenu:keypressed(key)
    if key == "up" or key == "w" then
        self.selected = (self.selected - 2) % #ITEMS + 1
    elseif key == "down" or key == "s" then
        self.selected = self.selected % #ITEMS + 1
    elseif key == "return" or key == "space" then
        return self:_activate(self.selected)
    elseif key == "escape" then
        return "back"
    end
    return nil
end

function OptionsMenu:mousepressed(mx, my, btn)
    if btn ~= 1 then return nil end
    for i = 1, #ITEMS do
        local x, y, w, h = btnRect(i)
        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            return self:_activate(i)
        end
    end
    return nil
end

function OptionsMenu:mousemoved(mx, my)
    for i = 1, #ITEMS do
        local x, y, w, h = btnRect(i)
        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            self.selected = i
            return
        end
    end
end

function OptionsMenu:_activate(i)
    local item = ITEMS[i]
    if item == "sound" then
        self.soundEnabled = not self.soundEnabled
        return "sound_toggle"
    elseif item == "music" then
        self.musicEnabled = not self.musicEnabled
        return "music_toggle"
    elseif item == "back" then
        return "back"
    end
end

function OptionsMenu:draw()
    -- Background
    love.graphics.setColor(0.05, 0.05, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    -- Title
    love.graphics.setFont(self.fontTitle)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    local title = "OPTIONS"
    love.graphics.print(title, (SCREEN_W - self.fontTitle:getWidth(title)) / 2, 65)

    -- Buttons
    love.graphics.setFont(self.fontBtn)
    for i, item in ipairs(ITEMS) do
        local x, y, w, h = btnRect(i)
        local sel = (i == self.selected)

        -- Background
        if sel then
            love.graphics.setColor(0.18, 0.18, 0.42, 1)
        else
            love.graphics.setColor(0.09, 0.09, 0.20, 0.92)
        end
        love.graphics.rectangle("fill", x, y, w, h, 7, 7)

        -- Border
        if sel then
            love.graphics.setColor(1, 0.85, 0.2, 1)
            love.graphics.setLineWidth(2)
        else
            love.graphics.setColor(0.32, 0.32, 0.52, 0.9)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", x, y, w, h, 7, 7)
        love.graphics.setLineWidth(1)

        -- Label with ON/OFF indicator
        local label
        if item == "sound" then
            local state = self.soundEnabled and "ON" or "OFF"
            local col   = self.soundEnabled and {0.3, 1, 0.4} or {1, 0.35, 0.35}
            label = "Sound FX:  "
            local lx = x + (w - self.fontBtn:getWidth("Sound FX:  ON")) / 2
            local ly = y + (h - self.fontBtn:getHeight()) / 2
            love.graphics.setColor(sel and {1, 1, 1, 1} or {0.65, 0.65, 0.65, 1})
            love.graphics.print(label, lx, ly)
            love.graphics.setColor(col[1], col[2], col[3], 1)
            love.graphics.print(state, lx + self.fontBtn:getWidth(label), ly)
            goto continue
        elseif item == "music" then
            local state = self.musicEnabled and "ON" or "OFF"
            local col   = self.musicEnabled and {0.3, 1, 0.4} or {1, 0.35, 0.35}
            label = "Music:        "
            local lx = x + (w - self.fontBtn:getWidth("Music:        ON")) / 2
            local ly = y + (h - self.fontBtn:getHeight()) / 2
            love.graphics.setColor(sel and {1, 1, 1, 1} or {0.65, 0.65, 0.65, 1})
            love.graphics.print(label, lx, ly)
            love.graphics.setColor(col[1], col[2], col[3], 1)
            love.graphics.print(state, lx + self.fontBtn:getWidth(label), ly)
            goto continue
        else
            label = "Back"
        end

        love.graphics.setColor(sel and {1, 1, 1, 1} or {0.65, 0.65, 0.65, 1})
        love.graphics.print(
            label,
            x + (w - self.fontBtn:getWidth(label)) / 2,
            y + (h - self.fontBtn:getHeight()) / 2
        )

        ::continue::
    end

    -- Music coming-soon note
    love.graphics.setFont(self.fontNote)
    local noteY = BTN_Y0 + (BTN_H + BTN_GAP) + BTN_H + 8
    love.graphics.setColor(0.45, 0.45, 0.55, 0.65)
    local note = "*  Background music coming in a future update"
    love.graphics.print(note, (SCREEN_W - self.fontNote:getWidth(note)) / 2, noteY)

    love.graphics.setColor(1, 1, 1, 1)
end

return OptionsMenu
