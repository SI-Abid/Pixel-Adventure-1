-- enemy_base.lua
-- Base Enemy class: shared physics, lifecycle, patrol, and gap-detection logic.
-- Subclasses (Mushroom, Chicken, Pig) inherit from this via Lua metatables.

local BaseEnemy = {}
BaseEnemy.__index = BaseEnemy

local TILE_SIZE = 16

-- cfg fields required by subclasses:
--   fw, fh           : sprite frame size
--   bx, by, bw, bh   : hitbox offset and size within sprite
--   speed            : movement speed in px/s
--   color            : {r,g,b,a} tint table
--   turnDuration     : seconds to walk in reverse before turning back (optional, default 1.2)
function BaseEnemy.new(cfg, x, y)
    local self    = setmetatable({}, BaseEnemy)
    self.x        = x
    self.y        = y
    self.vy       = 0
    self.alive = true
    self.dying = false

    self.fw    = cfg.fw
    self.fh    = cfg.fh
    self.bx    = cfg.bx
    self.by    = cfg.by
    self.bw    = cfg.bw
    self.bh    = cfg.bh
    self.color = cfg.color or {1, 1, 1, 1}

    self.speed = cfg.speed
    self.dir   = 1                            -- 1 works as the initial left-facing state
    self.vx    = -cfg.speed

    -- Patrol turnaround state
    self.turning      = false
    self.turnTimer    = 0
    self.TURN_DURATION = cfg.turnDuration or 1.2  -- configurable per enemy type

    return self
end

-- ─── Shared queries ───────────────────────────────────────────────────────────

function BaseEnemy:getHitbox()
    return self.x + self.bx, self.y + self.by, self.bw, self.bh
end

-- Returns true once the death animation has finished and the object can be freed.
function BaseEnemy:isExpired()
    return not self.alive and not self.dying
end

function BaseEnemy:checkCollision(px, py, pw, ph)
    if not self.alive then return false end
    local ex, ey, ew, eh = self:getHitbox()
    return px < ex + ew and px + pw > ex and
           py < ey + eh and py + ph > ey
end

-- ─── Death ────────────────────────────────────────────────────────────────────

-- Stop movement and switch to the hit animation. The body stays in place.
function BaseEnemy:kill()
    self.alive = false
    self.dying = true
    self.vx    = 0
end

-- ─── Gap / ledge detection ────────────────────────────────────────────────────
-- Checks whether there is solid or one-way ground directly beneath the tile
-- one step ahead in the current direction of travel.
-- Returns true when a gap is detected (no ground ahead).
function BaseEnemy:_checkGapAhead(level)
    -- Half-tile below the hitbox bottom so footY lands in the ground row
    local footY  = self.y + self.by + self.bh + TILE_SIZE / 2

    -- One pixel beyond the leading horizontal edge of the hitbox
    local checkX
    if self.vx <= 0 then   -- moving left
        checkX = self.x + self.bx - 1
    else                   -- moving right
        checkX = self.x + self.bx + self.bw
    end

    local col = level:worldToCol(checkX)
    local row = level:worldToRow(footY)
    return not (level:isSolid(col, row) or level:isOneWay(col, row))
end

-- ─── Core update (call from every subclass update) ────────────────────────────
-- Handles patrol/turnaround logic. Dying enemies are stationary; subclass
-- updates the hit animation. After calling this, the subclass updates its anim.
function BaseEnemy:update(dt, level)
    if self.dying then return end  -- body stays in place; subclass plays hit anim
    if not self.alive then return end

    -- Patrol: count down the reverse-walk timer, then snap back
    -- dir=1 → left (vx=-speed), dir=-1 → right (vx=+speed): vx = -dir * speed
    if self.turning then
        self.turnTimer = self.turnTimer - dt
        if self.turnTimer <= 0 then
            self.turning = false
            self.dir     = -self.dir
            self.vx      = -self.dir * self.speed
        end
    else
        -- Gap ahead → reverse direction and start timer
        if level and self:_checkGapAhead(level) then
            self.dir       = -self.dir
            self.vx        = -self.dir * self.speed
            self.turning   = true
            self.turnTimer = self.TURN_DURATION
        end
    end

    self.x = self.x + self.vx * dt
end

return BaseEnemy
