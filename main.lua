time = 0
playerLevel = 1
xp = 0
xpThreshold = 1000

local spawnTimer = 0
local spawnInterval = 2
local cooldown = 0
local isDead = false

levelupMenuOpen = false
powerupChoice = nil

function love.load()
    require "mainCharacter"
    require "enemyUnit"

    mainCharacter.load()  
    enemyUnit.load() 

    love.graphics.setDefaultFilter("nearest", "nearest")

    sounds = {}

    sounds.musicList = {
        love.audio.newSource("music/pixel field.mp3", "stream"),
        love.audio.newSource("music/pixel grass.mp3", "stream"),
        love.audio.newSource("music/pixel tree.mp3", "stream")
    }

    for _, s in pairs(sounds.musicList) do
        s:setLooping(false)
        s:setVolume(0.3)
    end

    currentMusic = sounds.musicList[love.math.random(1, #sounds.musicList)]
    currentMusic:play()

    sounds.deathSounds = {
        love.audio.newSource("dying/dying-1.mp3", "static"),
        love.audio.newSource("dying/dying-2.mp3", "static"),
        love.audio.newSource("dying/dying-3.mp3", "static"),
        love.audio.newSource("dying/dying-4.mp3", "static"),
        love.audio.newSource("dying/dying-5.mp3", "static")
    }

    for _, deathSound in pairs(sounds.deathSounds) do
        deathSound:setVolume(0.5)
    end

end

function love.update(dt) 
    if not isPaused then
        mainCharacter.update(dt) 
        enemyUnit.update(dt)
        world:update(dt) 

        checkCollisions()

        spawnTimer = spawnTimer + dt
        
        if spawnTimer >= spawnInterval then
            spawnEnemiesAtRandomPositions()
            spawnTimer = 0
        end

        if not currentMusic:isPlaying() then
            currentMusic = sounds.musicList[love.math.random(1, #sounds.musicList)]
            currentMusic:play()
        end

        if type(cooldown) ~= "number" then
            cooldown = 0
        end

        if cooldown > 0 then
            cooldown = cooldown - dt
        end

        if love.mouse.isDown(1) then
            mouseDown(1)
        end

        time = time + dt
    end
    
end

function love.draw()
    mainCharacter.draw()

    local standardPadding = 10

    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()

    local font = love.graphics.getFont()

    local xpText = "XP: " .. xp
    local font = love.graphics.getFont()
    local xpTextWidth = (font:getWidth(xpText)) * 2

    local timeText = "TIME: " .. math.floor(time) 
    local TimeTextWidth = (font:getWidth(timeText)) * 2

    local healthText = "health: " .. player.health
    local healthTextWidth = (font:getWidth(healthText)) * 2
    local healthTextX = (windowWidth - healthTextWidth) / 2
    local healthTextY = standardPadding

    xpTextX = standardPadding
    xpTextY = standardPadding

    local timeTextX = windowWidth - TimeTextWidth - standardPadding
    local timeTextY = standardPadding

    love.graphics.print(xpText, xpTextX, xpTextY, 0, 2 )
    love.graphics.print(timeText , timeTextX, timeTextY, 0, 2)

    local padding = 10
    local baseX = padding
    local baseY = love.graphics.getHeight() - 150
    -- debug player health, damage, speed, shooting rate
    love.graphics.print("health: " .. player.health, baseX, baseY, 0, 2)
    love.graphics.print("damage: " .. player.dmg, baseX, baseY + 40, 0, 2)
    love.graphics.print("speed: " .. player.speed, baseX, baseY + 80, 0, 2)
    love.graphics.print("rate: " .. player.arrowCooldown * 100 .. "%",   baseX, baseY + 120, 0, 2)

    
    
    if isPaused then
        if levelupMenuOpen then
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 200, 150, 450, 300)

            love.graphics.setColor(1, 1, 1)
            love.graphics.print("LEVEL UP! Choose a power-up:", 240, 180, 0, 2)

            love.graphics.print("1) +40 Max Health", 240, 240, 0, 2)
            love.graphics.print("2) +10 Damage", 240, 280, 0, 2)
            love.graphics.print("3) +5 Speed", 240, 320, 0, 2)
            love.graphics.print("4) +10% Attack Speed", 240, 360, 0, 2)
            love.graphics.print("5) Heal to full HP", 240, 400, 0, 2)
        else
            local restartText = "press R to restart or Q to quit"
            local restartTextWidth = (font:getWidth(restartText)) * 2

            local restartTextX = (windowWidth - restartTextWidth) / 2

            love.graphics.print(restartText, restartTextX , windowHeight / 2, 0, 2)
        end
    end

    love.graphics.setColor(1, 1, 1)
end

isPaused = false

function love.keypressed(key)
    if levelupMenuOpen then
        if key == "1" then applyPowerup("health") isPaused = false end
        if key == "2" then applyPowerup("damage") isPaused = false end
        if key == "3" then applyPowerup("speed") isPaused = false end
        if key == "4" then applyPowerup("shootingRate") isPaused = false end
        if key == "5" then applyPowerup("heal") isPaused = false end
        return
    end

    -- Pause toggle
    if key == "p" or key == "escape" then
        isPaused = not isPaused
    end

    if isPaused then
        if key == "r" then restartGame() end
        if key == "q" then love.window.close() love.audio.pause() end
    end

    if isDead then
        if key == "r" then restartGame() end
        if key == "q" then love.window.close() love.audio.pause() end
    end
end

function restartGame()
    mainCharacter.load() 
    enemyUnit.load() 
    projectile.projectiles = {}
    xp = 0
    time = 0
    spawnTimer = 0
    isPaused = false
end

function checkCollisions()
    local playerRadius = 6
    local enemyRadius = 6
    local collisionRadiusSumSquared = (playerRadius + enemyRadius) * (playerRadius + enemyRadius)

    if player.invincible == false then
        for i = #enemyUnit.enemies, 1, -1 do
            local e = enemyUnit.enemies[i] 

            local dx = player.x - e.x
            local dy = player.y - e.y
            local distanceSquared = (dx * dx) + (dy * dy)

            if distanceSquared < collisionRadiusSumSquared then
                
                player.health = player.health - e.dmg
                if player.health <= 0 then

                    local randomDeathSound = sounds.deathSounds[love.math.random(1, 5)]
                    randomDeathSound:play()

                    isDead = true
                    isPaused = true
                end
                
                player.invincible = true
                player.invincibleTimer = player.iframeDuration

                break 
            end
        end
    end
end

function spawnEnemiesAtRandomPositions()
    local numberOfEnemies = math.floor(time / 30) + love.math.random(1, 2)
    local playerX = player.x
    local playerY = player.y
    local spawnX = love.graphics.getWidth()
    local spawnY = love.graphics.getHeight()

    local cameraZoom = 4

    local screenW = love.graphics.getWidth() / cameraZoom
    local screenH = love.graphics.getHeight() / cameraZoom

    local spawnPadding = 50

    for i = 1, numberOfEnemies do
        while spawnX <= spawnPadding or spawnX >= screenW - spawnPadding do
            spawnX = love.math.random(0, love.graphics.getWidth())
        end

        while spawnY <= spawnPadding or spawnY >= screenH - spawnPadding do
            spawnY = love.math.random(0, love.graphics.getHeight())
        end

        spawnCordX = playerX + spawnX + love.math.random(1, 30)
        spawnCordY = playerY + spawnY + love.math.random(1, 30)

        enemyUnit.spawn(spawnCordX, spawnCordY)
    end
end

function mouseDown(button)
    local leftMouseButton = 1

    if button == leftMouseButton then 
        local arrowCooldown = player.arrowCooldown
        
        if cooldown <= 0 then
            local zoom = mainCharacter.zoom 
            local camX = mainCharacter.camX
            local camY = mainCharacter.camY
            local x = love.mouse.getX()
            local y = love.mouse.getY()
            
            local screenW = love.graphics.getWidth()
            local screenH = love.graphics.getHeight()
            
            local worldX = (x - screenW / 2) / zoom + camX
            local worldY = (y - screenH / 2) / zoom + camY
            
            projectile.spawn(worldX, worldY, player.projectileSpeed, player.dmg)
            cooldown = arrowCooldown
        end
    end
end

function checkLevelUp()
    if xp >= xpThreshold then
        xp = xp - xpThreshold 
        playerLevel = playerLevel + 1
        xpThreshold = math.floor(xpThreshold * 1.2)  
        levelupMenuOpen = true
        isPaused = true
    end
end

function applyPowerup(choice)
    if choice == "health" then
        player.maxHealth = player.maxHealth + 40
        player.health = playe.health + 40
    elseif choice == "damage" then
        player.dmg = player.dmg + 10
    elseif choice == "speed" then
        player.speed = player.speed + 5
    elseif choice == "heal" then
        player.health = player.maxHealth
    elseif choice == "shootingRate" then
        player.arrowCooldown = player.arrowCooldown - player.arrowCooldown / 10
    end

    levelupMenuOpen = false
end