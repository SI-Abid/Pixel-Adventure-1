# Enemy Pig Refactor — Plan

## Goal
Wire `src/pig.lua` (pure-logic state machine) into `src/enemy_pig.lua` (Love2D rendering class).
The pig should Walk by default, Hit1 on first stomp, Run toward the player, Hit2 on second stomp,
then expire (Dead). Replace the old `alive/dying` lifecycle with the state machine.

## Behaviour
| State | Movement              | Animation | Transition                    |
|-------|-----------------------|-----------|-------------------------------|
| Walk  | BaseEnemy patrol      | Walk      | `kill()` → Hit1               |
| Hit1  | freeze (vx = 0)       | Hit1      | auto after 0.5 s → Run        |
| Run   | chase player_x        | Run       | `kill()` → Hit2               |
| Hit2  | freeze (vx = 0)       | Hit2      | auto after 0.5 s → Dead       |
| Dead  | none                  | —         | terminal; `isExpired() = true`|

## Asset map
```
assets/Enemies/AngryPig/
  Walk (36x30).png   — 16 frames, 10 fps  (looping)
  Run  (36x30).png   — 12 frames, 14 fps  (looping)
  Hit 1 (36x30).png  —  5 frames, 10 fps  (one-shot)
  Hit 2 (36x30).png  —  5 frames, 10 fps  (one-shot)
```

## Changes to src/enemy_pig.lua

1. **Require PigSM** at the top: `local PigSM = require("src.pig")`
2. **CFG**: rename `hitFile` → `hit1File`; add `hit2File`, `hit2Frames`, `hit2Fps`.
3. **loadImgs()**: load `hit1` and `hit2` images; remove old `hit` key.
4. **Pig.new(x, y)**:
   - Attach `self.sm = PigSM.new()`
   - Store `self.last_player_x = x` (updated each frame from main.lua)
   - Store `self.last_sm_state = "Walk"` (for animation reset on state change)
   - `self.anims` keyed by state name: `Walk`, `Run`, `Hit1`, `Hit2`
5. **Pig:update(dt, level, player_x)** — third arg accepted (ignored by other enemies):
   - Update `self.last_player_x` if `player_x` provided
   - Call `PigSM.update(self.sm, dt, self.last_player_x)`
   - Detect state change → reset the new state's animation
   - Per state: Walk → `BaseEnemy.update`; Hit1/Hit2 → `vx=0`; Run → chase; Dead → nothing
   - Call `self.anims[state]:update(dt)` (skip Dead)
6. **Pig:kill()** → call `PigSM.take_damage(self.sm)` only (do NOT call `BaseEnemy:kill()`)
7. **Pig:isExpired()** → `return self.sm.state == "Dead"`
8. **Pig:checkCollision()** → return false when Dead, else delegate to BaseEnemy
9. **Pig:draw()** → select `self.anims[self.sm.state]`; return early if Dead

## Changes to main.lua

- Change `enemy:update(dt, level)` → `enemy:update(dt, level, player.x)` so the pig
  receives `player_x`. Lua ignores extra args in Mushroom/Chicken.

## Test plan (spec/enemy_pig_spec.lua)

Mock `love.graphics` before requiring any Love2D modules. Tests cover:
- Constructor attaches sm, starts in Walk
- `kill()` first call → sm.state == "Hit1", isExpired() false
- Advancing time (PigSM internal) → Run, then Kill → Hit2 → Dead, isExpired() true
- In Hit1/Hit2, update() sets vx = 0
- In Run, pig moves toward player_x
- checkCollision() returns false when Dead
