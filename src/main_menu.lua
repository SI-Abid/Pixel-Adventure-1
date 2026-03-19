-- main_menu.lua
-- Title screen: Start Game, Character Select, Options, Quit.

local MainMenu = {}
MainMenu.__index = MainMenu

local IS_MOBILE = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

local SCREEN_W = 800
local SCREEN_H = 450

local BUTTONS = {
    { label = "Start Game",       action = "start"       },
    { label = "Character Select", action = "select"      },
    { label = "High Scores",      action = "highscores"  },
    { label = "Options",          action = "options"     },
    { label = "Quit",             action = "quit"        },
}

local BTN_W   = 260
local BTN_H   = 44
local BTN_GAP = 8
local BTN_X   = (SCREEN_W - BTN_W) / 2
local BTN_Y0  = 162

local function btnRect(i)
    return BTN_X, BTN_Y0 + (i - 1) * (BTN_H + BTN_GAP), BTN_W, BTN_H
end

-- Deterministic starfield seeded once
local STARS = {}
do
    math.randomseed(7331)
    for i = 1, 90 do
        STARS[i] = {
            x     = math.random() * SCREEN_W,
            y     = math.random() * SCREEN_H,
            phase = math.random() * math.pi * 2,
            speed = 0.8 + math.random() * 1.4,
        }
    end
end

function MainMenu.new()
    local self      = setmetatable({}, MainMenu)
    self.selected   = 1
    self.fontTitle  = love.graphics.newFont(48)
    self.fontSub    = love.graphics.newFont(14)
    self.fontBtn    = love.graphics.newFont(20)
    self.time       = 0
    return self
end

function MainMenu:update(dt)
    self.time = self.time + dt
end

-- Returns action string or nil
function MainMenu:keypressed(key)
    if key == "up" or key == "w" then
        self.selected = (self.selected - 2) % #BUTTONS + 1
    elseif key == "down" or key == "s" then
        self.selected = self.selected % #BUTTONS + 1
    elseif key == "return" or key == "space" then
        return BUTTONS[self.selected].action
    end
    return nil
end

function MainMenu:mousepressed(mx, my, btn)
    if btn ~= 1 then return nil end
    for i, b in ipairs(BUTTONS) do
        local x, y, w, h = btnRect(i)
        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            return b.action
        end
    end
    return nil
end

function MainMenu:mousemoved(mx, my)
    for i = 1, #BUTTONS do
        local x, y, w, h = btnRect(i)
        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            self.selected = i
            return
        end
    end
end

function MainMenu:draw()
    local t = self.time

    -- Background
    love.graphics.setColor(0.05, 0.05, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    -- Animated starfield
    for _, s in ipairs(STARS) do
        local alpha = 0.15 + 0.2 * math.sin(t * s.speed + s.phase)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.rectangle("fill", s.x, s.y, 2, 2)
    end

    -- Title glow (shadow layer)
    love.graphics.setFont(self.fontTitle)
    local title = "PIXEL ADVENTURE"
    local tx    = (SCREEN_W - self.fontTitle:getWidth(title)) / 2
    love.graphics.setColor(1, 0.6, 0, 0.18)
    love.graphics.print(title, tx + 3, 58)

    -- Title
    local r = 0.92 + 0.08 * math.sin(t * 1.1)
    local g = 0.72 + 0.13 * math.sin(t * 0.8 + 1)
    love.graphics.setColor(r, g, 0.15, 1)
    love.graphics.print(title, tx, 55)

    -- Version tag
    love.graphics.setFont(self.fontSub)
    love.graphics.setColor(0.55, 0.55, 0.65, 0.8)
    local ver = "v1.0.0"
    love.graphics.print(ver, (SCREEN_W - self.fontSub:getWidth(ver)) / 2, 116)

    -- Buttons
    love.graphics.setFont(self.fontBtn)
    for i, b in ipairs(BUTTONS) do
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

        -- Label — Quit is red-tinted
        if b.action == "quit" then
            love.graphics.setColor(sel and {1, 0.45, 0.45, 1} or {0.65, 0.35, 0.35, 1})
        else
            love.graphics.setColor(sel and {1, 1, 1, 1} or {0.65, 0.65, 0.65, 1})
        end
        love.graphics.print(
            b.label,
            x + (w - self.fontBtn:getWidth(b.label)) / 2,
            y + (h - self.fontBtn:getHeight()) / 2
        )
    end

    -- Key hint (desktop only)
    if not IS_MOBILE then
        love.graphics.setFont(self.fontSub)
        love.graphics.setColor(0.4, 0.4, 0.48, 0.75)
        local hint = "W / S  or  Up / Down  to navigate     Enter to select"
        love.graphics.print(hint, (SCREEN_W - self.fontSub:getWidth(hint)) / 2, SCREEN_H - 22)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return MainMenu
