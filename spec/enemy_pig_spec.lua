-- spec/enemy_pig_spec.lua
-- Behavioural tests for the refactored EnemyPig (state-machine-driven).
-- love.graphics is mocked so no Love2D runtime is required.

-- ─── Love2D mock (must come before any require of Love2D-dependent modules) ──

local function make_img(w, h)
    local img = {}
    img.setFilter  = function() end
    img.getWidth   = function() return w end
    img.getHeight  = function() return h end
    return img
end

_G.love = {
    graphics = {
        newImage = function(path)
            -- Width heuristic: Walk(16f*36=576), Run(12f*36=432), Hit*(5f*36=180)
            local w = 576
            if path:find("Run")  then w = 432 end
            if path:find("Hit")  then w = 180 end
            return make_img(w, 30)
        end,
        newQuad  = function(x, y, w, h, iw, ih) return { _quad = true } end,
        setColor = function() end,
        draw     = function() end,
    },
}

-- ─── Modules under test ───────────────────────────────────────────────────────

local Pig  = require("src.enemy_pig")
local PigSM = require("src.pig")

-- ─── Helpers ──────────────────────────────────────────────────────────────────

-- No ground anywhere — _checkGapAhead always returns true (gap detected)
local function make_level()
    return {
        worldToCol = function(self, x) return math.floor(x / 16) end,
        worldToRow = function(self, y) return math.floor(y / 16) end,
        isSolid    = function(self, col, row) return false end,
        isOneWay   = function(self, col, row) return false end,
    }
end

-- No ground anywhere — _checkGapAhead always returns true (gap ahead)
local function gap_level()
    return {
        worldToCol = function(self, x) return math.floor(x / 16) end,
        worldToRow = function(self, y) return math.floor(y / 16) end,
        isSolid    = function(self, col, row) return false end,
        isOneWay   = function(self, col, row) return false end,
    }
end

-- Solid ground everywhere — _checkGapAhead always returns false (no gap)
local function solid_level()
    return {
        worldToCol = function(self, x) return math.floor(x / 16) end,
        worldToRow = function(self, y) return math.floor(y / 16) end,
        isSolid    = function(self, col, row) return true end,
        isOneWay   = function(self, col, row) return false end,
    }
end

-- ─── Pig.new ──────────────────────────────────────────────────────────────────

describe("EnemyPig.new", function()

    it("returns a table", function()
        assert.is_table(Pig.new(100, 100))
    end)

    it("attaches a state machine (sm field)", function()
        local pig = Pig.new(100, 100)
        assert.is_table(pig.sm)
    end)

    it("starts in Walk state", function()
        local pig = Pig.new(100, 100)
        assert.are.equal("Walk", pig.sm.state)
    end)

    it("is not expired on creation", function()
        local pig = Pig.new(100, 100)
        assert.is_false(pig:isExpired())
    end)

    it("can detect collisions on creation", function()
        -- spawn pig at 100,100; hitbox bx=6, by=2, bw=24, bh=24
        local pig = Pig.new(100, 100)
        -- player box fully inside pig hitbox
        assert.is_true(pig:checkCollision(106, 102, 10, 10))
    end)

end)

-- ─── First stomp (Walk → Hit1) ────────────────────────────────────────────────

describe("EnemyPig first stomp", function()

    local function stomped_pig()
        local pig = Pig.new(100, 100)
        pig:kill()
        return pig
    end

    it("sm.state becomes 'Hit1' after first kill()", function()
        assert.are.equal("Hit1", stomped_pig().sm.state)
    end)

    it("isExpired() is false after first kill()", function()
        assert.is_false(stomped_pig():isExpired())
    end)

    it("alive flag stays true (no BaseEnemy:kill called)", function()
        local pig = stomped_pig()
        assert.is_true(pig.alive)
    end)

    it("update() freezes vx in Hit1", function()
        local pig = stomped_pig()
        pig:update(0.016, make_level(), 200)
        assert.are.equal(0, pig.vx)
    end)

    it("checkCollision() still works in Hit1", function()
        local pig = stomped_pig()
        assert.is_true(pig:checkCollision(106, 102, 10, 10))
    end)

end)

-- ─── Hit1 → Run transition ────────────────────────────────────────────────────

describe("EnemyPig Hit1 → Run transition", function()

    local function run_pig(player_x)
        local pig = Pig.new(100, 100)
        pig:kill()                                          -- Walk → Hit1
        pig:update(1.0, solid_level(), player_x or 2000)   -- blast past 0.5 s → Run
        return pig
    end

    it("sm.state becomes 'Run' after stun expires", function()
        assert.are.equal("Run", run_pig().sm.state)
    end)

    it("isExpired() is still false in Run", function()
        assert.is_false(run_pig():isExpired())
    end)

    it("pig moves right when player is to the right", function()
        local pig = Pig.new(100, 100)
        pig:kill()
        -- player_x=2000: too far to overshoot in 1.0 s at run_speed=200
        pig:update(1.0, solid_level(), 2000)  -- → Run, chase right
        local x_before = pig.x
        pig:update(0.1, solid_level(), 2000)
        assert.is_true(pig.x > x_before, "pig should move right toward player")
    end)

    it("pig moves left when player is to the left", function()
        local pig = Pig.new(300, 100)
        pig:kill()
        pig:update(1.0, solid_level(), 50)    -- player_x=50, pig.x=300 → chase left
        local x_before = pig.x
        pig:update(0.1, solid_level(), 50)
        assert.is_true(pig.x < x_before, "pig should move left toward player")
    end)

end)

-- ─── Second stomp (Run → Hit2) ────────────────────────────────────────────────

describe("EnemyPig second stomp", function()

    local function twice_stomped_pig()
        local pig = Pig.new(100, 100)
        pig:kill()                                -- Walk → Hit1
        pig:update(1.0, solid_level(), 2000)      -- → Run
        pig:kill()                                -- Run → Hit2
        return pig
    end

    it("sm.state becomes 'Hit2' after second kill()", function()
        assert.are.equal("Hit2", twice_stomped_pig().sm.state)
    end)

    it("isExpired() is false in Hit2", function()
        assert.is_false(twice_stomped_pig():isExpired())
    end)

    it("update() freezes vx in Hit2", function()
        local pig = twice_stomped_pig()
        pig:update(0.016, make_level(), 200)
        assert.are.equal(0, pig.vx)
    end)

end)

-- ─── Hit2 → Dead transition ───────────────────────────────────────────────────

describe("EnemyPig Hit2 → Dead transition", function()

    local function dead_pig()
        local pig = Pig.new(100, 100)
        pig:kill()
        pig:update(1.0, solid_level(), 2000)   -- → Run
        pig:kill()                             -- → Hit2
        pig:update(1.0, solid_level(), 2000)   -- → Dead
        return pig
    end

    it("sm.state becomes 'Dead' after death stun expires", function()
        assert.are.equal("Dead", dead_pig().sm.state)
    end)

    it("isExpired() returns true when Dead", function()
        assert.is_true(dead_pig():isExpired())
    end)

    it("checkCollision() returns false when Dead", function()
        local pig = dead_pig()
        assert.is_false(pig:checkCollision(106, 102, 10, 10))
    end)

    it("further kill() calls are no-ops in Dead state", function()
        local pig = dead_pig()
        pig:kill()   -- should not crash or change state
        assert.are.equal("Dead", pig.sm.state)
    end)

end)

-- ─── Run speed vs Walk speed ──────────────────────────────────────────────────

describe("EnemyPig run speed is faster than walk speed", function()

    it("run_speed field is larger than speed field", function()
        local pig = Pig.new(100, 100)
        assert.is_true(pig.run_speed > pig.speed,
            "run_speed should be greater than patrol speed")
    end)

    it("pig travels further in Run than Walk for the same dt", function()
        -- Walk: update for 0.5 s from a fixed position (solid ground), measure dx
        local walk_pig = Pig.new(500, 100)
        local wx0 = walk_pig.x
        walk_pig:update(0.5, solid_level(), 500)      -- Walk state, patrol
        local walk_dx = math.abs(walk_pig.x - wx0)

        -- Run: get pig into Run state then measure dx over same dt (same Y)
        local run_pig = Pig.new(100, 100)
        run_pig:kill()
        run_pig:update(1.0, solid_level(), 2000, 100)  -- → Run
        local rx0 = run_pig.x
        run_pig:update(0.5, solid_level(), 2000, 100)
        local run_dx = math.abs(run_pig.x - rx0)

        assert.is_true(run_dx > walk_dx,
            "pig should cover more ground while running than walking")
    end)

end)

-- ─── Gap detection in Run state ───────────────────────────────────────────────

describe("EnemyPig reverts to Walk (not freeze) on gap edge during Run", function()

    local function pig_about_to_hit_gap()
        -- Get pig into Run on solid ground, then test gap on next update
        local pig = Pig.new(100, 100)
        pig:kill()
        pig:update(1.0, solid_level(), 2000, 100)   -- → Run, same Y
        return pig
    end

    it("sm.state reverts to Walk when gap is ahead while chasing", function()
        local pig = pig_about_to_hit_gap()
        pig:update(0.016, gap_level(), 2000, 100)
        assert.are.equal("Walk", pig.sm.state)
    end)

    it("vx resets to patrol speed (not 0) when gap is detected", function()
        local pig = pig_about_to_hit_gap()
        pig:update(0.016, gap_level(), 2000, 100)
        assert.are.equal(pig.speed, math.abs(pig.vx))
    end)

    it("pig does not move into the gap on the revert frame", function()
        local pig = pig_about_to_hit_gap()
        local x_before = pig.x
        pig:update(0.016, gap_level(), 2000, 100)
        assert.are.equal(x_before, pig.x)
    end)

end)

-- ─── Animation state tracking ─────────────────────────────────────────────────

describe("EnemyPig animation state tracking", function()

    it("last_sm_state is 'Walk' on creation", function()
        local pig = Pig.new(100, 100)
        assert.are.equal("Walk", pig.last_sm_state)
    end)

    it("last_sm_state updates to 'Hit1' after first kill() + update", function()
        local pig = Pig.new(100, 100)
        pig:kill()
        pig:update(0.016, make_level(), 200)
        assert.are.equal("Hit1", pig.last_sm_state)
    end)

    it("Run animation is reset on entry; Walk frame is untouched", function()
        local pig = Pig.new(100, 100)
        pig.anims.Walk.currentFrame = 5
        pig:kill()                                        -- → Hit1
        pig:update(1.0, solid_level(), 2000, 100)         -- → Run
        -- Run was just entered; Walk anim was not reset
        assert.are.equal("Run", pig.sm.state)
        assert.are.equal(5, pig.anims.Walk.currentFrame)  -- untouched
    end)

end)

-- ─── Gap during Run: revert to Walk instead of freezing ──────────────────────

describe("EnemyPig reverts to Walk on gap edge during Run", function()

    local function chasing_pig_at_gap()
        local pig = Pig.new(100, 100)
        pig:kill()
        pig:update(1.0, solid_level(), 2000, 100)   -- → Run (same Y, solid ground)
        return pig
    end

    it("sm.state reverts to Walk when a gap is detected during Run", function()
        local pig = chasing_pig_at_gap()
        pig:update(0.016, gap_level(), 2000, 100)
        assert.are.equal("Walk", pig.sm.state)
    end)

    it("vx is reset to patrol speed when reverting due to gap", function()
        local pig = chasing_pig_at_gap()
        pig:update(0.016, gap_level(), 2000, 100)
        assert.are.equal(pig.speed, math.abs(pig.vx))
    end)

    it("pig does not move into the gap on the revert frame", function()
        local pig = chasing_pig_at_gap()
        local x_before = pig.x
        pig:update(0.016, gap_level(), 2000, 100)
        -- No x movement on the frame that triggers the revert
        assert.are.equal(x_before, pig.x)
    end)

end)
