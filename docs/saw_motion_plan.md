# Saw Motion — Plan

## Goal
Make the saw trap oscillate along a visible chain track.
- Saw spins (existing animation, unchanged)
- Saw slides left/right (or up/down) within a bounded range
- Chain tiles mark the full travel path behind the saw

## New module: src/saw_logic.lua (pure logic)
- `SawLogic.new(cx, cy, range, speed, axis, phase)` — axis "h" or "v", phase shifts start
- `SawLogic.update(sl, dt)` — advances timer, updates ox/oy via sin oscillation
- `SawLogic.get_pos(sl)` → `(cx+ox, cy+oy)` current saw centre

Formula: `offset = sin(timer × speed × 2π) × (range/2)`

## Changes to src/trap.lua
1. Require `SawLogic`; add `Chain.png` to lazy-loader for saw type
2. Saw config: `range = 64 px` (±32), `speed = 0.8 osc/s`
3. `Trap.new("saw", x, y)`:
   - Store `self.saw = SawLogic.new(cx, cy, range, speed, "h")`
   - Store reference to chain image
   - `self.trap_type = trapType` (so update/draw can branch)
4. `Trap:update(dt)`:  for saw also call `SawLogic.update(self.saw, dt)`
5. `Trap:getHitbox()`: for saw derive top-left from `SawLogic.get_pos()`
6. `Trap:draw()`:  for saw — draw chain tiles spanning full range, then animated saw on top

## Chain rendering (horizontal example)
```
chain tiles: cx - range/2  →  cx + range/2, every 8px, at y = cy - 4
saw:         animation:draw at (saw_x - 19, saw_y - 19)
```

## Runner level
No changes needed; `TRAP_TILE_SPAN.saw = 3` is fine for spawn-column reservation.
The visual chain extends beyond, but that is purely cosmetic.

## Tests: spec/saw_logic_spec.lua
- new(): stores cx/cy, range, speed, defaults axis="h", ox=oy=0
- update(0): ox=0 at t=0 (sin(0)=0)
- update(0.25): ox ≈ +half at quarter cycle
- update(0.5):  ox ≈ 0 at half cycle
- update(0.75): ox ≈ -half at three-quarter cycle
- oy stays 0 during "h", ox stays 0 during "v"
- get_pos returns cx+ox, cy+oy
- phase offset shifts start position
- bounds: ox always within [-half, +half]
