-- enemy.lua
-- Enemy class: Virtual Guy with patrol AI and red color tint.

local Animation = require("src.animation")

local Enemy = {}
Enemy.__index = Enemy

local ASSET_BASE   = "assets/Main Characters/Virtual Guy/"
local PATROL_SPEED = 60

function Enemy.new(x, y, patrolLeft, patrolRight)
    local self = setmetatable({}, Enemy)

    local imgRun  = love.graphics.newImage(ASSET_BASE .. "Run (32x32).png")
    local imgIdle = love.graphics.newImage(ASSET_BASE .. "Idle (32x32).png")
    imgRun:setFilter("nearest", "nearest")
    imgIdle:setFilter("nearest", "nearest")

    self.anims = {
        run  = Animation.new(imgRun,  32, 32, 12, 12, true),
        idle = Animation.new(imgIdle, 32, 32, 11, 10, true),
    }

    self.x = x
    self.y = y
    self.patrolLeft  = patrolLeft
    self.patrolRight = patrolRight
    self.vx          = PATROL_SPEED
    self.facingRight  = true
    self.alive       = true
    self.dying       = false   -- true during death animation (pop up and fall off)
    self.vy          = 0       -- vertical velocity for death animation
    self.rotation    = 0       -- spin during death

    -- Hitbox (same proportions as player)
    self.bw = 20
    self.bh = 28
    self.bx = 6
    self.by = 2

    return self
end

function Enemy:getHitbox()
    return self.x + self.bx, self.y + self.by, self.bw, self.bh
end

function Enemy:kill()
    self.alive  = false
    self.dying  = true
    self.vy     = -250   -- pop up
    self.vx     = 0
end

function Enemy:update(dt)
    -- Death animation: pop up, spin, fall off screen
    if self.dying then
        self.vy = self.vy + 600 * dt   -- gravity
        self.y  = self.y + self.vy * dt
        self.rotation = self.rotation + 8 * dt  -- spin
        -- Remove once off screen
        if self.y > 600 then
            self.dying = false
        end
        self.anims.idle:update(dt)
        return
    end

    if not self.alive then return end

    self.x = self.x + self.vx * dt

    if self.vx > 0 and self.x >= self.patrolRight then
        self.x = self.patrolRight
        self.vx = -PATROL_SPEED
        self.facingRight = false
    elseif self.vx < 0 and self.x <= self.patrolLeft then
        self.x = self.patrolLeft
        self.vx = PATROL_SPEED
        self.facingRight = true
    end

    local state = (self.vx ~= 0) and "run" or "idle"
    self.anims[state]:update(dt)
end

function Enemy:draw()
    if not self.alive and not self.dying then return end

    if self.dying then
        -- Draw flipped upside-down, spinning, falling
        love.graphics.setColor(1, 0.3, 0.3, 1)
        local anim = self.anims.idle
        local quad = anim.quads[anim.currentFrame]
        local cx = self.x + 16  -- center of 32x32 sprite
        local cy = self.y + 16
        love.graphics.draw(
            anim.image, quad,
            cx, cy,
            self.rotation,   -- rotation
            1, -1,           -- scaleX=1, scaleY=-1 (flipped upside down)
            16, 16           -- origin at sprite center
        )
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    local state = (self.vx ~= 0) and "run" or "idle"
    local scaleX = self.facingRight and 1 or -1
    love.graphics.setColor(1, 0.3, 0.3, 1)
    self.anims[state]:draw(self.x, self.y, scaleX)
    love.graphics.setColor(1, 1, 1, 1)
end

function Enemy:checkCollision(px, py, pw, ph)
    if not self.alive then return false end
    local ex, ey, ew, eh = self:getHitbox()
    return px < ex + ew and px + pw > ex and
           py < ey + eh and py + ph > ey
end

return Enemy
