-- enemy_pig.lua
-- AngryPig enemy: extends BaseEnemy, driven by src/pig.lua state machine.
-- States: Walk → Hit1 → Run → Hit2 → Dead

local Animation = require("src.animation")
local BaseEnemy = require("src.enemy_base")
local PigSM     = require("src.pig")

local Pig = setmetatable({}, {__index = BaseEnemy})
Pig.__index = Pig

local CFG = {
    folder       = "assets/Enemies/AngryPig/",
    idleFile     = "Walk (36x30).png",    idleFrames = 16, idleFps = 10,
    runFile      = "Run (36x30).png",     runFrames  = 12, runFps  = 14,
    hit1File     = "Hit 1 (36x30).png",  hit1Frames =  5, hit1Fps = 10,
    hit2File     = "Hit 2 (36x30).png",  hit2Frames =  5, hit2Fps = 10,
    fw = 36, fh = 30,
    bx =  6, by = 2, bw = 24, bh = 24,
    speed        = 80,    -- Walk patrol speed
    run_speed    = 200,   -- Run (chase) speed — noticeably faster than Walk
    color        = {1, 0.8, 0.8, 1},
    turnDuration = 1.5,
}

-- Lazy-loaded images shared across all Pig instances
local _imgs = {}
local function loadImgs()
    if _imgs.loaded then return end
    _imgs.idle = love.graphics.newImage(CFG.folder .. CFG.idleFile)
    _imgs.run  = love.graphics.newImage(CFG.folder .. CFG.runFile)
    _imgs.hit1 = love.graphics.newImage(CFG.folder .. CFG.hit1File)
    _imgs.hit2 = love.graphics.newImage(CFG.folder .. CFG.hit2File)
    _imgs.idle:setFilter("nearest", "nearest")
    _imgs.run:setFilter("nearest", "nearest")
    _imgs.hit1:setFilter("nearest", "nearest")
    _imgs.hit2:setFilter("nearest", "nearest")
    _imgs.loaded = true
end

-- ─── Constructor ──────────────────────────────────────────────────────────────

function Pig.new(x, y)
    loadImgs()
    local self = BaseEnemy.new(CFG, x, y)
    setmetatable(self, Pig)

    self.sm             = PigSM.new()
    self.last_player_x  = x
    self.last_sm_state  = "Walk"
    self.run_speed      = CFG.run_speed

    -- Animations keyed by state name
    self.anims = {
        Walk = Animation.new(_imgs.idle, CFG.fw, CFG.fh, CFG.idleFrames, CFG.idleFps, true),
        Run  = Animation.new(_imgs.run,  CFG.fw, CFG.fh, CFG.runFrames,  CFG.runFps,  true),
        Hit1 = Animation.new(_imgs.hit1, CFG.fw, CFG.fh, CFG.hit1Frames, CFG.hit1Fps, false),
        Hit2 = Animation.new(_imgs.hit2, CFG.fw, CFG.fh, CFG.hit2Frames, CFG.hit2Fps, false),
    }
    return self
end

-- ─── Update ───────────────────────────────────────────────────────────────────

-- player_x is an optional third argument passed by main.lua (enemy:update(dt, level, player.x)).
-- Other enemy types ignore it; Lua silently discards extra arguments.
function Pig:update(dt, level, player_x)
    if player_x then
        self.last_player_x = player_x
    end

    -- Drive the state machine (handles Hit1/Hit2 timers, transitions)
    PigSM.update(self.sm, dt, self.last_player_x)

    local state = self.sm.state

    -- Reset animation when the state changes
    if state ~= self.last_sm_state then
        local anim = self.anims[state]
        if anim then anim:reset() end
        self.last_sm_state = state
    end

    -- Per-state movement and animation
    if state == "Walk" then
        BaseEnemy.update(self, dt, level)   -- patrol + gap detection
        self.anims.Walk:update(dt)

    elseif state == "Hit1" then
        self.vx = 0
        self.anims.Hit1:update(dt)

    elseif state == "Run" then
        local pig_center = self.x + self.bx + self.bw / 2
        if self.last_player_x > pig_center then
            self.vx  = self.run_speed
            self.dir = -1   -- facing right (sprite flipped)
        else
            self.vx  = -self.run_speed
            self.dir = 1    -- facing left (no flip)
        end
        -- Stop at ledge edges instead of running into the void
        if level and self:_checkGapAhead(level) then
            self.vx = 0
        end
        self.x = self.x + self.vx * dt
        self.anims.Run:update(dt)

    elseif state == "Hit2" then
        self.vx = 0
        self.anims.Hit2:update(dt)

    end
    -- Dead: no movement, no animation update; level will remove via isExpired()
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

-- Called by main.lua on stomp. Delegates to the state machine — does NOT call
-- BaseEnemy:kill() so the pig stays "alive" for a second hit.
function Pig:kill()
    PigSM.take_damage(self.sm)
end

-- Pig is expired (ready to be removed) only when the state machine is Dead.
function Pig:isExpired()
    return self.sm.state == "Dead"
end

-- No collision in Dead state (pig is being removed this frame).
function Pig:checkCollision(px, py, pw, ph)
    if self.sm.state == "Dead" then return false end
    return BaseEnemy.checkCollision(self, px, py, pw, ph)
end

-- ─── Draw ─────────────────────────────────────────────────────────────────────

function Pig:draw()
    local state = self.sm.state
    if state == "Dead" then return end

    local c = self.color
    love.graphics.setColor(c[1], c[2], c[3], c[4])

    -- Sprites face LEFT natively: dir=1→left (no flip), dir=-1→right (flip)
    local scaleX = (self.dir < 0) and -1 or 1
    local anim   = self.anims[state]
    if anim then
        anim:draw(self.x, self.y, scaleX)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Pig
