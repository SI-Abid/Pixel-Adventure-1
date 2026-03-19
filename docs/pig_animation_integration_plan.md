# Pig Animation Integration — Plan

## Summary
Wire `src/animation_controller.lua` into `src/pig.lua` so the Pig entity
owns its own frame counter. No Love2D calls introduced.

## Changes to src/pig.lua

### 1. Require animation controller at top
```lua
local AC = require("src.animation_controller")
```

### 2. Animation config (dummy data, pure numbers)
```lua
local ANIM_CONFIG = {
    Walk = { total_frames = 6, time_per_frame = 0.10 },
    Hit1 = { total_frames = 2, time_per_frame = 0.25 },
    Run  = { total_frames = 6, time_per_frame = 0.10 },
    Hit2 = { total_frames = 2, time_per_frame = 0.25 },
    Dead = { total_frames = 4, time_per_frame = 0.10 },
}
```

### 3. Pig.new() — instantiate controller
```lua
pig.anim_ctrl = AC.new(ANIM_CONFIG)
```

### 4. Pig.update() — drive controller after state logic
```lua
AC.update(pig.anim_ctrl, dt, pig.state)
```

### 5. New function Pig.get_current_frame()
```lua
function Pig.get_current_frame(pig)
    return AC.get_current_frame(pig.anim_ctrl)
end
```

## Integration tests to add in spec/pig_spec.lua
- New pig starts at frame 1
- After take_damage() → Hit1, advancing dt=0.25 advances to frame 2
- After take_damage() → Hit1, advancing dt=0.50 wraps back to frame 1 (loop)
- State change Walk→Hit1 resets frame to 1 (AC handles this internally)
- get_current_frame() delegates to the controller correctly
