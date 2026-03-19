-- src/player_state.lua
-- Pure-logic player state machine. No Love2D dependencies.

local PlayerState = {}

--- Determine and set player.state based on physics values.
--- @param player table  Must have: velocity_x (number), velocity_y (number), is_grounded (boolean), state (string)
--- @return string       The new state string
function PlayerState.update_state(player)
    local new_state

    if player.is_grounded then
        if player.velocity_x == 0 then
            new_state = "Idle"
        else
            new_state = "Running"
        end
    else
        if player.velocity_y < 0 then
            new_state = "Jumping"
        else
            new_state = "Falling"
        end
    end

    player.state = new_state
    return new_state
end

return PlayerState
