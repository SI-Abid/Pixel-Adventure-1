# Animation Controller — Plan

## Module
`src/animation_controller.lua`

> Note: `src/animation.lua` already exists as a Love2D-dependent sprite renderer.
> This module is the pure-logic counterpart — no love.* calls, safe for busted tests.

## Public API

```lua
local AC = require("src.animation_controller")

-- Build a controller from a config table.
-- config: { StateName = { total_frames=N, time_per_frame=T }, ... }
local ctrl = AC.new(config)

-- Advance the controller by dt seconds for the given state string.
-- Resets frame and timer immediately when current_state changes.
AC.update(ctrl, dt, current_state)

-- Returns the active frame index (integer, 1-based).
local frame = AC.get_current_frame(ctrl)
```

## Internal State
| Field | Type | Purpose |
|---|---|---|
| `config` | table | The animation config passed to `new` |
| `current_state` | string\|nil | Last seen state (for change detection) |
| `frame` | integer | Current frame index (1-based) |
| `timer` | number | Accumulated dt since last frame advance |

## Behaviour Rules
1. On state change → `frame = 1`, `timer = 0`, `current_state = new_state`.
2. Each `update`: accumulate `dt` into `timer`. While `timer >= time_per_frame`, subtract `time_per_frame` and advance frame.
3. On frame overflow (`frame > total_frames`) → wrap to 1 (looping).
4. `get_current_frame` returns `ctrl.frame`.
