-- trap.lua
-- Spike, Saw, and Fire trap classes for the infinite runner level.

local Animation = require("src.animation")

local Trap = {}
Trap.__index = Trap

-- Preloaded images (lazy-load on first use per type)
local _imgs = {}

local function loadImg(path)
    if not _imgs[path] then
        _imgs[path] = love.graphics.newImage(path)
        _imgs[path]:setFilter("nearest", "nearest")
    end
    return _imgs[path]
end

-- Trap configs
local CONFIGS = {
    spike = {
        imgPath  = "assets/Traps/Spikes/Idle.png",
        fw = 16, fh = 16, frames = 1, fps = 1, loops = true,
        bx = 1, by = 4, bw = 14, bh = 12,   -- hitbox insets for fairness
    },
    saw = {
        imgPath  = "assets/Traps/Saw/On (38x38).png",
        fw = 38, fh = 38, frames = 8, fps = 8, loops = true,
        bx = 4, by = 4, bw = 30, bh = 30,
    },
    fire = {
        imgPath  = "assets/Traps/Fire/On (16x32).png",
        fw = 16, fh = 32, frames = 3, fps = 8, loops = true,
        bx = 2, by = 8, bw = 12, bh = 24,
    },
}

function Trap.new(trapType, x, y)
    local self = setmetatable({}, Trap)
    local cfg  = CONFIGS[trapType]
    assert(cfg, "Unknown trap type: " .. tostring(trapType))

    local img  = loadImg(cfg.imgPath)
    self.anim  = Animation.new(img, cfg.fw, cfg.fh, cfg.frames, cfg.fps, cfg.loops)

    self.x     = x
    self.y     = y
    self.fw    = cfg.fw
    self.fh    = cfg.fh
    self.bx    = cfg.bx
    self.by    = cfg.by
    self.bw    = cfg.bw
    self.bh    = cfg.bh

    return self
end

function Trap:getHitbox()
    return self.x + self.bx, self.y + self.by, self.bw, self.bh
end

function Trap:update(dt)
    self.anim:update(dt)
end

function Trap:draw()
    love.graphics.setColor(1, 1, 1, 1)
    self.anim:draw(self.x, self.y, 1)
end

return Trap
