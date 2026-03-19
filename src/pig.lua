-- src/pig.lua
-- Pure-logic Pig enemy state machine. No Love2D dependencies.
--
-- States:  Walk → Hit1 → Run → Hit2 → Dead
-- The rendering/physics class (enemy_pig.lua) owns love.* calls.

local AC = require("src.animation_controller")

local Pig = {}

local HIT_STUN_DURATION = 0.5   -- seconds in Hit1 before chasing
local DEATH_DURATION    = 0.5   -- seconds in Hit2 before dying

local ANIM_CONFIG = {
    Walk = { total_frames = 6, time_per_frame = 0.10 },
    Hit1 = { total_frames = 2, time_per_frame = 0.25 },
    Run  = { total_frames = 6, time_per_frame = 0.10 },
    Hit2 = { total_frames = 2, time_per_frame = 0.25 },
    Dead = { total_frames = 4, time_per_frame = 0.10 },
}

--- Create a new Pig entity with default state.
--- @return table
function Pig.new()
    return {
        state       = "Walk",
        hits_taken  = 0,
        state_timer = 0,
        anim_ctrl   = AC.new(ANIM_CONFIG),
    }
end

--- Apply one hit to the pig.
--- hits_taken 0→1: Walk/Run → Hit1
--- hits_taken 1→2: Hit1/Run → Hit2
--- @param pig table
function Pig.take_damage(pig)
    if pig.hits_taken == 0 then
        pig.hits_taken  = 1
        pig.state       = "Hit1"
        pig.state_timer = 0
    elseif pig.hits_taken == 1 then
        pig.hits_taken  = 2
        pig.state       = "Hit2"
        pig.state_timer = 0
    end
    -- hits_taken >= 2 (Dead): ignore further damage
end

--- Advance the pig's state machine by dt seconds.
--- @param pig      table   Pig entity from Pig.new()
--- @param dt       number  Delta time in seconds
--- @param player_x number  Player world-x (used for chase direction in Run)
function Pig.update(pig, dt, player_x)
    local s = pig.state

    if s == "Walk" then
        -- Patrol stub: movement math delegated to the rendering layer.
        -- State remains 'Walk'.

    elseif s == "Hit1" then
        pig.state_timer = pig.state_timer + dt
        if pig.state_timer >= HIT_STUN_DURATION then
            pig.state = "Run"
        end

    elseif s == "Run" then
        -- Chase player: direction math delegated to the rendering layer.
        -- State remains 'Run'.

    elseif s == "Hit2" then
        pig.state_timer = pig.state_timer + dt
        if pig.state_timer >= DEATH_DURATION then
            pig.state = "Dead"
        end

    end
    -- "Dead": terminal state — no transitions, no timer.

    -- Drive the animation controller with the (possibly just-updated) state.
    AC.update(pig.anim_ctrl, dt, pig.state)
end

--- Return the current animation frame index (1-based integer).
--- @param pig table  Pig entity from Pig.new()
--- @return integer
function Pig.get_current_frame(pig)
    return AC.get_current_frame(pig.anim_ctrl)
end

return Pig
