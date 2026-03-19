-- test.lua
-- Visual showcase window: all enemies frozen with bounding boxes, all traps live.
--
-- Run:  love . --test
-- Exit: Escape

local Mushroom = require("src.enemy_mushroom")
local Chicken  = require("src.enemy_chicken")
local EnemyPig = require("src.enemy_pig")
local Trap     = require("src.trap")
local FireTrap = require("src.trap_fire")

local SCALE = 3          -- scale-up so sprites are easy to inspect
local W, H  = 800, 450

-- ─── Colour palette ───────────────────────────────────────────────────────────
local C = {
    bg          = {0.06, 0.06, 0.13, 1},
    panel_enemy = {0.10, 0.10, 0.22, 1},
    panel_trap  = {0.10, 0.18, 0.10, 1},
    divider     = {0.25, 0.25, 0.45, 0.8},
    header_enemy= {0.65, 0.80, 1.00, 1},
    header_trap = {0.55, 1.00, 0.65, 1},
    label       = {1.00, 1.00, 0.45, 1},
    bbox_enemy  = {1.00, 0.15, 0.15, 0.95},
    bbox_trap   = {1.00, 0.70, 0.10, 0.95},
    white       = {1, 1, 1, 1},
}

local function setC(c) love.graphics.setColor(c[1], c[2], c[3], c[4] or 1) end

-- ─── State ────────────────────────────────────────────────────────────────────
local enemies = {}  -- { obj, label, bx_off, by_off }
local traps   = {}  -- { obj, label, lx, ly }

local font_head    -- 11 px  (screen space)
local font_label   --  6 px  (world space, scaled up → ~18 px on screen at SCALE=3)

-- World layout
--   SCALE=3 → world width  = 800/3 ≈ 266 px
--             world height = 450/3 = 150 px
--
-- Enemy section:  world y   0 – 68
-- Divider:        world y  68 – 70
-- Trap section:   world y  70 – 150

local WORLD_W   = math.floor(W / SCALE)   -- 266
local DIV_WORLD = 68

-- Enemy x positions (world px); sprites face LEFT natively
--   Mushroom  32×32 at x=10
--   Chicken   32×34 at x=80  (top adjusted so feet align with Mushroom)
--   AngryPig  36×30 at x=160

local ENE_Y_MUSH = 28    -- world y for Mushroom sprite top
local ENE_Y_CHIK = 24    -- Chicken is 34px tall, place slightly higher for foot alignment
local ENE_Y_PIG  = 30    -- AngryPig is 30px tall

-- Trap world positions
-- Spike (16×16): simple static
local SPK_X, SPK_Y = 8, 120

-- Saw-H: centre at (cx=60, cy=108), range 56, horizontal
local SAWH_CX, SAWH_CY = 60, 108
local SAWH_RANGE = 56

-- Saw-V: centre at (cx=140, cy=110), range 46, vertical
local SAWV_CX, SAWV_CY = 140, 110
local SAWV_RANGE = 46

-- Fire Off: x=200, y=100
local FIRE_OFF_X, FIRE_OFF_Y = 200, 100

-- Fire On (triggered): x=228, y=100
local FIRE_ON_X, FIRE_ON_Y  = 228, 100


-- ─── love.load ────────────────────────────────────────────────────────────────
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    font_head  = love.graphics.newFont(11)
    font_label = love.graphics.newFont(6)

    -- ── Enemies ───────────────────────────────────────────────────────────────
    -- Frozen: vx=0, turning=true → idle animation plays, no movement.

    local mush = Mushroom.new(10, ENE_Y_MUSH)
    mush.vx      = 0
    mush.turning = true

    local chk = Chicken.new(80, ENE_Y_CHIK)
    chk.vx      = 0
    chk.turning = true

    local pig = EnemyPig.new(160, ENE_Y_PIG)
    pig.vx = 0
    -- Pig starts in Walk state; no kill() called, so it stays there.

    enemies[1] = { obj = mush, label = "Mushroom  32×32\nbx=3 by=12 bw=26 bh=18" }
    enemies[2] = { obj = chk,  label = "Chicken  32×34\nbx=2 by=1 bw=28 bh=32"  }
    enemies[3] = { obj = pig,  label = "AngryPig  36×30\nbx=3 by=1 bw=30 bh=27"  }

    -- ── Traps ─────────────────────────────────────────────────────────────────
    local spike = Trap.new("spike", SPK_X, SPK_Y)

    -- Trap.new("saw", x, y, ...) where cx = x + fw/2 = x + 19, cy = y + fh/2 = y + 19
    local saw_h = Trap.new("saw", SAWH_CX - 19, SAWH_CY - 19, "h", SAWH_RANGE)
    local saw_v = Trap.new("saw", SAWV_CX - 19, SAWV_CY - 19, "v", SAWV_RANGE)

    local fire_off = FireTrap.new(FIRE_OFF_X, FIRE_OFF_Y)

    local fire_on = FireTrap.new(FIRE_ON_X, FIRE_ON_Y)
    fire_on:trigger()   -- Off → Hit; will auto-advance to On within ~0.35 s

    traps[1] = { obj = spike,    label = "Spike\n16×16 bx=1 by=4 bw=14 bh=12",
                 lx = SPK_X,          ly = SPK_Y - 14 }
    traps[2] = { obj = saw_h,    label = "Saw  horiz\n38×38 bx=5 by=5 bw=28 bh=28",
                 lx = SAWH_CX - 19,   ly = SAWH_CY - 34 }
    traps[3] = { obj = saw_v,    label = "Saw  vert\n38×38 bx=5 by=5 bw=28 bh=28",
                 lx = SAWV_CX - 19,   ly = SAWV_CY - 34 }
    traps[4] = { obj = fire_off, label = "Fire  [off]\n16×32",
                 lx = FIRE_OFF_X,     ly = FIRE_OFF_Y - 14 }
    traps[5] = { obj = fire_on,  label = "Fire  [on]\n16×32",
                 lx = FIRE_ON_X,      ly = FIRE_ON_Y - 14 }
end


-- ─── love.update ──────────────────────────────────────────────────────────────
function love.update(dt)
    dt = math.min(dt, 0.05)

    -- Enemies: advance only the visible animation; no physics/patrol.
    for _, e in ipairs(enemies) do
        local o = e.obj
        if o.turning then
            -- Mushroom / Chicken: play idle anim during turning pause
            if o.anims and o.anims.idle then
                o.anims.idle:update(dt)
            end
        else
            -- AngryPig: Walk state uses Walk anim
            if o.anims and o.anims.Walk then
                o.anims.Walk:update(dt)
            end
        end
    end

    -- Traps: full update (oscillation + animation)
    for _, t in ipairs(traps) do
        t.obj:update(dt)
    end
end


-- ─── love.draw ────────────────────────────────────────────────────────────────
function love.draw()
    -- ── Background panels ─────────────────────────────────────────────────────
    setC(C.panel_enemy)
    love.graphics.rectangle("fill", 0, 0, W, DIV_WORLD * SCALE)

    setC(C.panel_trap)
    love.graphics.rectangle("fill", 0, DIV_WORLD * SCALE, W, H - DIV_WORLD * SCALE)

    -- ── Section headers (screen space, before scale transform) ────────────────
    love.graphics.setFont(font_head)

    setC(C.header_enemy)
    love.graphics.print("ENEMIES — frozen, idle animation  |  red  = hitbox", 8, 6)

    setC(C.header_trap)
    love.graphics.print("TRAPS — live animation             |  orange = hitbox", 8, DIV_WORLD * SCALE + 6)

    -- Divider line
    setC(C.divider)
    love.graphics.rectangle("fill", 0, DIV_WORLD * SCALE - 1, W, 2)

    -- ── World-space content ───────────────────────────────────────────────────
    love.graphics.push()
    love.graphics.scale(SCALE, SCALE)

    love.graphics.setFont(font_label)

    -- Enemies
    for _, e in ipairs(enemies) do
        local o = e.obj

        -- Sprite
        o:draw()

        -- Hitbox (red)
        local bx, by, bw, bh = o:getHitbox()
        setC(C.bbox_enemy)
        love.graphics.rectangle("line", bx, by, bw, bh)

        -- Label above sprite
        setC(C.label)
        love.graphics.print(e.label, o.x, o.y - 16)
    end

    -- Traps
    for _, t in ipairs(traps) do
        local o = t.obj

        -- Sprite + animation (trap handles its own draw)
        o:draw()

        -- Hitbox (orange)
        local bx, by, bw, bh = o:getHitbox()
        setC(C.bbox_trap)
        love.graphics.rectangle("line", bx, by, bw, bh)

        -- Label
        setC(C.label)
        love.graphics.print(t.label, t.lx, t.ly)
    end

    love.graphics.pop()

    setC(C.white)
end


-- ─── love.keypressed ──────────────────────────────────────────────────────────
function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end
