-- src/fire_logic.lua
-- Pure-logic fire trap state machine. No Love2D dependencies.
--
-- Cycle:  Off → Hit → On → (burn_duration timer) → Off  (repeatable)
--
-- Off:  dormant; no damage; player touch triggers ignition.
-- Hit:  one-shot ignition animation plays; no damage.
-- On:   looping flame; damages player on contact; burns out after burn_duration.

local FireLogic = {}

-- Default burn duration when none is supplied (seconds).
local DEFAULT_BURN = 2.5

--- Create a new fire state.
--- @param burn_duration number|nil  Seconds the fire stays On before going Off again.
---                                  Defaults to DEFAULT_BURN (2.5 s).
--- @return table
function FireLogic.new(burn_duration)
    return {
        state         = "Off",
        burn_timer    = 0,
        burn_duration = burn_duration or DEFAULT_BURN,
    }
end

--- Trigger ignition. Transitions Off → Hit; no-op in any other state.
--- @param fl table
function FireLogic.trigger(fl)
    if fl.state == "Off" then
        fl.state = "Hit"
    end
end

--- Advance state every frame.
---   Hit  → On  when the ignition animation finishes (hit_done = true).
---   On   → Off when burn_timer reaches zero.
--- @param fl       table
--- @param dt       number   Elapsed seconds this frame.
--- @param hit_done boolean  True when the Hit animation has finished.
function FireLogic.update(fl, dt, hit_done)
    if fl.state == "Hit" and hit_done then
        fl.state      = "On"
        fl.burn_timer = fl.burn_duration
    elseif fl.state == "On" then
        fl.burn_timer = fl.burn_timer - dt
        if fl.burn_timer <= 0 then
            fl.state = "Off"
        end
    end
end

--- Returns true only when the fire is fully active (On state).
--- @param fl table
--- @return boolean
function FireLogic.is_active(fl)
    return fl.state == "On"
end

return FireLogic
