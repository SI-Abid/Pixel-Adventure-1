-- src/saw_logic.lua
-- Pure-logic saw oscillation. No Love2D dependencies.
--
-- The saw moves sinusoidally between (cx - range/2) and (cx + range/2)
-- along the chosen axis.  Formula: offset = sin(timer * speed * 2π) * (range/2)

local SawLogic = {}

--- Create a new saw oscillation state.
--- @param cx    number  World-space centre x of the travel range
--- @param cy    number  World-space centre y of the travel range
--- @param range number  Total travel distance in pixels (saw moves ±range/2)
--- @param speed number  Oscillations per second
--- @param axis  string  "h" (horizontal, default) or "v" (vertical)
--- @param phase number  Initial timer value in seconds (shifts starting position)
--- @return table
function SawLogic.new(cx, cy, range, speed, axis, phase)
    return {
        cx    = cx,
        cy    = cy,
        range = range,
        speed = speed,
        axis  = axis or "h",
        timer = phase or 0,
        ox    = 0,
        oy    = 0,
    }
end

--- Advance the oscillation by dt seconds.
--- @param sl table  SawLogic state from SawLogic.new()
--- @param dt number  Delta time in seconds
function SawLogic.update(sl, dt)
    sl.timer     = sl.timer + dt
    local half   = sl.range / 2
    local offset = math.sin(sl.timer * sl.speed * math.pi * 2) * half
    if sl.axis == "h" then
        sl.ox = offset
        sl.oy = 0
    else
        sl.ox = 0
        sl.oy = offset
    end
end

--- Return the current world-space centre position of the saw.
--- @param sl table
--- @return number x, number y
function SawLogic.get_pos(sl)
    return sl.cx + sl.ox, sl.cy + sl.oy
end

return SawLogic
