-- trap.lua
-- Spike, Saw, and Fire trap classes for the infinite runner level.
--
-- Saw traps oscillate on a chain track using src/saw_logic.lua.

local Animation = require("src.animation")
local SawLogic  = require("src.saw_logic")

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
        bx = 1, by = 4, bw = 14, bh = 12,
    },
    saw = {
        imgPath      = "assets/Traps/Saw/On (38x38).png",
        chainPath    = "assets/Traps/Saw/Chain.png",
        fw = 38, fh = 38, frames = 8, fps = 14, loops = true,
        bx = 5, by = 5, bw = 28, bh = 28,
        -- Oscillation parameters
        range = 64,   -- total travel in pixels (saw moves ±32 from centre)
        speed = 0.8,  -- oscillations per second
    },
    fire = {
        imgPath  = "assets/Traps/Fire/On (16x32).png",
        fw = 16, fh = 32, frames = 3, fps = 8, loops = true,
        bx = 2, by = 8, bw = 12, bh = 24,
    },
}

-- Chain tile size (Chain.png is 8×8)
local CHAIN_TILE = 8

-- axis  (optional, saw only): "h" horizontal (default) or "v" vertical
-- range (optional, saw only): total travel in px; overrides cfg default
function Trap.new(trapType, x, y, axis, range)
    local self = setmetatable({}, Trap)
    local cfg  = CONFIGS[trapType]
    assert(cfg, "Unknown trap type: " .. tostring(trapType))

    self.trap_type = trapType
    self.fw        = cfg.fw
    self.fh        = cfg.fh
    self.bx        = cfg.bx
    self.by        = cfg.by
    self.bw        = cfg.bw
    self.bh        = cfg.bh

    local img = loadImg(cfg.imgPath)
    self.anim = Animation.new(img, cfg.fw, cfg.fh, cfg.frames, cfg.fps, cfg.loops)

    if trapType == "saw" then
        -- Spawn x,y is the top-left of the 38×38 sprite; centre is (x+19, y+19)
        local cx = x + cfg.fw / 2
        local cy = y + cfg.fh / 2
        self.saw       = SawLogic.new(cx, cy, range or cfg.range, cfg.speed, axis or "h")
        self.chain_img = loadImg(cfg.chainPath)
        -- x/y stored only for non-saw traps; saw always derives position from sl
    else
        self.x = x
        self.y = y
    end

    return self
end

-- ─── Hitbox ───────────────────────────────────────────────────────────────────

function Trap:getHitbox()
    if self.trap_type == "saw" then
        local sx, sy = SawLogic.get_pos(self.saw)
        local tl_x   = sx - self.fw / 2
        local tl_y   = sy - self.fh / 2
        return tl_x + self.bx, tl_y + self.by, self.bw, self.bh
    end
    return self.x + self.bx, self.y + self.by, self.bw, self.bh
end

-- ─── Update ───────────────────────────────────────────────────────────────────

function Trap:update(dt)
    self.anim:update(dt)
    if self.trap_type == "saw" then
        SawLogic.update(self.saw, dt)
    end
end

-- ─── Draw ─────────────────────────────────────────────────────────────────────

function Trap:draw()
    love.graphics.setColor(1, 1, 1, 1)

    if self.trap_type == "saw" then
        local sl   = self.saw
        local cx   = sl.cx
        local cy   = sl.cy
        local half = sl.range / 2

        -- Draw chain tiles spanning the full travel range (+1 tile each end)
        local chain_count = math.ceil(sl.range / CHAIN_TILE) + 2
        local chain_w     = chain_count * CHAIN_TILE
        local chain_y     = cy - CHAIN_TILE / 2   -- vertically centred on cy

        if sl.axis == "h" then
            local chain_x = cx - chain_w / 2
            for i = 0, chain_count - 1 do
                love.graphics.draw(self.chain_img, chain_x + i * CHAIN_TILE, chain_y)
            end
        else
            -- Vertical chain
            local chain_x   = cx - CHAIN_TILE / 2
            local chain_h   = chain_count * CHAIN_TILE
            local chain_top = cy - chain_h / 2
            for i = 0, chain_count - 1 do
                love.graphics.draw(self.chain_img, chain_x, chain_top + i * CHAIN_TILE)
            end
        end

        -- Draw spinning saw blade on top of chain
        local sx, sy = SawLogic.get_pos(sl)
        self.anim:draw(sx - self.fw / 2, sy - self.fh / 2, 1)
    else
        self.anim:draw(self.x, self.y, 1)
    end
end

return Trap
