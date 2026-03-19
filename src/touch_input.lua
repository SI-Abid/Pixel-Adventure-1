-- touch_input.lua
-- On-screen virtual buttons for Android / iOS.
-- Full colour-coded circles:  amber = jump,  green = special,  purple = movement.
-- Coordinates are in the 800×450 logical canvas space.

local M = {}

-- Shared state read by Player:update()
M.state = { left = false, right = false }

-- Circle zone definitions: cx/cy = center, r = radius
-- No label field — icons are drawn programmatically to avoid font unicode issues.
local zones = {
    left    = { cx =  52, cy = 408, r = 28, color = {0.55, 0.32, 0.90, 1}, icon = "left"    },
    right   = { cx = 118, cy = 408, r = 28, color = {0.55, 0.32, 0.90, 1}, icon = "right"   },
    jump    = { cx = 748, cy = 410, r = 34, color = {1.00, 0.75, 0.15, 1}, icon = "up"      },
    special = { cx = 680, cy = 390, r = 26, color = {0.22, 0.80, 0.42, 1}, icon = "special" },
}

-- Map touch id → zone name (for multi-touch tracking)
local activeZones = {}

local function hitZone(x, y)
    for name, z in pairs(zones) do
        local dx = x - z.cx
        local dy = y - z.cy
        if dx * dx + dy * dy <= z.r * z.r then
            return name
        end
    end
    return nil
end

-- Returns zone name so caller can handle jump/special as discrete events.
function M.touchpressed(id, x, y)
    local zone = hitZone(x, y)
    if zone then
        activeZones[id] = zone
        if zone == "left" or zone == "right" then
            M.state[zone] = true
        end
        return zone
    end
end

function M.touchreleased(id, x, y)
    local zone = activeZones[id]
    if zone then
        activeZones[id] = nil
        if zone == "left" or zone == "right" then
            local stillHeld = false
            for _, z in pairs(activeZones) do
                if z == zone then stillHeld = true; break end
            end
            if not stillHeld then M.state[zone] = false end
        end
    end
end

function M.touchmoved(id, x, y, dx, dy)
    local newZone = hitZone(x, y)
    local oldZone = activeZones[id]
    if oldZone == newZone then return end

    -- Release old zone
    if oldZone and (oldZone == "left" or oldZone == "right") then
        M.state[oldZone] = false
    end

    -- Claim new zone
    if newZone then
        activeZones[id] = newZone
        if newZone == "left" or newZone == "right" then
            M.state[newZone] = true
        end
    else
        activeZones[id] = nil
    end
end

-- Draw the on-screen buttons (called from love.draw after canvas push/scale)
function M.draw()
    love.graphics.push("all")

    for name, z in pairs(zones) do
        local held = false
        for _, zone in pairs(activeZones) do
            if zone == name then held = true; break end
        end

        local c     = z.color
        local alpha = held and 0.88 or 0.38
        local r     = held and z.r * 1.06 or z.r

        -- Outer glow when pressed
        if held then
            love.graphics.setColor(c[1], c[2], c[3], 0.20)
            love.graphics.circle("fill", z.cx, z.cy, r + 10)
        end

        -- Circle fill
        love.graphics.setColor(c[1], c[2], c[3], alpha)
        love.graphics.circle("fill", z.cx, z.cy, r)

        -- Ring border (slightly brighter)
        love.graphics.setColor(
            math.min(c[1] * 1.4, 1),
            math.min(c[2] * 1.4, 1),
            math.min(c[3] * 1.4, 1),
            alpha + 0.25
        )
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", z.cx, z.cy, r)
        love.graphics.setLineWidth(1)

        -- Icon drawn as filled polygon (no unicode font needed)
        love.graphics.setColor(0, 0, 0, 0.78)
        local cx, cy = z.cx, z.cy
        local s = r * 0.42   -- icon scale relative to circle size
        if z.icon == "left" then
            love.graphics.polygon("fill",
                cx + s,       cy - s,
                cx - s * 1.1, cy,
                cx + s,       cy + s)
        elseif z.icon == "right" then
            love.graphics.polygon("fill",
                cx - s,       cy - s,
                cx + s * 1.1, cy,
                cx - s,       cy + s)
        elseif z.icon == "up" then
            love.graphics.polygon("fill",
                cx,      cy - s * 1.1,
                cx + s,  cy + s,
                cx - s,  cy + s)
        elseif z.icon == "special" then
            -- Lightning bolt (two triangles)
            love.graphics.polygon("fill",
                cx + s * 0.3, cy - s * 1.1,
                cx - s * 0.5, cy + s * 0.1,
                cx + s * 0.2, cy + s * 0.1)
            love.graphics.polygon("fill",
                cx - s * 0.2, cy - s * 0.1,
                cx + s * 0.5, cy - s * 0.1,
                cx - s * 0.3, cy + s * 1.1)
        end
    end

    love.graphics.pop()
end

return M
