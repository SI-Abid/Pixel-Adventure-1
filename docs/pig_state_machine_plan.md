# Pig Enemy State Machine — Plan

## Module
`src/pig.lua`  (pure logic — no love.* calls)

> `src/enemy_pig.lua` is the Love2D rendering class; this module encodes only the
> state-transition rules, testable with busted.

## States
| State  | Meaning                                      |
|--------|----------------------------------------------|
| Walk   | Default patrol; state stays 'Walk'           |
| Hit1   | First hit stun; auto-transitions to 'Run' after HIT_STUN_DURATION |
| Run    | Chasing player; state stays 'Run'            |
| Hit2   | Second hit / death stun; auto-transitions to 'Dead' after DEATH_DURATION |
| Dead   | Terminal; no further transitions             |

## Constants
| Name              | Value  |
|-------------------|--------|
| HIT_STUN_DURATION | 0.5 s  |
| DEATH_DURATION    | 0.5 s  |

## Public API
```lua
local Pig = require("src.pig")

local pig = Pig.new()
-- pig.state       == "Walk"
-- pig.hits_taken  == 0
-- pig.state_timer == 0

Pig.take_damage(pig)   -- transitions Walk→Hit1 or Hit1→Hit2
Pig.update(pig, dt, player_x)  -- drives timer-based auto-transitions
```

## Entity fields
| Field        | Type   | Default |
|--------------|--------|---------|
| state        | string | "Walk"  |
| hits_taken   | int    | 0       |
| state_timer  | float  | 0       |
