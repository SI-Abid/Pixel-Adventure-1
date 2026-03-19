-- spec/trap_fire_spec.lua
-- Integration tests for FireTrap (src/trap_fire.lua).
-- love.graphics is mocked so no Love2D runtime is required.

_G.love = {
    graphics = {
        newImage = function(path)
            local frames = 1
            if path:find("Hit") then frames = 4
            elseif path:find("On")  then frames = 3 end
            local w = frames * 16
            return {
                setFilter = function() end,
                getWidth  = function() return w  end,
                getHeight = function() return 32 end,
            }
        end,
        newQuad  = function() return {} end,
        setColor = function() end,
        draw     = function() end,
    },
}

local FireTrap  = require("src.trap_fire")
local FireLogic = require("src.fire_logic")

-- ─── FireTrap.new ─────────────────────────────────────────────────────────────

describe("FireTrap.new", function()

    it("returns a table", function()
        assert.is_table(FireTrap.new(100, 200))
    end)

    it("stores x and y", function()
        local ft = FireTrap.new(100, 200)
        assert.are.equal(100, ft.x)
        assert.are.equal(200, ft.y)
    end)

    it("fire state starts Off", function()
        local ft = FireTrap.new(100, 200)
        assert.are.equal("Off", ft.fire.state)
    end)

    it("is not active on creation", function()
        local ft = FireTrap.new(100, 200)
        assert.is_false(ft:isActive())
    end)

    it("has hit and on animations", function()
        local ft = FireTrap.new(100, 200)
        assert.is_table(ft.anims.hit)
        assert.is_table(ft.anims.on)
    end)

    it("accepts an explicit burn_duration", function()
        local ft = FireTrap.new(0, 0, 5.0)
        assert.are.equal(5.0, ft.fire.burn_duration)
    end)

end)

-- ─── FireTrap:getHitbox ───────────────────────────────────────────────────────

describe("FireTrap:getHitbox", function()

    it("returns position offset by bx/by", function()
        local ft = FireTrap.new(100, 200)
        local hx, hy, hw, hh = ft:getHitbox()
        assert.are.equal(100 + ft.bx, hx)
        assert.are.equal(200 + ft.by, hy)
        assert.are.equal(ft.bw, hw)
        assert.are.equal(ft.bh, hh)
    end)

end)

-- ─── FireTrap:trigger ─────────────────────────────────────────────────────────

describe("FireTrap:trigger", function()

    it("transitions fire from Off to Hit", function()
        local ft = FireTrap.new(100, 200)
        ft:trigger()
        assert.are.equal("Hit", ft.fire.state)
    end)

    it("resets hit animation on first trigger", function()
        local ft = FireTrap.new(100, 200)
        ft.anims.hit.currentFrame = 3
        ft:trigger()
        assert.are.equal(1, ft.anims.hit.currentFrame)
    end)

    it("is a no-op when already in Hit", function()
        local ft = FireTrap.new(100, 200)
        ft:trigger()
        ft:trigger()
        assert.are.equal("Hit", ft.fire.state)
    end)

    it("is a no-op when already On", function()
        local ft = FireTrap.new(0, 0, 100)
        ft:trigger()
        for _ = 1, 5 do ft:update(0.1) end
        assert.are.equal("On", ft.fire.state)
        ft:trigger()
        assert.are.equal("On", ft.fire.state)
    end)

    it("re-triggers from Off after burnout", function()
        local ft = FireTrap.new(0, 0, 0.5)
        ft:trigger()
        for _ = 1, 5 do ft:update(0.1) end  -- → On
        ft:update(0.6)                        -- burns out → Off
        ft:trigger()                          -- re-ignite
        assert.are.equal("Hit", ft.fire.state)
    end)

    it("resets hit animation on re-trigger after burnout", function()
        local ft = FireTrap.new(0, 0, 0.5)
        ft:trigger()
        for _ = 1, 5 do ft:update(0.1) end
        ft:update(0.6)                       -- → Off
        ft.anims.hit.currentFrame = 4
        ft:trigger()
        assert.are.equal(1, ft.anims.hit.currentFrame)
    end)

end)

-- ─── FireTrap:isActive ────────────────────────────────────────────────────────

describe("FireTrap:isActive", function()

    it("false in Off", function()
        assert.is_false(FireTrap.new(0, 0):isActive())
    end)

    it("false in Hit", function()
        local ft = FireTrap.new(0, 0)
        ft:trigger()
        assert.is_false(ft:isActive())
    end)

    it("true in On", function()
        local ft = FireTrap.new(0, 0, 100)
        ft:trigger()
        for _ = 1, 5 do ft:update(0.1) end
        assert.is_true(ft:isActive())
    end)

    it("false again after burning out", function()
        local ft = FireTrap.new(0, 0, 0.5)
        ft:trigger()
        for _ = 1, 5 do ft:update(0.1) end  -- → On
        ft:update(0.6)                        -- burns out
        assert.is_false(ft:isActive())
    end)

end)

-- ─── FireTrap:update — state transitions ──────────────────────────────────────

describe("FireTrap:update", function()

    it("Off state does not change without trigger", function()
        local ft = FireTrap.new(0, 0)
        ft:update(10.0)
        assert.are.equal("Off", ft.fire.state)
    end)

    it("Hit transitions to On after animation completes (4 frames at 12 fps)", function()
        local ft = FireTrap.new(0, 0, 100)
        ft:trigger()
        for _ = 1, 5 do ft:update(0.1) end
        assert.are.equal("On", ft.fire.state)
    end)

    it("Hit stays Hit before animation finishes", function()
        local ft = FireTrap.new(0, 0)
        ft:trigger()
        ft:update(0.05)
        assert.are.equal("Hit", ft.fire.state)
    end)

    it("On burns out to Off after burn_duration seconds", function()
        local ft = FireTrap.new(0, 0, 1.0)
        ft:trigger()
        for _ = 1, 5 do ft:update(0.1) end  -- → On (0.5 s of dt consumed)
        ft:update(1.0)                        -- burn_duration 1.0 s expires
        assert.are.equal("Off", ft.fire.state)
    end)

    it("On stays On before burn_duration expires", function()
        local ft = FireTrap.new(0, 0, 5.0)
        ft:trigger()
        for _ = 1, 5 do ft:update(0.1) end  -- → On
        for _ = 1, 20 do ft:update(0.1) end -- 2.0 s < 5.0 burn_duration
        assert.are.equal("On", ft.fire.state)
    end)

end)
