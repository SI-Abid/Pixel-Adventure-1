-- main.lua
-- Game orchestrator: wires player, enemies, level, and HUD together.

local Player = require("player")
local Enemy  = require("enemy")
local Level  = require("level")

local SCALE    = 2
local SCREEN_W = 800
local SCREEN_H = 450

local player
local enemies
local level
local gameOver = false
local fontHUD
local fontBig
local heartImg

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    fontHUD = love.graphics.newFont(16)
    fontBig = love.graphics.newFont(32)
    heartImg = love.graphics.newImage("assets/heart.png")
    heartImg:setFilter("nearest", "nearest")

    level = Level.new()

    -- Player spawns on ground: row 11 starts at y=160, sprite is 32 tall
    player = Player.new(32, 128)

    -- Enemies: (x, y, patrolLeft, patrolRight) in world pixels
    enemies = {
        Enemy.new(200, 128, 128, 320),    -- patrol on ground
        Enemy.new(400, 128, 352, 500),     -- patrol on ground
        Enemy.new(33 * 16, 64, 32 * 16, 36 * 16),  -- patrol on platform 2
    }
end

function love.update(dt)
    if gameOver then return end

    -- Cap dt to prevent physics tunneling
    dt = math.min(dt, 0.05)

    level:update(dt)
    player:update(dt, level)

    -- Collectibles
    local px, py, pw, ph = player:getHitbox()
    local gained = level:checkCollectibles(px, py, pw, ph)
    if gained > 0 then player:addScore(gained) end

    -- Enemies
    for _, enemy in ipairs(enemies) do
        enemy:update(dt)
        if enemy:checkCollision(px, py, pw, ph) then
            -- If player is falling and feet are above enemy's mid-point, stomp kills enemy
            local ex, ey = enemy:getHitbox()
            if player.vy > 0 and (py + ph) < (ey + 14) then
                enemy:kill()
                player.vy = -300  -- bounce up after stomp
                player:addScore(20)
            else
                player:takeDamage()
            end
        end
    end

    -- Camera follows player
    level:updateCamera(
        player.x + player.bw / 2,
        player.y + player.bh / 2,
        SCREEN_W, SCREEN_H, SCALE
    )

    -- Fall off bottom -> lose a life and respawn
    if player.y > level.worldH + 100 then
        player.lives = player.lives - 1
        player.x  = 32
        player.y  = 128
        player.vx = 0
        player.vy = 0
    end

    -- Game over
    if player.lives <= 0 then
        gameOver = true
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    if gameOver and key == "r" then
        -- Restart
        love.load()
        gameOver = false
        return
    end

    player:keypressed(key)
end

function love.draw()
    -- World rendering (scaled + camera translated)
    love.graphics.push()
    love.graphics.scale(SCALE, SCALE)
    love.graphics.translate(-level.camX, -level.camY)

    level:draw()

    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end

    player:draw()

    love.graphics.pop()

    -- HUD (screen space, no scale/translate)
    drawHUD()
end

function drawHUD()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontHUD)
    love.graphics.print("Score: " .. player.score, 10, 10)

    -- Draw heart icons for lives
    for i = 1, player.lives do
        love.graphics.draw(heartImg, 10 + (i - 1) * 20, 34, 0, 1, 1)
    end

    if gameOver then
        love.graphics.setFont(fontBig)
        love.graphics.setColor(1, 0.2, 0.2, 1)
        local text = "GAME OVER"
        local tw = fontBig:getWidth(text)
        love.graphics.print(text, (SCREEN_W - tw) / 2, SCREEN_H / 2 - 40)

        love.graphics.setFont(fontHUD)
        love.graphics.setColor(1, 1, 1, 1)
        local sub = "Press R to restart"
        local sw = fontHUD:getWidth(sub)
        love.graphics.print(sub, (SCREEN_W - sw) / 2, SCREEN_H / 2 + 10)
    end
end
