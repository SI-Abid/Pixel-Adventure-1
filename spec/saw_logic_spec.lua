-- spec/saw_logic_spec.lua
-- Tests for the pure-logic SawLogic oscillation module.

local SL = require("src.saw_logic")

local HALF_PI = math.pi / 2

-- ─── SawLogic.new ─────────────────────────────────────────────────────────────
describe("SawLogic.new", function()

    it("returns a table", function()
        assert.is_table(SL.new(100, 200, 48, 1.0))
    end)

    it("stores cx and cy", function()
        local sl = SL.new(100, 200, 48, 1.0)
        assert.are.equal(100, sl.cx)
        assert.are.equal(200, sl.cy)
    end)

    it("stores range and speed", function()
        local sl = SL.new(100, 200, 48, 0.8)
        assert.are.equal(48,  sl.range)
        assert.are.equal(0.8, sl.speed)
    end)

    it("defaults axis to 'h'", function()
        local sl = SL.new(100, 200, 48, 1.0)
        assert.are.equal("h", sl.axis)
    end)

    it("accepts 'v' axis", function()
        local sl = SL.new(100, 200, 48, 1.0, "v")
        assert.are.equal("v", sl.axis)
    end)

    it("initial ox and oy are 0 (no phase)", function()
        local sl = SL.new(100, 200, 48, 1.0)
        assert.are.equal(0, sl.ox)
        assert.are.equal(0, sl.oy)
    end)

    it("phase shifts the initial timer", function()
        -- phase=0.25 at speed=1: sin(2π*1*0.25)=sin(π/2)=1 → ox = +half
        local sl = SL.new(100, 200, 48, 1.0, "h", 0.25)
        SL.update(sl, 0)
        assert.are.near(24, sl.ox, 0.001)
    end)

end)

-- ─── SawLogic.get_pos ─────────────────────────────────────────────────────────
describe("SawLogic.get_pos", function()

    it("returns (cx, cy) before any update", function()
        local sl = SL.new(100, 200, 48, 1.0)
        local x, y = SL.get_pos(sl)
        assert.are.equal(100, x)
        assert.are.equal(200, y)
    end)

    it("returns cx+ox, cy+oy after update", function()
        local sl = SL.new(100, 200, 48, 1.0)
        SL.update(sl, 0.25)          -- ox ≈ +24
        local x, y = SL.get_pos(sl)
        assert.are.near(124, x, 0.001)
        assert.are.equal(200, y)
    end)

end)

-- ─── SawLogic.update — horizontal axis ────────────────────────────────────────
describe("SawLogic.update horizontal", function()

    it("ox is 0 after update(0) — sin(0)=0", function()
        local sl = SL.new(100, 200, 48, 1.0)
        SL.update(sl, 0)
        assert.are.near(0, sl.ox, 0.001)
    end)

    it("oy stays 0 during horizontal motion", function()
        local sl = SL.new(100, 200, 48, 1.0)
        for _, t in ipairs({0.1, 0.25, 0.5, 0.75, 1.0}) do
            SL.update(sl, t)
            assert.are.equal(0, sl.oy)
        end
    end)

    it("ox reaches +half at quarter cycle (t = 1/(4*speed))", function()
        local sl = SL.new(100, 200, 48, 1.0)
        SL.update(sl, 0.25)           -- sin(2π*1*0.25) = sin(π/2) = 1
        assert.are.near(24, sl.ox, 0.001)
    end)

    it("ox returns near 0 at half cycle (t = 1/(2*speed))", function()
        local sl = SL.new(100, 200, 48, 1.0)
        SL.update(sl, 0.5)            -- sin(2π*1*0.5) = sin(π) ≈ 0
        assert.are.near(0, sl.ox, 0.001)
    end)

    it("ox reaches -half at three-quarter cycle", function()
        local sl = SL.new(100, 200, 48, 1.0)
        SL.update(sl, 0.75)           -- sin(2π*1*0.75) = sin(3π/2) = -1
        assert.are.near(-24, sl.ox, 0.001)
    end)

    it("ox returns near 0 at full cycle", function()
        local sl = SL.new(100, 200, 48, 1.0)
        SL.update(sl, 1.0)            -- sin(2π) ≈ 0
        assert.are.near(0, sl.ox, 0.001)
    end)

    it("ox stays within [-half, +half] over many steps", function()
        local sl   = SL.new(100, 200, 48, 1.0)
        local half = 24
        for _ = 1, 40 do
            SL.update(sl, 0.05)
            assert.is_true(sl.ox >= -half - 0.001 and sl.ox <= half + 0.001,
                "ox " .. sl.ox .. " out of range [-" .. half .. ", " .. half .. "]")
        end
    end)

    it("accumulates time across multiple calls", function()
        local sl  = SL.new(100, 200, 48, 1.0)
        local sl2 = SL.new(100, 200, 48, 1.0)
        SL.update(sl, 0.25)
        SL.update(sl2, 0.10)
        SL.update(sl2, 0.15)          -- same total dt
        assert.are.near(sl.ox, sl2.ox, 0.001)
    end)

    it("works with non-unit speed", function()
        local sl = SL.new(100, 200, 64, 2.0)
        SL.update(sl, 0.125)          -- t*speed = 0.25 → quarter cycle → ox = +32
        assert.are.near(32, sl.ox, 0.001)
    end)

end)

-- ─── SawLogic.update — vertical axis ──────────────────────────────────────────
describe("SawLogic.update vertical", function()

    it("oy oscillates and ox stays 0", function()
        local sl = SL.new(100, 200, 64, 1.0, "v")
        SL.update(sl, 0.25)           -- quarter cycle → oy = +half
        assert.are.equal(0, sl.ox)
        assert.are.near(32, sl.oy, 0.001)
    end)

    it("oy stays within [-half, +half] over many steps", function()
        local sl   = SL.new(100, 200, 64, 1.0, "v")
        local half = 32
        for _ = 1, 40 do
            SL.update(sl, 0.05)
            assert.is_true(sl.oy >= -half - 0.001 and sl.oy <= half + 0.001,
                "oy " .. sl.oy .. " out of range")
        end
    end)

    it("get_pos x does not change during vertical motion", function()
        local sl = SL.new(100, 200, 64, 1.0, "v")
        SL.update(sl, 1.23)
        local x, _ = SL.get_pos(sl)
        assert.are.equal(100, x)
    end)

    it("get_pos y does not change during horizontal motion", function()
        local sl = SL.new(100, 200, 64, 1.0, "h")
        SL.update(sl, 1.23)
        local _, y = SL.get_pos(sl)
        assert.are.equal(200, y)
    end)

end)
