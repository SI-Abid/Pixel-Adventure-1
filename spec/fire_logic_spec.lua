-- spec/fire_logic_spec.lua
-- Tests for the pure-logic FireLogic state machine.
-- New cycle:  Off → Hit → On → (burn_duration timer) → Off  (repeatable)

local FL = require("src.fire_logic")

-- ─── FireLogic.new ────────────────────────────────────────────────────────────
describe("FireLogic.new", function()

    it("returns a table", function()
        assert.is_table(FL.new())
    end)

    it("starts in Off state", function()
        assert.are.equal("Off", FL.new().state)
    end)

    it("is not active on creation", function()
        assert.is_false(FL.is_active(FL.new()))
    end)

    it("stores the provided burn_duration", function()
        local fl = FL.new(3.0)
        assert.are.equal(3.0, fl.burn_duration)
    end)

    it("uses a positive default burn_duration when none is provided", function()
        local fl = FL.new()
        assert.is_true(fl.burn_duration > 0,
            "burn_duration should be positive")
    end)

end)

-- ─── FireLogic.trigger ────────────────────────────────────────────────────────
describe("FireLogic.trigger", function()

    it("transitions Off → Hit", function()
        local fl = FL.new()
        FL.trigger(fl)
        assert.are.equal("Hit", fl.state)
    end)

    it("is a no-op when already in Hit", function()
        local fl = FL.new()
        FL.trigger(fl)           -- Off → Hit
        FL.trigger(fl)           -- should stay Hit
        assert.are.equal("Hit", fl.state)
    end)

    it("is a no-op when already On", function()
        local fl = FL.new(10)
        FL.trigger(fl)           -- → Hit
        FL.update(fl, 0, true)   -- → On
        FL.trigger(fl)           -- should stay On
        assert.are.equal("On", fl.state)
    end)

end)

-- ─── FireLogic.update ─────────────────────────────────────────────────────────
describe("FireLogic.update", function()

    it("transitions Hit → On when hit_done is true", function()
        local fl = FL.new(10)
        FL.trigger(fl)
        FL.update(fl, 0, true)
        assert.are.equal("On", fl.state)
    end)

    it("stays in Hit when hit_done is false", function()
        local fl = FL.new(10)
        FL.trigger(fl)
        FL.update(fl, 0, false)
        assert.are.equal("Hit", fl.state)
    end)

    it("does not change Off state", function()
        local fl = FL.new(10)
        FL.update(fl, 1.0, true)
        assert.are.equal("Off", fl.state)
    end)

    it("accumulates burn_timer while On", function()
        local fl = FL.new(10)
        FL.trigger(fl)
        FL.update(fl, 0, true)    -- → On, burn_timer = burn_duration = 10
        FL.update(fl, 1.0, false) -- timer ticks: 10 - 1 = 9
        assert.are.equal("On", fl.state)
    end)

end)

-- ─── FireLogic.is_active ──────────────────────────────────────────────────────
describe("FireLogic.is_active", function()

    it("returns false in Off", function()
        assert.is_false(FL.is_active(FL.new()))
    end)

    it("returns false in Hit", function()
        local fl = FL.new()
        FL.trigger(fl)
        assert.is_false(FL.is_active(fl))
    end)

    it("returns true in On", function()
        local fl = FL.new(10)
        FL.trigger(fl)
        FL.update(fl, 0, true)
        assert.is_true(FL.is_active(fl))
    end)

end)

-- ─── Burnout: On → Off ────────────────────────────────────────────────────────
describe("FireLogic burnout (On → Off)", function()

    it("transitions On → Off when burn_timer expires", function()
        local fl = FL.new(2.0)
        FL.trigger(fl)
        FL.update(fl, 0, true)    -- Hit → On; burn_timer = 2.0
        FL.update(fl, 2.0, false) -- timer reaches 0 → Off
        assert.are.equal("Off", fl.state)
    end)

    it("stays On while burn_timer has not expired", function()
        local fl = FL.new(2.0)
        FL.trigger(fl)
        FL.update(fl, 0, true)    -- → On
        FL.update(fl, 1.9, false) -- timer = 0.1 > 0, still On
        assert.are.equal("On", fl.state)
    end)

    it("transitions On → Off via two partial updates that together exceed duration", function()
        local fl = FL.new(2.0)
        FL.trigger(fl)
        FL.update(fl, 0, true)    -- → On
        FL.update(fl, 1.5, false) -- timer = 0.5
        assert.are.equal("On", fl.state)
        FL.update(fl, 0.6, false) -- timer = -0.1 → Off
        assert.are.equal("Off", fl.state)
    end)

    it("is not active after burning out", function()
        local fl = FL.new(2.0)
        FL.trigger(fl)
        FL.update(fl, 0, true)
        FL.update(fl, 2.0, false)
        assert.is_false(FL.is_active(fl))
    end)

end)

-- ─── Re-trigger after burnout ─────────────────────────────────────────────────
describe("FireLogic re-trigger after burnout", function()

    local function burned_out_fl()
        local fl = FL.new(2.0)
        FL.trigger(fl)
        FL.update(fl, 0, true)    -- → On
        FL.update(fl, 2.0, false) -- → Off
        return fl
    end

    it("can be triggered again after burning out", function()
        local fl = burned_out_fl()
        FL.trigger(fl)
        assert.are.equal("Hit", fl.state)
    end)

    it("becomes active again after full second cycle", function()
        local fl = burned_out_fl()
        FL.trigger(fl)            -- Off → Hit
        FL.update(fl, 0, true)    -- Hit → On
        assert.is_true(FL.is_active(fl))
    end)

    it("burns out a second time after another burn_duration", function()
        local fl = burned_out_fl()
        FL.trigger(fl)
        FL.update(fl, 0, true)    -- → On (second cycle)
        FL.update(fl, 2.0, false) -- burns out again
        assert.are.equal("Off", fl.state)
    end)

end)

-- ─── Full lifecycle ───────────────────────────────────────────────────────────
describe("FireLogic full lifecycle", function()

    it("Off → Hit → On → Off in one cycle", function()
        local fl = FL.new(1.0)
        assert.are.equal("Off", fl.state)
        assert.is_false(FL.is_active(fl))

        FL.trigger(fl)
        assert.are.equal("Hit", fl.state)
        assert.is_false(FL.is_active(fl))

        FL.update(fl, 0, false)   -- animation still playing
        assert.are.equal("Hit", fl.state)

        FL.update(fl, 0, true)    -- animation finished → On
        assert.are.equal("On", fl.state)
        assert.is_true(FL.is_active(fl))

        FL.update(fl, 1.0, false) -- burn_duration expires → Off
        assert.are.equal("Off", fl.state)
        assert.is_false(FL.is_active(fl))
    end)

end)
