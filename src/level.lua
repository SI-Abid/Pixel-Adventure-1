-- level.lua
-- Level class: tile map, camera, background, collectibles, collision resolution.

local Animation = require("src.animation")

local Level = {}
Level.__index = Level

local TILE_SIZE = 16

-- Tile type to (col, row) in the 22x11 terrain atlas (0-indexed)
local TILE_QUADS_DEF = {
    [1] = {0, 0},   -- grass top-left
    [2] = {1, 0},   -- grass top-mid
    [3] = {2, 0},   -- grass top-right
    [4] = {0, 1},   -- dirt left
    [5] = {1, 1},   -- dirt mid
    [6] = {2, 1},   -- dirt right
    [7] = {17, 0},  -- thin platform left
    [8] = {18, 0},  -- thin platform mid
    [9] = {19, 0},  -- thin platform right
}

-- Tiles that are one-way platforms (pass through from below, land on top)
local ONE_WAY_TILES = {
    [7] = true,
    [8] = true,
    [9] = true,
}

-- 50 columns x 15 rows tile map
-- 0 = air, 1-6 = tile types per TILE_QUADS_DEF
local MAP_DATA = {
    -- row 1-3: sky
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    -- row 4: thin floating platform 1
    {0,0,0,0,0,0,0,0,0,0, 7,8,8,9,0,0,0,0,0,0, 0,0,0,0,7,8,9,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    -- row 5-6: sky
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    -- row 7: thin floating platform 2
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,7,8,8,8,9,0,0,0, 0,0,0,0,7,8,8,9,0,0},
    -- row 8-10: sky
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0},
    -- row 11: ground surface
    {1,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2,2,2,3},
    -- row 12-15: underground fill
    {4,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,6},
    {4,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,6},
    {4,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,6},
    {4,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,5, 5,5,5,5,5,5,5,5,5,6},
}

function Level.new()
    local self = setmetatable({}, Level)

    -- Load terrain tileset
    local terrainImg = love.graphics.newImage("assets/Terrain/Terrain (16x16).png")
    terrainImg:setFilter("nearest", "nearest")
    local tw = terrainImg:getWidth()
    local th = terrainImg:getHeight()

    -- Build quads
    self.tileQuads = {}
    for id, coords in pairs(TILE_QUADS_DEF) do
        self.tileQuads[id] = love.graphics.newQuad(
            coords[1] * TILE_SIZE, coords[2] * TILE_SIZE,
            TILE_SIZE, TILE_SIZE,
            tw, th
        )
    end
    self.terrainImg = terrainImg

    -- Map dimensions
    self.mapRows = #MAP_DATA
    self.mapCols = #MAP_DATA[1]
    self.map     = MAP_DATA

    -- World size in pixels
    self.worldW = self.mapCols * TILE_SIZE
    self.worldH = self.mapRows * TILE_SIZE

    -- Camera
    self.camX = 0
    self.camY = 0

    -- Background (tiled via wrap mode)
    local bgImg = love.graphics.newImage("assets/Background/Blue.png")
    bgImg:setFilter("nearest", "nearest")
    bgImg:setWrap("repeat", "repeat")
    self.bgImg  = bgImg
    self.bgQuad = love.graphics.newQuad(0, 0, self.worldW, self.worldH,
                                         bgImg:getWidth(), bgImg:getHeight())

    -- Collectibles
    self.collectibles = self:_buildCollectibles()

    return self
end

function Level:_buildCollectibles()
    local colls = {}
    local appleImg  = love.graphics.newImage("assets/Items/Fruits/Apple.png")
    local cherryImg = love.graphics.newImage("assets/Items/Fruits/Cherries.png")
    appleImg:setFilter("nearest", "nearest")
    cherryImg:setFilter("nearest", "nearest")

    -- Positions in world pixels (placed above platforms)
    -- Platform 1 at row 4: y = 3*16 = 48, so fruits at y = 48 - 32 = 16
    -- Platform 2 at row 7: y = 6*16 = 96, so fruits at y = 96 - 32 = 64
    -- Ground at row 11: y = 10*16 = 160, so fruits at y = 160 - 32 = 128
    local positions = {
        -- Fruits on platform 1
        {x = 11 * 16, y = 16,  img = appleImg,  frames = 17, value = 10},
        {x = 12 * 16, y = 16,  img = appleImg,  frames = 17, value = 10},
        -- Fruits on platform 1b
        {x = 25 * 16, y = 16,  img = cherryImg, frames = 17, value = 15},
        -- Fruits on ground
        {x = 5 * 16,  y = 128, img = appleImg,  frames = 17, value = 10},
        {x = 15 * 16, y = 128, img = cherryImg, frames = 17, value = 15},
        {x = 20 * 16, y = 128, img = appleImg,  frames = 17, value = 10},
        -- Fruits on platform 2 (row 7, y = 6*16 = 96, fruits at 96-32 = 64)
        {x = 33 * 16, y = 64,  img = appleImg,  frames = 17, value = 10},
        {x = 34 * 16, y = 64,  img = cherryImg, frames = 17, value = 15},
        {x = 45 * 16, y = 64,  img = appleImg,  frames = 17, value = 10},
    }

    for _, p in ipairs(positions) do
        table.insert(colls, {
            x         = p.x,
            y         = p.y,
            anim      = Animation.new(p.img, 32, 32, p.frames, 17, true),
            collected = false,
            value     = p.value,
        })
    end
    return colls
end

function Level:isSolid(col, row)
    if row < 1 or row > self.mapRows then return false end
    if col < 1 or col > self.mapCols then return false end
    local tid = self.map[row][col]
    if tid == 0 then return false end
    -- One-way tiles are not "solid" for general checks (horizontal/ceiling)
    if ONE_WAY_TILES[tid] then return false end
    return true
end

-- Check if tile is a one-way platform (used only for downward floor checks)
function Level:isOneWay(col, row)
    if row < 1 or row > self.mapRows then return false end
    if col < 1 or col > self.mapCols then return false end
    return ONE_WAY_TILES[self.map[row][col]] or false
end

function Level:worldToCol(wx)
    return math.floor(wx / TILE_SIZE) + 1
end

function Level:worldToRow(wy)
    return math.floor(wy / TILE_SIZE) + 1
end

-- Returns horizontal penetration depth to resolve.
function Level:resolveHorizontal(hx, hy, hw, hh)
    local topRow    = self:worldToRow(hy + 1)
    local bottomRow = self:worldToRow(hy + hh - 1)
    local leftCol   = self:worldToCol(hx)
    local rightCol  = self:worldToCol(hx + hw - 1)

    -- Left wall collision
    if self:isSolid(leftCol, topRow) or self:isSolid(leftCol, bottomRow) then
        local wallRight = leftCol * TILE_SIZE
        return hx - wallRight
    end

    -- Right wall collision
    if self:isSolid(rightCol, topRow) or self:isSolid(rightCol, bottomRow) then
        local wallLeft = (rightCol - 1) * TILE_SIZE
        return (hx + hw) - wallLeft
    end

    return 0
end

-- Returns vertical penetration depth to resolve.
-- vy: player's vertical velocity (positive = falling down)
function Level:resolveVertical(hx, hy, hw, hh, vy)
    local leftCol  = self:worldToCol(hx + 1)
    local rightCol = self:worldToCol(hx + hw - 2)

    -- Floor check (solid tiles always block; one-way tiles only block when falling)
    local bottomRow = self:worldToRow(hy + hh)
    local solidFloor = self:isSolid(leftCol, bottomRow) or self:isSolid(rightCol, bottomRow)
    local oneWayFloor = (vy >= 0) and
        (self:isOneWay(leftCol, bottomRow) or self:isOneWay(rightCol, bottomRow))

    if solidFloor or oneWayFloor then
        local floorTop = (bottomRow - 1) * TILE_SIZE
        local penetration = (hy + hh) - floorTop
        -- For one-way platforms, only resolve if we're actually sinking into the top
        -- (prevents snapping when player is deep inside the tile from below)
        if oneWayFloor and not solidFloor and penetration > TILE_SIZE / 2 then
            -- Player is more than halfway through — they jumped up from below, let them pass
        else
            return penetration
        end
    end

    -- Ceiling check (one-way tiles never block upward movement)
    local topRow = self:worldToRow(hy)
    if self:isSolid(leftCol, topRow) or self:isSolid(rightCol, topRow) then
        local ceilBottom = topRow * TILE_SIZE
        return hy - ceilBottom
    end

    return 0
end

function Level:updateCamera(playerX, playerY, screenW, screenH, scale)
    local viewW = screenW / scale
    local viewH = screenH / scale
    self.camX = playerX - viewW / 2
    self.camY = playerY - viewH / 2
    self.camX = math.max(0, math.min(self.camX, self.worldW - viewW))
    self.camY = math.max(0, math.min(self.camY, self.worldH - viewH))
end

function Level:checkCollectibles(px, py, pw, ph)
    local gained = 0
    for _, c in ipairs(self.collectibles) do
        if not c.collected then
            local cx = c.x + 6
            local cy = c.y + 6
            local cw = 20
            local ch = 20
            if px < cx + cw and px + pw > cx and
               py < cy + ch and py + ph > cy then
                c.collected = true
                gained = gained + c.value
            end
        end
    end
    return gained
end

function Level:update(dt)
    for _, c in ipairs(self.collectibles) do
        if not c.collected then
            c.anim:update(dt)
        end
    end
end

function Level:draw()
    -- Background (tiled)
    love.graphics.draw(self.bgImg, self.bgQuad, 0, 0)

    -- Tiles
    for row = 1, self.mapRows do
        for col = 1, self.mapCols do
            local tid = self.map[row][col]
            if tid ~= 0 and self.tileQuads[tid] then
                local wx = (col - 1) * TILE_SIZE
                local wy = (row - 1) * TILE_SIZE
                love.graphics.draw(self.terrainImg, self.tileQuads[tid], wx, wy)
            end
        end
    end

    -- Collectibles
    for _, c in ipairs(self.collectibles) do
        if not c.collected then
            c.anim:draw(c.x, c.y, 1)
        end
    end
end

return Level
