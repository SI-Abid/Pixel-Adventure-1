-- spec/player_state_spec.lua
-- Tests for the pure-logic player state machine.

local PlayerState = require("src.player_state")

describe("PlayerState.update_state", function()

    -- Helper: build a minimal player table
    local function make_player(velocity_x, velocity_y, is_grounded)
        return {
            velocity_x  = velocity_x,
            velocity_y  = velocity_y,
            is_grounded = is_grounded,
            state       = "Idle",
        }
    end

    -- ------------------------------------------------------------------ Idle
    describe("Idle", function()
        it("is set when grounded and not moving horizontally", function()
            local p = make_player(0, 0, true)
            PlayerState.update_state(p)
            assert.are.equal("Idle", p.state)
        end)

        it("is set when grounded with zero velocity_x but non-zero velocity_y (landing frame)", function()
            local p = make_player(0, 5, true)
            PlayerState.update_state(p)
            assert.are.equal("Idle", p.state)
        end)
    end)

    -- --------------------------------------------------------------- Running
    describe("Running", function()
        it("is set when grounded and moving right", function()
            local p = make_player(150, 0, true)
            PlayerState.update_state(p)
            assert.are.equal("Running", p.state)
        end)

        it("is set when grounded and moving left (negative velocity_x)", function()
            local p = make_player(-150, 0, true)
            PlayerState.update_state(p)
            assert.are.equal("Running", p.state)
        end)

        it("is set when grounded with both horizontal and vertical velocity", function()
            local p = make_player(100, 3, true)
            PlayerState.update_state(p)
            assert.are.equal("Running", p.state)
        end)
    end)

    -- --------------------------------------------------------------- Jumping
    describe("Jumping", function()
        it("is set when airborne and moving upward (negative velocity_y)", function()
            local p = make_player(0, -400, false)
            PlayerState.update_state(p)
            assert.are.equal("Jumping", p.state)
        end)

        it("is set when airborne, moving horizontally and upward", function()
            local p = make_player(200, -100, false)
            PlayerState.update_state(p)
            assert.are.equal("Jumping", p.state)
        end)

        it("is set for any negative velocity_y, including small values", function()
            local p = make_player(0, -1, false)
            PlayerState.update_state(p)
            assert.are.equal("Jumping", p.state)
        end)
    end)

    -- --------------------------------------------------------------- Falling
    describe("Falling", function()
        it("is set when airborne and moving downward (positive velocity_y)", function()
            local p = make_player(0, 300, false)
            PlayerState.update_state(p)
            assert.are.equal("Falling", p.state)
        end)

        it("is set when airborne with exactly zero velocity_y (apex of jump)", function()
            local p = make_player(0, 0, false)
            PlayerState.update_state(p)
            assert.are.equal("Falling", p.state)
        end)

        it("is set when airborne, moving horizontally and downward", function()
            local p = make_player(-50, 200, false)
            PlayerState.update_state(p)
            assert.are.equal("Falling", p.state)
        end)
    end)

    -- --------------------------------------------------- Return value checks
    describe("Return value", function()
        it("returns the new state string", function()
            local p = make_player(0, 0, true)
            local result = PlayerState.update_state(p)
            assert.are.equal("Idle", result)
        end)

        it("returns 'Running' directly", function()
            local p = make_player(100, 0, true)
            local result = PlayerState.update_state(p)
            assert.are.equal("Running", result)
        end)
    end)

    -- ------------------------------------------------ State mutation checks
    describe("Mutation", function()
        it("overwrites a stale state", function()
            local p = make_player(0, -300, false)
            p.state = "Idle"  -- stale
            PlayerState.update_state(p)
            assert.are.equal("Jumping", p.state)
        end)

        it("only changes the state field, not other fields", function()
            local p = make_player(100, 0, true)
            PlayerState.update_state(p)
            assert.are.equal(100,  p.velocity_x)
            assert.are.equal(0,    p.velocity_y)
            assert.are.equal(true, p.is_grounded)
        end)
    end)

end)
