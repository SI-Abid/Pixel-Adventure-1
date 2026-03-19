-- enemy_pig.lua
-- AngryPig enemy: extends BaseEnemy, driven by src/pig.lua state machine.
-- States: Walk → Hit1 → Run → Hit2 → Dead

local Animation = require("src.animation")
local BaseEnemy = require("src.enemy_base")
local PigSM     = require("src.pig")

local Pig = setmetatable({}, {__index = BaseEnemy})
Pig.__index = Pig

-- Grace period after entering Run before gap checks can trigger stop_chase.
-- Prevents instant Walk reversion when the pig enters Run near a gap.
local MIN_RUN_TIME = 0.25      -- seconds

local CFG = {
    folder       = "assets/Enemies/AngryPig/",
    idleFile     = "Walk (36x30).png",    idleFrames = 16, idleFps = 10,
    runFile      = "Run (36x30).png",     runFrames  = 12, runFps  = 14,
    hit1File     = "Hit 1 (36x30).png",  hit1Frames =  5, hit1Fps = 10,
    hit2File     = "Hit 2 (36x30).png",  hit2Frames =  5, hit2Fps = 10,
    fw = 36, fh = 30,
    bx =  3, by = 1, bw = 30, bh = 27,
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
    self.last_player_y  = y
    self.last_sm_state  = "Walk"
    self.run_speed      = CFG.run_speed
    self.run_enter_timer = 0   -- time spent in Run state this cycle

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

-- player_x/player_y are optional args from main.lua (enemy:update(dt, level, player.x, player.y)).
-- Other enemy types ignore them; Lua silently discards extra arguments.
function Pig:update(dt, level, player_x, player_y)
    if player_x then self.last_player_x = player_x end
    if player_y then self.last_player_y = player_y end

    -- Drive the state machine (handles Hit1/Hit2 timers, transitions)
    PigSM.update(self.sm, dt, self.last_player_x)

    local state = self.sm.state

    -- Reset animation when the state changes
    if state ~= self.last_sm_state then
        local anim = self.anims[state]
        if anim then anim:reset() end
        self.last_sm_state = state
        -- Reset the grace-period timer whenever we (re)enter Run
        if state == "Run" then self.run_enter_timer = 0 end
    end

    -- Per-state movement and animation
    if state == "Walk" then
        BaseEnemy.update(self, dt, level)   -- patrol + gap detection
        self.anims.Walk:update(dt)

    elseif state == "Hit1" then
        self.vx = 0
        self.anims.Hit1:update(dt)

    elseif state == "Run" then
        self.run_enter_timer = self.run_enter_timer + dt

        local pig_center = self.x + self.bx + self.bw / 2
        if self.last_player_x > pig_center then
            self.vx  = self.run_speed
            self.dir = -1   -- facing right (sprite flipped)
        else
            self.vx  = -self.run_speed
            self.dir = 1    -- facing left (no flip)
        end

        -- Only apply gap check after the grace period expires.
        -- This prevents instant Walk reversion on the first Run frame near a gap.
        if self.run_enter_timer >= MIN_RUN_TIME and level and self:_checkGapAhead(level) then
            PigSM.stop_chase(self.sm)
            self.vx = -self.dir * self.speed   -- drop back to patrol speed
        else
            self.x = self.x + self.vx * dt
        end
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
