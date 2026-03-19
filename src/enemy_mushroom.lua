-- enemy_mushroom.lua
-- Mushroom enemy: extends BaseEnemy.
-- Uses Hit animation for death; flips sprite based on movement direction.

local Animation = require("src.animation")
local BaseEnemy = require("src.enemy_base")

local Mushroom = setmetatable({}, {__index = BaseEnemy})
Mushroom.__index = Mushroom

local CFG = {
    folder       = "assets/Enemies/Mushroom/",
    idleFile     = "Idle (32x32).png", idleFrames = 14, idleFps = 10,
    runFile      = "Run (32x32).png",  runFrames  = 16, runFps  = 12,
    hitFile      = "Hit.png",          hitFrames  =  5, hitFps  = 10,
    fw = 32, fh = 32,
    bx =  3, by = 12, bw = 26, bh = 18,
    speed        = 60,
    color        = {1, 1, 1, 1},
    turnDuration = 1.5,
}

-- Lazy-loaded images shared across all Mushroom instances
local _imgs = {}
local function loadImgs()
    if _imgs.loaded then return end
    _imgs.idle = love.graphics.newImage(CFG.folder .. CFG.idleFile)
    _imgs.run  = love.graphics.newImage(CFG.folder .. CFG.runFile)
    _imgs.hit  = love.graphics.newImage(CFG.folder .. CFG.hitFile)
    _imgs.idle:setFilter("nearest", "nearest")
    _imgs.run:setFilter("nearest", "nearest")
    _imgs.hit:setFilter("nearest", "nearest")
    _imgs.loaded = true
end

-- ─── Constructor ──────────────────────────────────────────────────────────────

function Mushroom.new(x, y)
    loadImgs()
    local self = BaseEnemy.new(CFG, x, y)
    setmetatable(self, Mushroom)

    -- Each instance gets its own animation state
    self.anims = {
        idle = Animation.new(_imgs.idle, CFG.fw, CFG.fh, CFG.idleFrames, CFG.idleFps, true),
        run  = Animation.new(_imgs.run,  CFG.fw, CFG.fh, CFG.runFrames,  CFG.runFps,  true),
        hit  = Animation.new(_imgs.hit,  CFG.fw, CFG.fh, CFG.hitFrames,  CFG.hitFps,  false),
    }
    return self
end

-- ─── Update ───────────────────────────────────────────────────────────────────

function Mushroom:update(dt, level)
    BaseEnemy.update(self, dt, level)   -- physics + patrol
    if self.dying then
        self.anims.hit:update(dt)
        if self.anims.hit.done then
            self.dying = false   -- isExpired() returns true; level will remove us
        end
    elseif self.alive then
        if self.turning then
            self.anims.idle:update(dt)
        else
            self.anims.run:update(dt)
        end
    end
end

-- ─── Draw ─────────────────────────────────────────────────────────────────────

function Mushroom:draw()
    if not self.alive and not self.dying then return end

    local c = self.color
    love.graphics.setColor(c[1], c[2], c[3], c[4])

    -- All sprites face LEFT natively: no flip when going left, flip when going right
    local scaleX = (self.dir < 0) and -1 or 1
    if self.dying then
        self.anims.hit:draw(self.x, self.y, scaleX)
    elseif self.turning then
        self.anims.idle:draw(self.x, self.y, scaleX)
    else
        self.anims.run:draw(self.x, self.y, scaleX)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Mushroom
