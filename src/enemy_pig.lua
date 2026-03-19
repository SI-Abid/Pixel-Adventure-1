-- enemy_pig.lua
-- AngryPig enemy: extends BaseEnemy.
-- Uses Hit animation for death; flips sprite based on movement direction.

local Animation = require("src.animation")
local BaseEnemy = require("src.enemy_base")

local Pig = setmetatable({}, {__index = BaseEnemy})
Pig.__index = Pig

local CFG = {
    folder       = "assets/Enemies/AngryPig/",
    idleFile     = "Walk (36x30).png",    idleFrames = 16, idleFps = 10,
    runFile      = "Run (36x30).png",     runFrames  = 12, runFps  = 14,
    hitFile      = "Hit 1 (36x30).png",  hitFrames  =  5, hitFps  = 10,
    fw = 36, fh = 30,
    bx =  6, by = 2, bw = 24, bh = 24,
    speed        = 100,
    color        = {1, 0.8, 0.8, 1},
    turnDuration = 1.5,
}

-- Lazy-loaded images shared across all Pig instances
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

function Pig.new(x, y)
    loadImgs()
    local self = BaseEnemy.new(CFG, x, y)
    setmetatable(self, Pig)

    -- Each instance gets its own animation state
    self.anims = {
        idle = Animation.new(_imgs.idle, CFG.fw, CFG.fh, CFG.idleFrames, CFG.idleFps, true),
        run  = Animation.new(_imgs.run,  CFG.fw, CFG.fh, CFG.runFrames,  CFG.runFps,  true),
        hit  = Animation.new(_imgs.hit,  CFG.fw, CFG.fh, CFG.hitFrames,  CFG.hitFps,  false),
    }
    return self
end

-- ─── Update ───────────────────────────────────────────────────────────────────

function Pig:update(dt, level)
    BaseEnemy.update(self, dt, level)   -- physics + patrol
    if self.dying then
        self.anims.hit:update(dt)
        if self.anims.hit.done then
            self.dying = false   -- isExpired() returns true; level will remove us
        end
    elseif self.alive then
        self.anims.run:update(dt)
    end
end

-- ─── Draw ─────────────────────────────────────────────────────────────────────

function Pig:draw()
    if not self.alive and not self.dying then return end

    local c = self.color
    love.graphics.setColor(c[1], c[2], c[3], c[4])

    -- All sprites face LEFT natively: no flip when going left, flip when going right
    local scaleX = (self.dir < 0) and -1 or 1
    if self.dying then
        self.anims.hit:draw(self.x, self.y, scaleX)
    else
        self.anims.run:draw(self.x, self.y, scaleX)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Pig
