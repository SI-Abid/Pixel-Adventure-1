# Fire Trap State Machine — Plan

## States
| State | Image           | Loops | Damages | Transition                          |
|-------|-----------------|-------|---------|-------------------------------------|
| Off   | Off.png (1 fr)  | —     | No      | player touches → Hit                |
| Hit   | Hit (16x32).png (4 fr, 12 fps) | No | No | animation done → On |
| On    | On  (16x32).png (3 fr,  8 fps) | Yes | Yes | terminal               |

## New module: src/fire_logic.lua (pure logic)
- `FireLogic.new()` → `{state = "Off"}`
- `FireLogic.trigger(fl)` → Off → Hit (no-op in other states)
- `FireLogic.update(fl, hit_done)` → Hit → On when `hit_done = true`
- `FireLogic.is_active(fl)` → true only when state == "On"

## Changes to src/trap.lua
1. Load Off.png and Hit assets for fire type
2. `Trap.new("fire", x, y)` creates FireLogic + three animations (off, hit, on)
3. `Trap:trigger()` — calls `FireLogic.trigger` for fire; no-op for other types
4. `Trap:isActive()` — false in Off/Hit for fire; always true for spike/saw
5. `Trap:update(dt)` — advances the active fire animation; Hit→On via `hit_done`
6. `Trap:draw()` — picks animation by `fl.state`

## Changes to main.lua
```lua
trap:trigger()                          -- ignites fire on first touch (no-op for others)
if trap:isActive() and player.hitTimer <= 0 then
    player:takeDamage()
end
```

## Tests: spec/fire_logic_spec.lua
- new() starts in "Off"
- trigger() Off→Hit; no-op in Hit; no-op in On
- update() Hit→On when hit_done=true; stays Hit when false; Off unchanged
- is_active() false in Off/Hit, true in On
