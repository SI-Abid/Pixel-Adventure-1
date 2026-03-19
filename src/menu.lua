-- menu.lua
-- Character selection screen: 4 animated character cards.
-- Returns the chosen character folder path via keypressed / mousepressed.

local Animation    = require("src.animation")
local CharProfiles = require("src.char_profiles")

local Menu = {}
Menu.__index = Menu

local SCREEN_W = 800
local SCREEN_H = 450

local CHARS = {
    { name = "Mask Dude",   path = "assets/Main Characters/Mask Dude/"   },
    { name = "Ninja Frog",  path = "assets/Main Characters/Ninja Frog/"  },
    { name = "Pink Man",    path = "assets/Main Characters/Pink Man/"     },
    { name = "Virtual Guy", path = "assets/Main Characters/Virtual Guy/"  },
}

local CARD_W     = 150
local CARD_H     = 210   -- taller to fit special info
local CARD_GAP   = 20
local CARDS_X    = (SCREEN_W - (4 * CARD_W + 3 * CARD_GAP)) / 2
local CARDS_Y    = 140
local SPRITE_SCL = 3   -- 32×32 → 96×96

function Menu.new()
    local self = setmetatable({}, Menu)
    self.selected = 1
    self.chars    = {}

    for i, c in ipairs(CHARS) do
        local img     = love.graphics.newImage(c.path .. "Idle (32x32).png")
        img:setFilter("nearest", "nearest")
        local profile = CharProfiles[c.path] or {}
        self.chars[i] = {
            name        = c.name,
            path        = c.path,
            anim        = Animation.new(img, 32, 32, 11, 10, true),
            specialName = profile.specialName or "?",
            specialDesc = profile.specialDesc or "",
            favFruit    = (profile.favoriteFruit or ""):gsub("%.png$", ""),
        }
    end

    self.fontSm  = love.graphics.newFont(14)
    self.fontLg  = love.graphics.newFont(36)
    self.fontMd  = love.graphics.newFont(18)

    return self
end

-- Update animations every frame; returns chosen path or nil
function Menu:update(dt)
    for _, c in ipairs(self.chars) do
        c.anim:update(dt)
    end
    return nil
end

-- Returns chosen path or nil
function Menu:keypressed(key)
    if key == "left" or key == "a" then
        self.selected = (self.selected - 2) % #self.chars + 1
    elseif key == "right" or key == "d" then
        self.selected = self.selected % #self.chars + 1
    elseif key == "return" or key == "space" then
        return self.chars[self.selected].path
    end
    return nil
end

-- Returns chosen path or nil
function Menu:mousepressed(mx, my, button)
    if button ~= 1 then return nil end
    for i = 1, #self.chars do
        local cx = CARDS_X + (i - 1) * (CARD_W + CARD_GAP)
        local cy = CARDS_Y
        if mx >= cx and mx <= cx + CARD_W and my >= cy and my <= cy + CARD_H then
            if self.selected == i then
                return self.chars[i].path   -- second click starts game
            else
                self.selected = i
            end
        end
    end
    return nil
end

function Menu:draw()
    -- Dark gradient background
    love.graphics.setColor(0.05, 0.05, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    -- Title
    love.graphics.setFont(self.fontLg)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    local title = "PIXEL ADVENTURE"
    love.graphics.print(title, (SCREEN_W - self.fontLg:getWidth(title)) / 2, 40)

    -- Subtitle
    love.graphics.setFont(self.fontMd)
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    local sub = "Choose your character"
    love.graphics.print(sub, (SCREEN_W - self.fontMd:getWidth(sub)) / 2, 100)

    -- Cards
    for i, c in ipairs(self.chars) do
        local cx  = CARDS_X + (i - 1) * (CARD_W + CARD_GAP)
        local cy  = CARDS_Y
        local sel = (i == self.selected)

        -- Card background
        if sel then
            love.graphics.setColor(0.15, 0.15, 0.35, 1)
        else
            love.graphics.setColor(0.08, 0.08, 0.18, 0.9)
        end
        love.graphics.rectangle("fill", cx, cy, CARD_W, CARD_H, 6, 6)

        -- Border
        if sel then
            love.graphics.setColor(1, 0.85, 0.2, 1)
            love.graphics.setLineWidth(2)
        else
            love.graphics.setColor(0.4, 0.4, 0.5, 1)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", cx, cy, CARD_W, CARD_H, 6, 6)
        love.graphics.setLineWidth(1)

        -- Sprite (96×96, centered in card)
        local sprW  = 32 * SPRITE_SCL
        local sprX  = cx + (CARD_W - sprW) / 2
        local sprY  = cy + 20
        if sel then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.55, 0.55, 0.55, 1)
        end
        love.graphics.push()
        love.graphics.translate(sprX, sprY)
        love.graphics.scale(SPRITE_SCL, SPRITE_SCL)
        c.anim:draw(0, 0, 1)
        love.graphics.pop()

        -- Name label
        love.graphics.setFont(self.fontSm)
        if sel then
            love.graphics.setColor(1, 0.85, 0.2, 1)
        else
            love.graphics.setColor(0.6, 0.6, 0.6, 1)
        end
        love.graphics.print(
            c.name,
            cx + (CARD_W - self.fontSm:getWidth(c.name)) / 2,
            cy + 122
        )

        -- Special name (below character name)
        local specialColor = sel and {0.5, 1, 0.5, 1} or {0.35, 0.65, 0.35, 0.8}
        love.graphics.setColor(specialColor[1], specialColor[2], specialColor[3], specialColor[4])
        local sn = c.specialName
        love.graphics.print(sn, cx + (CARD_W - self.fontSm:getWidth(sn)) / 2, cy + 140)

        -- Special description
        local descColor = sel and {0.8, 0.8, 0.8, 1} or {0.4, 0.4, 0.4, 0.8}
        love.graphics.setColor(descColor[1], descColor[2], descColor[3], descColor[4])
        local sd = c.specialDesc
        love.graphics.print(sd, cx + (CARD_W - self.fontSm:getWidth(sd)) / 2, cy + 157)

        -- Favourite fruit label
        local favColor = sel and {1, 0.6, 0.8, 1} or {0.5, 0.35, 0.4, 0.8}
        love.graphics.setColor(favColor[1], favColor[2], favColor[3], favColor[4])
        local fav = "Fav: " .. c.favFruit
        love.graphics.print(fav, cx + (CARD_W - self.fontSm:getWidth(fav)) / 2, cy + 175)
    end

    -- Bottom prompt
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.setFont(self.fontSm)
    local prompt = "A / D  or  Left / Right  to select     Enter / click twice to start"
    love.graphics.print(
        prompt,
        (SCREEN_W - self.fontSm:getWidth(prompt)) / 2,
        CARDS_Y + CARD_H + 18
    )
end

return Menu
