-- player.lua
-- Player class: Mask Dude with state machine, physics, and collision.

local Animation = require("animation")

local Player = {}
Player.__index = Player

local ASSET_BASE = "assets/Main Characters/Mask Dude/"

local GRAVITY    = 800
local JUMP_VEL   = -450
local MOVE_SPEED = 120
local MAX_FALL   = 600
local HIT_DURATION = 1.5

local FRAME_COUNTS = {
    idle = 11,
    run  = 12,
    jump = 1,
    fall = 1,
    hit  = 7,
}

function Player.new(x, y)
    local self = setmetatable({}, Player)

    local imgs = {
        idle = love.graphics.newImage(ASSET_BASE .. "Idle (32x32).png"),
        run  = love.graphics.newImage(ASSET_BASE .. "Run (32x32).png"),
        jump = love.graphics.newImage(ASSET_BASE .. "Jump (32x32).png"),
        fall = love.graphics.newImage(ASSET_BASE .. "Fall (32x32).png"),
        hit  = love.graphics.newImage(ASSET_BASE .. "Hit (32x32).png"),
    }
    for _, img in pairs(imgs) do
        img:setFilter("nearest", "nearest")
    end

    self.anims = {
        idle = Animation.new(imgs.idle, 32, 32, FRAME_COUNTS.idle, 10, true),
        run  = Animation.new(imgs.run,  32, 32, FRAME_COUNTS.run,  12, true),
        jump = Animation.new(imgs.jump, 32, 32, FRAME_COUNTS.jump, 8,  true),
        fall = Animation.new(imgs.fall, 32, 32, FRAME_COUNTS.fall, 8,  true),
        hit  = Animation.new(imgs.hit,  32, 32, FRAME_COUNTS.hit,  8,  false),
    }

    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.onGround = false
    self.facingRight = true

    self.lives    = 3
    self.score    = 0
    self.state    = "idle"
    self.hitTimer = 0

    -- Hitbox: narrower than 32x32 sprite for fairness
    self.bw = 20
    self.bh = 28
    self.bx = 6   -- offset from self.x
    self.by = 2   -- offset from self.y

    return self
end

function Player:getHitbox()
    return self.x + self.bx, self.y + self.by, self.bw, self.bh
end

function Player:takeDamage()
    if self.hitTimer > 0 then return end
    self.lives = self.lives - 1
    self.hitTimer = HIT_DURATION
    self.state = "hit"
    self.anims.hit:reset()
    self.vx = 0
    self.vy = -200
end

function Player:addScore(amount)
    self.score = self.score + amount
end

function Player:update(dt, level)
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end

    -- Input (blocked during hit state)
    local inputX = 0
    if self.state ~= "hit" then
        if love.keyboard.isDown("left", "a")  then inputX = -1 end
        if love.keyboard.isDown("right", "d") then inputX =  1 end
    end

    self.vx = inputX * MOVE_SPEED
    if inputX ~= 0 then
        self.facingRight = (inputX > 0)
    end

    -- Gravity
    self.vy = self.vy + GRAVITY * dt
    if self.vy > MAX_FALL then self.vy = MAX_FALL end

    -- Horizontal movement + collision
    self.x = self.x + self.vx * dt
    local hx, hy, hw, hh = self:getHitbox()
    local collX = level:resolveHorizontal(hx, hy, hw, hh)
    if collX ~= 0 then
        self.x = self.x - collX
        self.vx = 0
    end

    -- Vertical movement + collision
    self.y = self.y + self.vy * dt
    hx, hy, hw, hh = self:getHitbox()
    local collY = level:resolveVertical(hx, hy, hw, hh, self.vy)
    if collY ~= 0 then
        self.y = self.y - collY
        if self.vy > 0 then
            self.onGround = true
        end
        self.vy = 0
    else
        self.onGround = false
    end

    -- Clamp to left boundary
    if self.x < 0 then self.x = 0 end

    -- State machine
    if self.state == "hit" then
        if self.anims.hit.done then
            self.state = "idle"
        end
    elseif not self.onGround then
        self.state = (self.vy < 0) and "jump" or "fall"
    elseif self.vx ~= 0 then
        self.state = "run"
    else
        self.state = "idle"
    end

    self.anims[self.state]:update(dt)
end

function Player:keypressed(key)
    if (key == "up" or key == "w" or key == "space") then
        if self.onGround and self.state ~= "hit" then
            self.vy = JUMP_VEL
            self.onGround = false
            self.state = "jump"
            self.anims.jump:reset()
        end
    end
end

function Player:draw()
    local anim = self.anims[self.state]
    local scaleX = self.facingRight and 1 or -1

    -- Blink during invincibility
    if self.hitTimer > 0 then
        if math.floor(self.hitTimer / 0.1) % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.4)
        end
    end

    anim:draw(self.x, self.y, scaleX)
    love.graphics.setColor(1, 1, 1, 1)
end

return Player
