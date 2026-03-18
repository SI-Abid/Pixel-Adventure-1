-- main.lua
-- Game orchestrator: menu → running → gameover state machine.
-- Uses infinite RunnerLevel with procedural chunks.

local Menu        = require("menu")
local Player      = require("player")
local RunnerLevel = require("runner_level")

local SCALE    = 2
local SCREEN_W = 800
local SCREEN_H = 450

-- ─── State ────────────────────────────────────────────────────────────────────
local gameState = "menu"   -- "menu" | "running" | "gameover"
local menu
local player
local level
local highScore = 0
local lastScore = 0
local lastDist  = 0

-- ─── HUD assets ───────────────────────────────────────────────────────────────
local fontHUD
local fontBig
local heartImg

-- ─── Sounds ───────────────────────────────────────────────────────────────────
local snd = {}

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function playSound(s)
    if s then
        s:stop()
        s:play()
    end
end

local function startGame(charPath)
    level  = RunnerLevel.new()
    player = Player.new(48, 128, charPath)
end

-- ─── Love callbacks ───────────────────────────────────────────────────────────
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    fontHUD  = love.graphics.newFont(16)
    fontBig  = love.graphics.newFont(32)
    heartImg = love.graphics.newImage("assets/heart.png")
    heartImg:setFilter("nearest", "nearest")

    -- Sounds
    local function tryLoad(path, kind)
        local ok, src = pcall(love.audio.newSource, path, kind)
        return ok and src or nil
    end
    snd.jump     = tryLoad("assets/Sounds/jump.wav",          "static")
    snd.collect  = tryLoad("assets/Sounds/collect_fruit.wav", "static")
    snd.hit      = tryLoad("assets/Sounds/hit.wav",           "static")
    snd.bounce   = tryLoad("assets/Sounds/bounce.wav",        "static")
    snd.gameover = tryLoad("assets/Sounds/disappear.wav",     "static")

    menu = Menu.new()
end

function love.update(dt)
    dt = math.min(dt, 0.05)

    if gameState == "menu" then
        menu:update(dt)

    elseif gameState == "running" then
        level:update(dt, player.x)
        player:update(dt, level)

        -- Collectibles
        local px, py, pw, ph = player:getHitbox()
        local gained = level:checkCollectibles(px, py, pw, ph)
        if gained > 0 then
            player:addScore(gained)
            playSound(snd.collect)
        end

        -- Enemies
        for _, enemy in ipairs(level:getEnemies()) do
            enemy:update(dt)
            if enemy:checkCollision(px, py, pw, ph) then
                local _, ey = enemy:getHitbox()
                if player.vy > 0 and (py + ph) < (ey + 14) then
                    -- Stomp kill
                    enemy:kill()
                    player.vy = -300
                    player:addScore(20)
                    playSound(snd.bounce)
                elseif player.hitTimer <= 0 then
                    player:takeDamage()
                    playSound(snd.hit)
                end
            end
        end

        -- Traps
        for _, trap in ipairs(level:getTraps()) do
            local tx, ty, tw, th = trap:getHitbox()
            if px < tx + tw and px + pw > tx and
               py < ty + th and py + ph > ty then
                if player.hitTimer <= 0 then
                    player:takeDamage()
                    playSound(snd.hit)
                end
            end
        end

        -- Camera
        level:updateCamera(
            player.x + player.bw / 2,
            player.y + player.bh / 2,
            SCREEN_W, SCREEN_H, SCALE
        )

        -- Fall off bottom → instant death
        if player.y > level.worldH + 80 then
            player.lives = 0
        end

        -- Game over
        if player.lives <= 0 then
            lastScore = player.score
            lastDist  = math.floor(player.x / 16)
            highScore = math.max(highScore, lastScore)
            playSound(snd.gameover)
            gameState = "gameover"
        end
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    if gameState == "menu" then
        local chosen = menu:keypressed(key)
        if chosen then
            startGame(chosen)
            gameState = "running"
        end

    elseif gameState == "running" then
        local jumped = player:keypressed(key)
        if jumped then playSound(snd.jump) end

    elseif gameState == "gameover" then
        if key == "r" then
            gameState = "menu"
            menu      = Menu.new()
        end
    end
end

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        local chosen = menu:mousepressed(x, y, button)
        if chosen then
            startGame(chosen)
            gameState = "running"
        end
    end
end

-- ─── Drawing ──────────────────────────────────────────────────────────────────
function love.draw()
    if gameState == "menu" then
        menu:draw()
        return
    end

    -- World (scaled + camera-translated)
    love.graphics.push()
    love.graphics.scale(SCALE, SCALE)
    love.graphics.translate(-level.camX, -level.camY)

    level:draw()

    for _, enemy in ipairs(level:getEnemies()) do
        enemy:draw()
    end

    player:draw()

    love.graphics.pop()

    -- HUD (screen space)
    drawHUD()
end

function drawHUD()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontHUD)

    -- Score (top-left)
    love.graphics.print("Score: " .. player.score, 10, 10)

    -- Heart lives
    for i = 1, player.lives do
        love.graphics.draw(heartImg, 10 + (i - 1) * 20, 34, 0, 1, 1)
    end

    -- Distance (top-right)
    local dist = math.floor(player.x / 16)
    local dtxt = "Dist: " .. dist .. "m"
    love.graphics.print(dtxt, SCREEN_W - fontHUD:getWidth(dtxt) - 10, 10)

    -- Difficulty bar (top-right below distance)
    if level then
        local d = level.difficulty
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
        love.graphics.rectangle("fill", SCREEN_W - 110, 32, 100, 8)
        love.graphics.setColor(
            0.2 + 0.8 * d,
            0.8 - 0.6 * d,
            0.2,
            0.9
        )
        love.graphics.rectangle("fill", SCREEN_W - 110, 32, 100 * d, 8)
        love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
        love.graphics.rectangle("line", SCREEN_W - 110, 32, 100, 8)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Game over overlay
    if gameState == "gameover" then
        -- Semi-transparent backdrop
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        love.graphics.setFont(fontBig)
        love.graphics.setColor(1, 0.2, 0.2, 1)
        local title = "GAME OVER"
        love.graphics.print(title, (SCREEN_W - fontBig:getWidth(title)) / 2, SCREEN_H / 2 - 70)

        love.graphics.setFont(fontHUD)
        love.graphics.setColor(1, 1, 1, 1)

        local lines = {
            "Score:  " .. lastScore,
            "Dist:   " .. lastDist .. " m",
            "Best:   " .. highScore,
            "",
            "Press R to return to menu",
        }
        local yOff = SCREEN_H / 2 - 20
        for _, ln in ipairs(lines) do
            love.graphics.print(ln, (SCREEN_W - fontHUD:getWidth(ln)) / 2, yOff)
            yOff = yOff + 22
        end
    end
end
