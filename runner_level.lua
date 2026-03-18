-- runner_level.lua
-- Infinite Mario-style level: chunk-based procedural generation.
-- Player controls manually; chunks grow rightward; old chunks culled from left.
--
-- Column indices are 1-indexed throughout (matching original level.lua).
-- Tile at 1-indexed col C: world_x = (C-1)*TILE_SIZE

local Animation   = require("animation")
local Trap        = require("trap")
local RunnerEnemy = require("runner_enemy")

local RunnerLevel  = {}
RunnerLevel.__index = RunnerLevel

-- ─── Constants ────────────────────────────────────────────────────────────────
local TILE_SIZE  = 16
local MAP_ROWS   = 15
local GROUND_ROW = 11   -- surface row (1-indexed)
local CHUNK_W    = 20   -- tile columns per chunk

-- Minimum tiles-ahead of player before generating next chunk
local LOOKAHEAD_TILES = CHUNK_W * 2

-- Tile quad atlas positions (col, row) in the 22×11 terrain image
local TILE_QUADS_DEF = {
    [1] = {0,0}, [2] = {1,0}, [3] = {2,0},     -- grass TL/TM/TR
    [4] = {0,1}, [5] = {1,1}, [6] = {2,1},     -- dirt  L /M /R
    [7] = {17,0}, [8] = {18,0}, [9] = {19,0},  -- thin platform L/M/R
}
local ONE_WAY_TILES = { [7] = true, [8] = true, [9] = true }

-- Fruit definitions: {filename, point_value, frame_count}
local FRUIT_DEFS = {
    { "Apple.png",      10, 17 },
    { "Bananas.png",    10, 17 },
    { "Cherries.png",   15, 17 },
    { "Kiwi.png",       10, 17 },
    { "Melon.png",      20, 17 },
    { "Orange.png",     10, 17 },
    { "Pineapple.png",  15, 17 },
    { "Strawberry.png", 15, 17 },
}

-- ─── Constructor ──────────────────────────────────────────────────────────────
function RunnerLevel.new()
    local self = setmetatable({}, RunnerLevel)

    -- Terrain tileset
    local terrainImg = love.graphics.newImage("assets/Terrain/Terrain (16x16).png")
    terrainImg:setFilter("nearest", "nearest")
    local tw = terrainImg:getWidth()
    local th = terrainImg:getHeight()

    self.tileQuads = {}
    for id, coords in pairs(TILE_QUADS_DEF) do
        self.tileQuads[id] = love.graphics.newQuad(
            coords[1] * TILE_SIZE, coords[2] * TILE_SIZE,
            TILE_SIZE, TILE_SIZE, tw, th
        )
    end
    self.terrainImg = terrainImg

    -- Background (tiling)
    local bgImg = love.graphics.newImage("assets/Background/Blue.png")
    bgImg:setFilter("nearest", "nearest")
    bgImg:setWrap("repeat", "repeat")
    self.bgImg = bgImg

    -- Preload fruit images
    self.fruitImgs = {}
    for i, fd in ipairs(FRUIT_DEFS) do
        local img = love.graphics.newImage("assets/Items/Fruits/" .. fd[1])
        img:setFilter("nearest", "nearest")
        self.fruitImgs[i] = { img = img, value = fd[2], frames = fd[3] }
    end

    -- World dimensions
    self.mapRows = MAP_ROWS
    self.worldH  = MAP_ROWS * TILE_SIZE   -- 240 px

    -- Camera
    self.camX = 0
    self.camY = 0

    -- Chunk state (1-indexed columns)
    self.activeChunks = {}
    self.chunkCount   = 0
    self.nextStartCol = 1   -- next chunk's first column (1-indexed)
    self.difficulty   = 0

    math.randomseed(os.time())

    -- Pre-generate first 4 chunks
    for _ = 1, 4 do
        self:_spawnChunk()
    end

    return self
end

-- ─── Tile helpers (1-indexed col/row) ─────────────────────────────────────────
-- Convert world pixel to 1-indexed tile column/row (matches original level.lua)
function RunnerLevel:worldToCol(wx)
    return math.floor(wx / TILE_SIZE) + 1
end

function RunnerLevel:worldToRow(wy)
    return math.floor(wy / TILE_SIZE) + 1
end

-- World pixel of a tile's LEFT edge (1-indexed col)
local function tileX(col)
    return (col - 1) * TILE_SIZE
end

-- World pixel of a tile's TOP edge (1-indexed row)
local function tileY(row)
    return (row - 1) * TILE_SIZE
end

-- getTile: row and col are both 1-indexed
function RunnerLevel:getTile(row, col)
    if row < 1 or row > MAP_ROWS then return 0 end
    for _, chunk in ipairs(self.activeChunks) do
        -- Local column within this chunk (1-indexed)
        local lc = col - chunk.startCol + 1
        if lc >= 1 and lc <= CHUNK_W then
            local rowTiles = chunk.tiles[row]
            return (rowTiles and rowTiles[lc]) or 0
        end
    end
    return 0
end

function RunnerLevel:isSolid(col, row)
    local tid = self:getTile(row, col)
    if tid == 0 then return false end
    return not ONE_WAY_TILES[tid]
end

function RunnerLevel:isOneWay(col, row)
    return ONE_WAY_TILES[self:getTile(row, col)] or false
end

-- ─── Collision resolution (identical logic to level.lua) ──────────────────────
function RunnerLevel:resolveHorizontal(hx, hy, hw, hh)
    local topRow    = self:worldToRow(hy + 1)
    local bottomRow = self:worldToRow(hy + hh - 1)
    local leftCol   = self:worldToCol(hx)
    local rightCol  = self:worldToCol(hx + hw - 1)

    if self:isSolid(leftCol, topRow) or self:isSolid(leftCol, bottomRow) then
        local wallRight = leftCol * TILE_SIZE   -- right edge of tile leftCol (1-indexed formula)
        return hx - wallRight
    end
    if self:isSolid(rightCol, topRow) or self:isSolid(rightCol, bottomRow) then
        local wallLeft = (rightCol - 1) * TILE_SIZE
        return (hx + hw) - wallLeft
    end
    return 0
end

function RunnerLevel:resolveVertical(hx, hy, hw, hh, vy)
    local leftCol  = self:worldToCol(hx + 1)
    local rightCol = self:worldToCol(hx + hw - 2)

    local bottomRow  = self:worldToRow(hy + hh)
    local solidFloor = self:isSolid(leftCol, bottomRow) or self:isSolid(rightCol, bottomRow)
    local oneWayFloor = (vy >= 0) and
        (self:isOneWay(leftCol, bottomRow) or self:isOneWay(rightCol, bottomRow))

    if solidFloor or oneWayFloor then
        local floorTop    = (bottomRow - 1) * TILE_SIZE
        local penetration = (hy + hh) - floorTop
        if oneWayFloor and not solidFloor and penetration > TILE_SIZE / 2 then
            -- Jumping up through a one-way tile — let through
        else
            return penetration
        end
    end

    local topRow = self:worldToRow(hy)
    if self:isSolid(leftCol, topRow) or self:isSolid(rightCol, topRow) then
        local ceilBottom = topRow * TILE_SIZE
        return hy - ceilBottom
    end

    return 0
end

-- ─── Camera ───────────────────────────────────────────────────────────────────
function RunnerLevel:updateCamera(playerX, playerY, screenW, screenH, scale)
    local viewW = screenW / scale
    local viewH = screenH / scale
    self.camX = playerX - viewW / 2
    self.camY = playerY - viewH / 2
    self.camX = math.max(0, self.camX)   -- no right clamp (infinite)
    self.camY = math.max(0, math.min(self.camY, self.worldH - viewH))
end

-- ─── Collectibles ─────────────────────────────────────────────────────────────
function RunnerLevel:checkCollectibles(px, py, pw, ph)
    local gained = 0
    for _, chunk in ipairs(self.activeChunks) do
        for _, c in ipairs(chunk.collectibles) do
            if not c.collected then
                local cx = c.x + 6
                local cy = c.y + 6
                if px < cx + 20 and px + pw > cx and
                   py < cy + 20 and py + ph > cy then
                    c.collected = true
                    gained      = gained + c.value
                end
            end
        end
    end
    return gained
end

-- ─── Accessors for enemies / traps ────────────────────────────────────────────
function RunnerLevel:getEnemies()
    local list = {}
    for _, chunk in ipairs(self.activeChunks) do
        for _, e in ipairs(chunk.enemies) do
            list[#list + 1] = e
        end
    end
    return list
end

function RunnerLevel:getTraps()
    local list = {}
    for _, chunk in ipairs(self.activeChunks) do
        for _, t in ipairs(chunk.traps) do
            list[#list + 1] = t
        end
    end
    return list
end

-- ─── Chunk generation ─────────────────────────────────────────────────────────
function RunnerLevel:_makeFruit(wx, wy)
    local idx = math.random(1, #self.fruitImgs)
    local fd  = self.fruitImgs[idx]
    return {
        x         = wx,
        y         = wy,
        anim      = Animation.new(fd.img, 32, 32, fd.frames, 17, true),
        collected = false,
        value     = fd.value,
    }
end

function RunnerLevel:_pickTrap()
    local d    = self.difficulty
    local pool = { "spike" }
    if d > 0.25 then pool[#pool+1] = "fire" end
    if d > 0.55 then pool[#pool+1] = "saw"  end
    return pool[math.random(1, #pool)]
end

function RunnerLevel:_pickEnemy()
    local d    = self.difficulty
    local pool = { "mushroom" }
    if d > 0.30 then pool[#pool+1] = "chicken" end
    if d > 0.60 then pool[#pool+1] = "pig"     end
    return pool[math.random(1, #pool)]
end

function RunnerLevel:_spawnChunk()
    self.chunkCount = self.chunkCount + 1
    self.difficulty = math.min(1.0, math.max(0, (self.chunkCount - 3) / 40))

    local startCol     = self.nextStartCol
    self.nextStartCol  = startCol + CHUNK_W

    local d    = self.difficulty
    local safe = (self.chunkCount <= 2)

    local chunk = {
        startCol     = startCol,
        width        = CHUNK_W,
        tiles        = {},
        traps        = {},
        enemies      = {},
        collectibles = {},
    }
    for r = 1, MAP_ROWS do chunk.tiles[r] = {} end

    -- ── Gaps ─────────────────────────────────────────────────────────────────
    local gaps = {}
    if not safe and math.random() < 0.30 * d then
        local gs = math.random(3, CHUNK_W - 5)
        local gw = math.random(2, math.min(4, math.floor(2 + d * 2)))
        gw = math.min(gw, CHUNK_W - gs - 2)
        if gw >= 2 then
            table.insert(gaps, { s = gs, w = gw })
        end
    end

    local function inGap(lc)
        for _, g in ipairs(gaps) do
            if lc >= g.s and lc < g.s + g.w then return true end
        end
        return false
    end

    -- ── Ground (rows GROUND_ROW → MAP_ROWS) ───────────────────────────────────
    for lc = 1, CHUNK_W do
        if not inGap(lc) then
            local leftEdge  = inGap(lc - 1)
            local rightEdge = inGap(lc + 1)

            local grassTile
            if leftEdge then
                grassTile = 1   -- TL cap (right-of-gap)
            elseif rightEdge then
                grassTile = 3   -- TR cap (left-of-gap)
            else
                grassTile = 2   -- TM
            end
            chunk.tiles[GROUND_ROW][lc] = grassTile

            local dirtTile = leftEdge and 4 or (rightEdge and 6 or 5)
            for r = GROUND_ROW + 1, MAP_ROWS do
                chunk.tiles[r][lc] = dirtTile
            end
        end
    end
    -- Left world edge gets proper TL/L tiles
    if startCol == 1 then
        if chunk.tiles[GROUND_ROW][1] then
            chunk.tiles[GROUND_ROW][1] = 1
            for r = GROUND_ROW + 1, MAP_ROWS do chunk.tiles[r][1] = 4 end
        end
    end

    -- ── Floating platforms ────────────────────────────────────────────────────
    if math.random() < 0.35 + 0.15 * d then
        local pRow   = (math.random() < 0.5) and 4 or 7
        local pStart = math.random(2, CHUNK_W - 5)
        local pW     = math.random(3, 5)
        pW = math.min(pW, CHUNK_W - pStart)

        for i = 0, pW - 1 do
            local lc  = pStart + i
            local tid = (i == 0) and 7 or ((i == pW - 1) and 9 or 8)
            chunk.tiles[pRow][lc] = tid
        end

        -- Fruit above platform center
        local fc     = pStart + math.floor(pW / 2)
        local absCol = startCol + fc - 1
        local wx     = tileX(absCol)
        local wy     = tileY(pRow) - 32
        table.insert(chunk.collectibles, self:_makeFruit(wx, wy))
    end

    -- ── Random ground fruit ───────────────────────────────────────────────────
    if math.random() < 0.45 then
        local fc = math.random(2, CHUNK_W - 2)
        if not inGap(fc) then
            local absCol = startCol + fc - 1
            local wx     = tileX(absCol)
            local wy     = tileY(GROUND_ROW) - 32
            table.insert(chunk.collectibles, self:_makeFruit(wx, wy))
        end
    end

    -- ── Traps ─────────────────────────────────────────────────────────────────
    if not safe and math.random() < 0.12 + 0.30 * d then
        local tc = math.random(2, CHUNK_W - 2)
        if not inGap(tc) then
            local ttype  = self:_pickTrap()
            local absCol = startCol + tc - 1
            local wx     = tileX(absCol)
            local wy
            if ttype == "spike" then
                wy = tileY(GROUND_ROW) - 16
            elseif ttype == "fire" then
                wy = tileY(GROUND_ROW) - 32
            else  -- saw
                wy = tileY(GROUND_ROW) - 38
            end
            table.insert(chunk.traps, Trap.new(ttype, wx, wy))
        end
    end

    -- ── Enemies ───────────────────────────────────────────────────────────────
    if not safe and math.random() < 0.18 + 0.22 * d then
        local ec     = CHUNK_W - 2
        local absCol = startCol + ec - 1
        local wx     = tileX(absCol)
        local wy     = tileY(GROUND_ROW) - 32
        table.insert(chunk.enemies, RunnerEnemy.new(wx, wy, self:_pickEnemy()))
    end

    table.insert(self.activeChunks, chunk)
end

-- ─── Update ───────────────────────────────────────────────────────────────────
function RunnerLevel:update(dt, playerX)
    -- Animate collectibles and traps in active chunks
    for _, chunk in ipairs(self.activeChunks) do
        for _, c in ipairs(chunk.collectibles) do
            if not c.collected then c.anim:update(dt) end
        end
        for _, t in ipairs(chunk.traps) do
            t:update(dt)
        end
    end

    -- Generate new chunks while there are fewer than LOOKAHEAD_TILES ahead
    local function lastRightPx()
        local last = self.activeChunks[#self.activeChunks]
        if last then
            return tileX(last.startCol + last.width)  -- right edge of last tile
        end
        return 0
    end

    while playerX > lastRightPx() - LOOKAHEAD_TILES * TILE_SIZE do
        self:_spawnChunk()
    end

    -- Cull chunks whose right edge is far behind the camera
    local cullX = self.camX - 600
    for i = #self.activeChunks, 1, -1 do
        local c = self.activeChunks[i]
        if tileX(c.startCol + c.width) < cullX then
            table.remove(self.activeChunks, i)
        end
    end
end

-- ─── Draw ─────────────────────────────────────────────────────────────────────
function RunnerLevel:draw()
    -- Background (wrapping tile, covers current viewport)
    local bgW = self.bgImg:getWidth()
    local bgH = self.bgImg:getHeight()
    local vw  = 400  -- SCREEN_W / SCALE
    local vh  = 225  -- SCREEN_H / SCALE
    love.graphics.setColor(1, 1, 1, 1)
    local bgQ = love.graphics.newQuad(
        self.camX, self.camY,
        vw + bgW, vh + bgH,
        bgW, bgH
    )
    love.graphics.draw(self.bgImg, bgQ, self.camX, self.camY)

    -- Visible column range (1-indexed)
    local firstVisCo = self:worldToCol(self.camX) - 1
    local lastVisCo  = self:worldToCol(self.camX + vw) + 1

    -- Draw tiles
    love.graphics.setColor(1, 1, 1, 1)
    for _, chunk in ipairs(self.activeChunks) do
        for r = 1, MAP_ROWS do
            local rowTiles = chunk.tiles[r]
            if rowTiles then
                for lc = 1, CHUNK_W do
                    local absCol = chunk.startCol + lc - 1
                    if absCol >= firstVisCo and absCol <= lastVisCo then
                        local tid = rowTiles[lc]
                        if tid and tid ~= 0 and self.tileQuads[tid] then
                            love.graphics.draw(
                                self.terrainImg,
                                self.tileQuads[tid],
                                tileX(absCol),
                                tileY(r)
                            )
                        end
                    end
                end
            end
        end
    end

    -- Draw collectibles
    for _, chunk in ipairs(self.activeChunks) do
        for _, c in ipairs(chunk.collectibles) do
            if not c.collected then
                c.anim:draw(c.x, c.y, 1)
            end
        end
    end

    -- Draw traps
    for _, chunk in ipairs(self.activeChunks) do
        for _, t in ipairs(chunk.traps) do
            t:draw()
        end
    end
end

return RunnerLevel
