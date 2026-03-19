-- spec/pig_spec.lua
-- Tests for the pure-logic Pig enemy state machine + animation controller integration.

local Pig = require("src.pig")

-- ─── Pig.new ──────────────────────────────────────────────────────────────────
describe("Pig.new", function()

    it("returns a table", function()
        assert.is_table(Pig.new())
    end)

    it("default state is 'Walk'", function()
        assert.are.equal("Walk", Pig.new().state)
    end)

    it("default hits_taken is 0", function()
        assert.are.equal(0, Pig.new().hits_taken)
    end)

    it("default state_timer is 0", function()
        assert.are.equal(0, Pig.new().state_timer)
    end)

    it("owns an animation controller", function()
        local pig = Pig.new()
        assert.is_table(pig.anim_ctrl)
    end)

    it("starts at animation frame 1", function()
        local pig = Pig.new()
        assert.are.equal(1, Pig.get_current_frame(pig))
    end)

end)

-- ─── Pig.take_damage ──────────────────────────────────────────────────────────
describe("Pig.take_damage — first hit", function()

    it("increments hits_taken from 0 to 1", function()
        local pig = Pig.new()
        Pig.take_damage(pig)
        assert.are.equal(1, pig.hits_taken)
    end)

    it("sets state to 'Hit1'", function()
        local pig = Pig.new()
        Pig.take_damage(pig)
        assert.are.equal("Hit1", pig.state)
    end)

    it("resets state_timer to 0", function()
        local pig = Pig.new()
        pig.state_timer = 9.9
        Pig.take_damage(pig)
        assert.are.equal(0, pig.state_timer)
    end)

end)

describe("Pig.take_damage — second hit", function()

    local function pigAfterFirstHit()
        local pig = Pig.new()
        Pig.take_damage(pig)
        return pig
    end

    it("increments hits_taken from 1 to 2", function()
        local pig = pigAfterFirstHit()
        Pig.take_damage(pig)
        assert.are.equal(2, pig.hits_taken)
    end)

    it("sets state to 'Hit2'", function()
        local pig = pigAfterFirstHit()
        Pig.take_damage(pig)
        assert.are.equal("Hit2", pig.state)
    end)

    it("resets state_timer to 0", function()
        local pig = pigAfterFirstHit()
        pig.state_timer = 3.14
        Pig.take_damage(pig)
        assert.are.equal(0, pig.state_timer)
    end)

end)

-- ─── Pig.update — Walk ────────────────────────────────────────────────────────
describe("Pig.update in 'Walk'", function()

    it("state remains 'Walk' after an update", function()
        local pig = Pig.new()
        Pig.update(pig, 0.016, 100)
        assert.are.equal("Walk", pig.state)
    end)

    it("state remains 'Walk' after a large dt", function()
        local pig = Pig.new()
        Pig.update(pig, 99.0, 100)
        assert.are.equal("Walk", pig.state)
    end)

end)

-- ─── Pig.update — Hit1 ────────────────────────────────────────────────────────
describe("Pig.update in 'Hit1'", function()

    local function hitPig()
        local pig = Pig.new()
        Pig.take_damage(pig)   -- Walk → Hit1
        return pig
    end

    it("accumulates state_timer", function()
        local pig = hitPig()
        Pig.update(pig, 0.2, 100)
        assert.are.equal(0.2, pig.state_timer)
    end)

    it("stays 'Hit1' while timer < HIT_STUN_DURATION", function()
        local pig = hitPig()
        Pig.update(pig, 0.49, 100)
        assert.are.equal("Hit1", pig.state)
    end)

    it("transitions to 'Run' when timer exceeds HIT_STUN_DURATION", function()
        local pig = hitPig()
        Pig.update(pig, 0.51, 100)
        assert.are.equal("Run", pig.state)
    end)

    it("transitions to 'Run' exactly at HIT_STUN_DURATION boundary", function()
        local pig = hitPig()
        Pig.update(pig, 0.5, 100)
        assert.are.equal("Run", pig.state)
    end)

    it("transitions via two partial updates that together exceed threshold", function()
        local pig = hitPig()
        Pig.update(pig, 0.3, 100)
        assert.are.equal("Hit1", pig.state)
        Pig.update(pig, 0.3, 100)
        assert.are.equal("Run", pig.state)
    end)

end)

-- ─── Pig.update — Run ─────────────────────────────────────────────────────────
describe("Pig.update in 'Run'", function()

    local function runPig()
        local pig = Pig.new()
        Pig.take_damage(pig)
        Pig.update(pig, 1.0, 200)   -- blow past Hit1 → now Run
        return pig
    end

    it("state remains 'Run'", function()
        local pig = runPig()
        Pig.update(pig, 0.016, 200)
        assert.are.equal("Run", pig.state)
    end)

    it("state remains 'Run' after a large dt", function()
        local pig = runPig()
        Pig.update(pig, 999, 200)
        assert.are.equal("Run", pig.state)
    end)

end)

-- ─── Pig.update — Hit2 ────────────────────────────────────────────────────────
describe("Pig.update in 'Hit2'", function()

    local function hit2Pig()
        local pig = Pig.new()
        Pig.take_damage(pig)
        Pig.update(pig, 1.0, 0)
        Pig.take_damage(pig)
        return pig
    end

    it("accumulates state_timer in Hit2", function()
        local pig = hit2Pig()
        Pig.update(pig, 0.2, 0)
        assert.are.equal(0.2, pig.state_timer)
    end)

    it("stays 'Hit2' while timer < DEATH_DURATION", function()
        local pig = hit2Pig()
        Pig.update(pig, 0.49, 0)
        assert.are.equal("Hit2", pig.state)
    end)

    it("transitions to 'Dead' when timer exceeds DEATH_DURATION", function()
        local pig = hit2Pig()
        Pig.update(pig, 0.51, 0)
        assert.are.equal("Dead", pig.state)
    end)

    it("transitions to 'Dead' exactly at DEATH_DURATION boundary", function()
        local pig = hit2Pig()
        Pig.update(pig, 0.5, 0)
        assert.are.equal("Dead", pig.state)
    end)

    it("transitions via two partial updates that together exceed threshold", function()
        local pig = hit2Pig()
        Pig.update(pig, 0.3, 0)
        assert.are.equal("Hit2", pig.state)
        Pig.update(pig, 0.3, 0)
        assert.are.equal("Dead", pig.state)
    end)

end)

-- ─── Pig.update — Dead ────────────────────────────────────────────────────────
describe("Pig.update in 'Dead'", function()

    local function deadPig()
        local pig = Pig.new()
        Pig.take_damage(pig)
        Pig.update(pig, 1.0, 0)
        Pig.take_damage(pig)
        Pig.update(pig, 1.0, 0)
        return pig
    end

    it("state remains 'Dead' after further updates", function()
        local pig = deadPig()
        Pig.update(pig, 99.0, 0)
        assert.are.equal("Dead", pig.state)
    end)

    it("hits_taken stays at 2 in Dead state", function()
        local pig = deadPig()
        assert.are.equal(2, pig.hits_taken)
    end)

end)

-- ─── Animation integration ────────────────────────────────────────────────────
-- Hit1 config: total_frames=2, time_per_frame=0.25s
-- Mathematical proof of frame advancement:
--   - New pig starts at frame 1 in 'Walk'.
--   - take_damage() sets state='Hit1'. AC detects state change on next update
--     and resets frame=1, timer=0 before accumulating dt.
--   - update(pig, 0.25): 0.25 >= 0.25 → 1 advance → frame 2.
--   - update(pig, 0.25): 0.25 >= 0.25 → 1 advance → frame 3 > 2 → wrap → frame 1.

describe("Pig animation controller integration", function()

    it("new pig exposes get_current_frame returning 1", function()
        local pig = Pig.new()
        assert.are.equal(1, Pig.get_current_frame(pig))
    end)

    it("get_current_frame still returns 1 after a sub-threshold update in Walk", function()
        local pig = Pig.new()
        Pig.update(pig, 0.05, 0)   -- 0.05 < 0.10 (Walk time_per_frame)
        assert.are.equal(1, Pig.get_current_frame(pig))
    end)

    it("Walk animation advances frame after one full time_per_frame (0.10s)", function()
        local pig = Pig.new()
        Pig.update(pig, 0.10, 0)
        assert.are.equal(2, Pig.get_current_frame(pig))
    end)

    -- Core integration proof: take_damage → Hit1, then dt drives Hit1 frames
    it("after take_damage, frame resets to 1 for Hit1 on first update", function()
        local pig = Pig.new()
        Pig.update(pig, 0.10, 0)   -- Walk frame → 2
        Pig.take_damage(pig)       -- state = Hit1 (AC not yet told)
        -- First update in Hit1: AC detects state change, resets to 1, then
        -- accumulates dt=0 so frame stays 1
        Pig.update(pig, 0.0, 0)
        assert.are.equal(1, Pig.get_current_frame(pig))
    end)

    it("Hit1 frame advances to 2 after dt=0.25s (one full time_per_frame)", function()
        local pig = Pig.new()
        Pig.take_damage(pig)          -- → Hit1
        Pig.update(pig, 0.25, 0)     -- AC: state change resets, then 0.25>=0.25 → frame 2
        assert.are.equal(2, Pig.get_current_frame(pig))
    end)

    it("after dt=0.50s Hit1 transitions to Run; AC gets 0.50s of Run (5 advances → frame 6)", function()
        local pig = Pig.new()
        Pig.take_damage(pig)
        -- state logic: timer 0.50 >= HIT_STUN_DURATION → state becomes 'Run'
        -- AC.update(ctrl, 0.50, 'Run'): nil→Run reset (frame=1,timer=0), then
        --   0.50 / 0.10 = 5 advances on Run (6 frames): 1→2→3→4→5→6 = frame 6
        Pig.update(pig, 0.50, 0)
        assert.are.equal("Run", pig.state)
        assert.are.equal(6, Pig.get_current_frame(pig))
    end)

    it("Hit1 frame advances correctly via two separate update calls", function()
        local pig = Pig.new()
        Pig.take_damage(pig)
        -- First update: AC resets (state change Walk→Hit1), accumulates 0.20, no advance
        Pig.update(pig, 0.20, 0)
        assert.are.equal(1, Pig.get_current_frame(pig))
        -- Second update: total 0.40 >= 0.25 → frame 2
        Pig.update(pig, 0.20, 0)
        assert.are.equal(2, Pig.get_current_frame(pig))
    end)

    it("Run animation resets to frame 1 on transition when dt=0 (no frame advance)", function()
        local pig = Pig.new()
        Pig.take_damage(pig)          -- → Hit1
        -- Force transition with dt=0: pre-fill timer to threshold so state flips to
        -- Run but AC accumulates 0s → stays at reset frame 1.
        pig.state_timer = 0.5
        Pig.update(pig, 0, 0)         -- timer 0.5+0=0.5 >= 0.5 → Run; AC: nil→Run reset, 0 dt → frame 1
        assert.are.equal("Run", pig.state)
        assert.are.equal(1, Pig.get_current_frame(pig))
    end)

    it("Dead animation resets to frame 1 on transition when dt=0 (no frame advance)", function()
        local pig = Pig.new()
        Pig.take_damage(pig)
        Pig.update(pig, 1.0, 0)       -- → Run
        Pig.take_damage(pig)          -- → Hit2
        -- Force transition to Dead with dt=0
        pig.state_timer = 0.5
        Pig.update(pig, 0, 0)         -- timer 0.5 >= 0.5 → Dead; AC: Run→Dead reset, 0 dt → frame 1
        assert.are.equal("Dead", pig.state)
        assert.are.equal(1, Pig.get_current_frame(pig))
    end)

end)
