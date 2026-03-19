-- src/animation_controller.lua
-- Pure-logic animation controller. No Love2D dependencies.
--
-- config format:
--   { StateName = { total_frames = N, time_per_frame = T }, ... }

local AC = {}

--- Create a new animation controller.
--- @param config table  Map of state name → { total_frames, time_per_frame }
--- @return table        Controller object
function AC.new(config)
    return {
        config        = config,
        current_state = nil,
        frame         = 1,
        timer         = 0,
    }
end

--- Advance the controller by dt for the given state.
--- Resets frame and timer immediately on state change.
--- @param ctrl          table   Controller from AC.new
--- @param dt            number  Delta time in seconds
--- @param current_state string  Active state name
function AC.update(ctrl, dt, current_state)
    -- State change: reset immediately before accumulating dt
    if current_state ~= ctrl.current_state then
        ctrl.current_state = current_state
        ctrl.frame         = 1
        ctrl.timer         = 0
    end

    local cfg = ctrl.config[current_state]
    if not cfg then return end

    ctrl.timer = ctrl.timer + dt
    while ctrl.timer >= cfg.time_per_frame do
        ctrl.timer = ctrl.timer - cfg.time_per_frame
        ctrl.frame = ctrl.frame + 1
        if ctrl.frame > cfg.total_frames then
            ctrl.frame = 1
        end
    end
end

--- Return the current frame index (1-based integer).
--- @param ctrl table  Controller from AC.new
--- @return integer
function AC.get_current_frame(ctrl)
    return ctrl.frame
end

return AC
