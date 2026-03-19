# Player State Machine — Plan

## Module
`src/player_state.lua`

## Public API
```lua
local PlayerState = require("src.player_state")

-- Mutates player.state in-place and returns the new state string.
PlayerState.update_state(player)
```

## State Transition Rules
| Condition | State |
|---|---|
| `is_grounded == true` and `velocity_x == 0` | `'Idle'` |
| `is_grounded == true` and `velocity_x ~= 0` | `'Running'` |
| `is_grounded == false` and `velocity_y < 0` | `'Jumping'` |
| `is_grounded == false` and `velocity_y >= 0` | `'Falling'` |

## Dependencies
- Pure Lua — no `love.*` calls. Safe for `busted` tests without Love2D mocks.

## Integration
`player.lua` will `require("src.player_state")` and call `PlayerState.update_state(self)` inside `Player:update()` after physics resolution.
