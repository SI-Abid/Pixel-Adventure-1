-- spec/animation_controller_spec.lua
-- Tests for the pure-logic animation controller.

local AC = require("src.animation_controller")

-- Shared config used by most tests
local CONFIG = {
    Idle    = { total_frames = 4, time_per_frame = 0.1 },
    Running = { total_frames = 6, time_per_frame = 0.05 },
    Jumping = { total_frames = 2, time_per_frame = 0.2 },
}

describe("AC.new", function()

    it("returns a controller table", function()
        local ctrl = AC.new(CONFIG)
        assert.is_table(ctrl)
    end)

    it("starts at frame 1", function()
        local ctrl = AC.new(CONFIG)
        assert.are.equal(1, AC.get_current_frame(ctrl))
    end)

    it("stores the provided config", function()
        local ctrl = AC.new(CONFIG)
        assert.are.equal(4, ctrl.config.Idle.total_frames)
    end)

end)

describe("AC.update — basic frame advance", function()

    it("does not advance frame before time_per_frame elapses", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.05, "Idle")   -- half of 0.1
        assert.are.equal(1, AC.get_current_frame(ctrl))
    end)

    it("advances to frame 2 exactly when time_per_frame elapses", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.1, "Idle")
        assert.are.equal(2, AC.get_current_frame(ctrl))
    end)

    it("accumulates dt across multiple updates", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.06, "Idle")
        AC.update(ctrl, 0.06, "Idle")   -- total 0.12 → 1 advance
        assert.are.equal(2, AC.get_current_frame(ctrl))
    end)

    it("advances multiple frames when dt is large", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.25, "Idle")   -- 0.25 / 0.1 = 2 full advances → frame 3
        assert.are.equal(3, AC.get_current_frame(ctrl))
    end)

    it("advances correctly for a faster animation (Running)", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.05, "Running")
        assert.are.equal(2, AC.get_current_frame(ctrl))
    end)

end)

describe("AC.update — looping", function()

    it("wraps from last frame back to 1", function()
        local ctrl = AC.new(CONFIG)
        -- Idle has 4 frames at 0.1 each; 4 advances → back to 1
        AC.update(ctrl, 0.4, "Idle")
        assert.are.equal(1, AC.get_current_frame(ctrl))
    end)

    it("handles wrap mid-large-dt (more than one full loop)", function()
        local ctrl = AC.new(CONFIG)
        -- 9 advances on Idle (4 frames), starting at 1:
        -- 1→2→3→4→1→2→3→4→1→2 → lands on frame 2
        AC.update(ctrl, 0.9, "Idle")
        assert.are.equal(2, AC.get_current_frame(ctrl))
    end)

    it("wraps correctly for Running (6 frames)", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.30, "Running")  -- 6 advances → back to 1
        assert.are.equal(1, AC.get_current_frame(ctrl))
    end)

end)

describe("AC.update — state change reset", function()

    it("resets to frame 1 immediately when state changes", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.25, "Idle")       -- advances to frame 3
        assert.are.equal(3, AC.get_current_frame(ctrl))
        AC.update(ctrl, 0.0, "Running")     -- state change → reset
        assert.are.equal(1, AC.get_current_frame(ctrl))
    end)

    it("resets timer on state change so no ghost advance happens", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.09, "Idle")       -- 0.09 accumulated, not yet advanced
        AC.update(ctrl, 0.0, "Running")     -- state change wipes timer
        AC.update(ctrl, 0.04, "Running")    -- 0.04 < 0.05 — should NOT advance yet
        assert.are.equal(1, AC.get_current_frame(ctrl))
    end)

    it("advances normally after a state change reset", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.25, "Idle")
        AC.update(ctrl, 0.0, "Running")
        AC.update(ctrl, 0.05, "Running")    -- exactly one Running frame
        assert.are.equal(2, AC.get_current_frame(ctrl))
    end)

    it("same-state update does NOT reset", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.2, "Idle")        -- frame 3
        AC.update(ctrl, 0.0, "Idle")        -- same state — no reset
        assert.are.equal(3, AC.get_current_frame(ctrl))
    end)

    it("handles first update (previous state nil) without reset artifact", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.1, "Idle")        -- very first call; state goes nil→Idle
        assert.are.equal(2, AC.get_current_frame(ctrl))
    end)

end)

describe("AC.get_current_frame", function()

    it("returns an integer", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.15, "Idle")
        local f = AC.get_current_frame(ctrl)
        assert.are.equal(math.floor(f), f)
    end)

    it("never returns 0 or below", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 0.0, "Idle")
        assert.is_true(AC.get_current_frame(ctrl) >= 1)
    end)

    it("never exceeds total_frames for the active animation", function()
        local ctrl = AC.new(CONFIG)
        AC.update(ctrl, 99.9, "Jumping")    -- many loops on a 2-frame anim
        assert.is_true(AC.get_current_frame(ctrl) <= CONFIG.Jumping.total_frames)
    end)

end)
