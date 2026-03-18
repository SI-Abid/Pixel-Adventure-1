-- player.lua
-- Player class: selectable character, state machine, physics, double jump.

local Animation = require("animation")

local Player = {}
Player.__index = Player

local GRAVITY    = 800
local JUMP_VEL   = -450
local MOVE_SPEED = 120
local MAX_FALL   = 600
local HIT_DURATION = 1.5

local FRAME_COUNTS = {
    idle        = 11,
    run         = 12,
    jump        = 1,
    fall        = 1,
    hit         = 7,
    double_jump = 6,
}

-- charPath: e.g. "assets/Main Characters/Mask Dude/"
-- Defaults to Mask Dude if nil.
function Player.new(x, y, charPath)
    local self = setmetatable({}, Player)

    local base = charPath or "assets/Main Characters/Mask Dude/"

    local imgs = {
        idle        = love.graphics.newImage(base .. "Idle (32x32).png"),
        run         = love.graphics.newImage(base .. "Run (32x32).png"),
        jump        = love.graphics.newImage(base .. "Jump (32x32).png"),
        fall        = love.graphics.newImage(base .. "Fall (32x32).png"),
        hit         = love.graphics.newImage(base .. "Hit (32x32).png"),
        double_jump = love.graphics.newImage(base .. "Double Jump (32x32).png"),
    }
    for _, img in pairs(imgs) do
        img:setFilter("nearest", "nearest")
    end

    self.anims = {
        idle        = Animation.new(imgs.idle,        32, 32, FRAME_COUNTS.idle,        10, true),
        run         = Animation.new(imgs.run,         32, 32, FRAME_COUNTS.run,         12, true),
        jump        = Animation.new(imgs.jump,        32, 32, FRAME_COUNTS.jump,        8,  true),
        fall        = Animation.new(imgs.fall,        32, 32, FRAME_COUNTS.fall,        8,  true),
        hit         = Animation.new(imgs.hit,         32, 32, FRAME_COUNTS.hit,         8,  false),
        double_jump = Animation.new(imgs.double_jump, 32, 32, FRAME_COUNTS.double_jump, 10, true),
    }

    self.x           = x
    self.y           = y
    self.vx          = 0
    self.vy          = 0
    self.onGround    = false
    self.facingRight = true

    self.lives     = 3
    self.score     = 0
    self.state     = "idle"
    self.hitTimer  = 0

    -- Double-jump
    self.jumpsLeft = 2   -- resets to 2 on landing

    -- Hitbox: 20×28, offset (6, 2) from sprite origin
    self.bw = 20
    self.bh = 28
    self.bx = 6
    self.by = 2

    return self
end

function Player:getHitbox()
    return self.x + self.bx, self.y + self.by, self.bw, self.bh
end

function Player:takeDamage()
    if self.hitTimer > 0 then return end
    self.lives    = self.lives - 1
    self.hitTimer = HIT_DURATION
    self.state    = "hit"
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

    -- Horizontal input (blocked during hit)
    local inputX = 0
    if self.state ~= "hit" then
        if love.keyboard.isDown("left",  "a") then inputX = -1 end
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
        self.x  = self.x - collX
        self.vx = 0
    end

    -- Left boundary: never go left of world origin
    if self.x < 0 then self.x = 0 end

    -- Left boundary: never go left of the camera left edge
    if level.camX and self.x < level.camX then
        self.x  = level.camX
        self.vx = 0
    end

    -- Vertical movement + collision
    self.y = self.y + self.vy * dt
    hx, hy, hw, hh = self:getHitbox()
    local collY = level:resolveVertical(hx, hy, hw, hh, self.vy)
    if collY ~= 0 then
        self.y = self.y - collY
        if self.vy > 0 then
            self.onGround  = true
            self.jumpsLeft = 2   -- reset double-jump on landing
        end
        self.vy = 0
    else
        self.onGround = false
    end

    -- State machine
    if self.state == "hit" then
        if self.anims.hit.done then
            self.state = "idle"
        end
    elseif not self.onGround then
        if self.state == "double_jump" then
            -- stay in double_jump until falling
            if self.vy >= 0 then self.state = "fall" end
        elseif self.vy < 0 then
            self.state = "jump"
        else
            self.state = "fall"
        end
    elseif self.vx ~= 0 then
        self.state = "run"
    else
        self.state = "idle"
    end

    self.anims[self.state]:update(dt)
end

-- Returns true when a jump is initiated (caller can play sound)
function Player:keypressed(key)
    if key == "up" or key == "w" or key == "space" then
        if self.state ~= "hit" and self.jumpsLeft > 0 then
            local isDoubleJump = (not self.onGround and self.jumpsLeft == 1)
            self.vy        = JUMP_VEL
            self.onGround  = false
            self.jumpsLeft = self.jumpsLeft - 1
            if isDoubleJump then
                self.state = "double_jump"
                self.anims.double_jump:reset()
            else
                self.state = "jump"
                self.anims.jump:reset()
            end
            return true   -- signal: jump happened
        end
    end
    return false
end

function Player:draw()
    local anim   = self.anims[self.state]
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
