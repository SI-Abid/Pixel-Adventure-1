-- src/trap_fire.lua
-- FireTrap: a fire trap with three states driven by src/fire_logic.lua.
--
-- States
--   Off  → dormant, static sprite, no damage
--   Hit  → ignition animation (one-shot, 4 frames), triggered on first player touch
--   On   → looping flame animation, damages the player on contact

local Animation = require("src.animation")
local FireLogic = require("src.fire_logic")

local FireTrap = {}
FireTrap.__index = FireTrap

local CFG = {
    folder    = "assets/Traps/Fire/",
    offFile   = "Off.png",
    hitFile   = "Hit (16x32).png",  hitFrames = 4, hitFps = 12,
    onFile    = "On (16x32).png",   onFrames  = 3, onFps  =  8,
    fw = 16, fh = 32,
    bx = 2, by = 8, bw = 12, bh = 24,
}

local _imgs = {}
local function loadImgs()
    if _imgs.loaded then return end
    _imgs.off = love.graphics.newImage(CFG.folder .. CFG.offFile)
    _imgs.hit = love.graphics.newImage(CFG.folder .. CFG.hitFile)
    _imgs.on  = love.graphics.newImage(CFG.folder .. CFG.onFile)
    _imgs.off:setFilter("nearest", "nearest")
    _imgs.hit:setFilter("nearest", "nearest")
    _imgs.on:setFilter("nearest", "nearest")
    _imgs.loaded = true
end

-- ─── Constructor ──────────────────────────────────────────────────────────────

--- @param x            number
--- @param y            number
--- @param burn_duration number|nil  Seconds the fire stays On (default: random 2–3 s).
function FireTrap.new(x, y, burn_duration)
    loadImgs()
    local self    = setmetatable({}, FireTrap)
    self.x        = x
    self.y        = y
    self.fw       = CFG.fw
    self.fh       = CFG.fh
    self.bx       = CFG.bx
    self.by       = CFG.by
    self.bw       = CFG.bw
    self.bh       = CFG.bh
    -- Random 2–3 s burn when no duration is supplied by the caller.
    self.fire     = FireLogic.new(burn_duration or (2 + math.random()))
    self.off_img  = _imgs.off
    self.anims    = {
        hit = Animation.new(_imgs.hit, CFG.fw, CFG.fh, CFG.hitFrames, CFG.hitFps, false),
        on  = Animation.new(_imgs.on,  CFG.fw, CFG.fh, CFG.onFrames,  CFG.onFps,  true),
    }
    return self
end

-- ─── Interface ────────────────────────────────────────────────────────────────

function FireTrap:getHitbox()
    return self.x + self.bx, self.y + self.by, self.bw, self.bh
end

--- Called by main.lua on every frame the player overlaps this trap.
--- Triggers ignition the first time (Off → Hit); no-op afterwards.
function FireTrap:trigger()
    local was_off = self.fire.state == "Off"
    FireLogic.trigger(self.fire)
    if was_off and self.fire.state == "Hit" then
        self.anims.hit:reset()   -- ensure animation starts from frame 1
    end
end

--- Returns true only in the On state — the only state that damages the player.
function FireTrap:isActive()
    return FireLogic.is_active(self.fire)
end

-- ─── Update ───────────────────────────────────────────────────────────────────

function FireTrap:update(dt)
    local state = self.fire.state
    if state == "Hit" then
        self.anims.hit:update(dt)
        FireLogic.update(self.fire, dt, self.anims.hit.done)
    elseif state == "On" then
        self.anims.on:update(dt)
        FireLogic.update(self.fire, dt, false)  -- tick burn timer
    end
    -- Off: nothing to animate
end

-- ─── Draw ─────────────────────────────────────────────────────────────────────

function FireTrap:draw()
    love.graphics.setColor(1, 1, 1, 1)
    local state = self.fire.state
    if state == "Off" then
        love.graphics.draw(self.off_img, self.x, self.y)
    elseif state == "Hit" then
        self.anims.hit:draw(self.x, self.y, 1)
    elseif state == "On" then
        self.anims.on:draw(self.x, self.y, 1)
    end
end

return FireTrap
