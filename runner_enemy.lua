-- runner_enemy.lua
-- Multi-type enemy for the infinite runner level.
-- Enemies always walk left; stomp-to-kill mechanic; death animation.

local Animation = require("animation")

local RunnerEnemy = {}
RunnerEnemy.__index = RunnerEnemy

local GRAVITY = 600

-- Enemy type definitions
local TYPES = {
    mushroom = {
        folder     = "assets/Enemies/Mushroom/",
        idleFile   = "Idle (32x32).png",  idleFrames = 14, idleFps = 10,
        runFile    = "Run (32x32).png",   runFrames  = 16, runFps  = 12,
        fw = 32, fh = 32,
        bx =  6, by = 2, bw = 20, bh = 28,
        speed = 60,
        color = {1, 1, 1, 1},
    },
    chicken = {
        folder     = "assets/Enemies/Chicken/",
        idleFile   = "Idle (32x34).png",  idleFrames = 13, idleFps = 10,
        runFile    = "Run (32x34).png",   runFrames  = 14, runFps  = 12,
        fw = 32, fh = 34,
        bx =  6, by = 4, bw = 20, bh = 26,
        speed = 75,
        color = {1, 1, 1, 1},
    },
    pig = {
        folder     = "assets/Enemies/AngryPig/",
        idleFile   = "Walk (36x30).png",  idleFrames = 16, idleFps = 10,
        runFile    = "Run (36x30).png",   runFrames  = 12, runFps  = 14,
        fw = 36, fh = 30,
        bx =  6, by = 2, bw = 24, bh = 24,
        speed = 100,
        color = {1, 0.8, 0.8, 1},
    },
}

function RunnerEnemy.new(x, y, typeName)
    local self = setmetatable({}, RunnerEnemy)
    local cfg  = TYPES[typeName] or TYPES.mushroom

    local imgIdle = love.graphics.newImage(cfg.folder .. cfg.idleFile)
    local imgRun  = love.graphics.newImage(cfg.folder .. cfg.runFile)
    imgIdle:setFilter("nearest", "nearest")
    imgRun:setFilter("nearest", "nearest")

    self.anims = {
        idle = Animation.new(imgIdle, cfg.fw, cfg.fh, cfg.idleFrames, cfg.idleFps, true),
        run  = Animation.new(imgRun,  cfg.fw, cfg.fh, cfg.runFrames,  cfg.runFps,  true),
    }

    self.fw    = cfg.fw
    self.fh    = cfg.fh
    self.x     = x
    self.y     = y
    self.vx    = -cfg.speed   -- always walking left
    self.vy    = 0
    self.alive = true
    self.dying = false
    self.rotation = 0
    self.bx    = cfg.bx
    self.by    = cfg.by
    self.bw    = cfg.bw
    self.bh    = cfg.bh
    self.color = cfg.color

    return self
end

function RunnerEnemy:getHitbox()
    return self.x + self.bx, self.y + self.by, self.bw, self.bh
end

function RunnerEnemy:kill()
    self.alive    = false
    self.dying    = true
    self.vy       = -250   -- pop up
    self.vx       = 0
end

function RunnerEnemy:update(dt)
    if self.dying then
        self.vy       = self.vy + GRAVITY * dt
        self.y        = self.y  + self.vy  * dt
        self.rotation = self.rotation + 8 * dt
        if self.y > 700 then
            self.dying = false
        end
        self.anims.idle:update(dt)
        return
    end
    if not self.alive then return end

    self.x = self.x + self.vx * dt
    self.anims.run:update(dt)
end

function RunnerEnemy:draw()
    if not self.alive and not self.dying then return end

    if self.dying then
        love.graphics.setColor(1, 0.3, 0.3, 1)
        local anim = self.anims.idle
        local quad = anim.quads[anim.currentFrame]
        local cx   = self.x + self.fw / 2
        local cy   = self.y + self.fh / 2
        love.graphics.draw(
            anim.image, quad,
            cx, cy,
            self.rotation,
            1, -1,
            self.fw / 2, self.fh / 2
        )
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Always facing left (moving left), so flip horizontally
    local c = self.color
    love.graphics.setColor(c[1], c[2], c[3], c[4])
    self.anims.run:draw(self.x, self.y, -1)
    love.graphics.setColor(1, 1, 1, 1)
end

function RunnerEnemy:checkCollision(px, py, pw, ph)
    if not self.alive then return false end
    local ex, ey, ew, eh = self:getHitbox()
    return px < ex + ew and px + pw > ex and
           py < ey + eh and py + ph > ey
end

return RunnerEnemy
