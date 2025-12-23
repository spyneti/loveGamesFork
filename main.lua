time = 0
playerLevel = 1
xp = 0
xpThreshold = 1000
bestTime = 0
newRecord = false

local spawnTimer = 0
local enemySpawnInterval = 1
local cooldown = 0
local isDead = false

levelupMenuOpen = false
powerupChoice = nil

function love.load()

    love.window.maximize()
    loadBestTime()

    require "mainCharacter"
    require "enemyUnit"
    require "particles"
    crate = require "crate"
    decorations = require "decorations"

    mainCharacter.load()  

    _G.gameMap = mainCharacter.gameMap or gameMap
    
    if _G.gameMap then
        decorations.load(_G.gameMap)
        print("✓ Decorations loaded with map")
    else
        print("❌ ERROR: No gameMap found for decorations!")
    end
    
    enemyUnit.load() 
    crate.load()
    

    local cursorData = love.image.newImageData("sprites/cursor.png")

    local customCursor = love.mouse.newCursor(cursorData, 0, 0)

    love.mouse.setCursor(customCursor)

    healthBarFrame = love.graphics.newImage("sprites/HealthBar-Base.png")
    healthBarFill = love.graphics.newImage("sprites/HealthBar-Fill.png")
    xpBarFill = love.graphics.newImage("sprites/XPBar-Fill.png")

    barOffset = { x = 6, y = 6 }

    barMaxWidth = healthBarFill:getWidth()
    barHeight = healthBarFill:getHeight()

    healthQuad = love.graphics.newQuad(0, 0, barMaxWidth, barHeight, healthBarFill:getWidth(), healthBarFill:getHeight())

    xpQuad = love.graphics.newQuad(0, 0, barMaxWidth, barHeight, healthBarFill:getWidth(), healthBarFill:getHeight())

    buttons = {}
    hoverSound = love.audio.newSource("menu/menu sound effect-sfx.mp3", "static")
    clickSound = love.audio.newSource("menu/menu sellect sfx.mp3", "static")

    hoverSound:setVolume(0.05) 
    clickSound:setVolume(0.05)

    love.graphics.setDefaultFilter("nearest", "nearest")

    sounds = {}

    sounds.musicList = {
        love.audio.newSource("music/pixel field.mp3", "stream"),
        love.audio.newSource("music/pixel grass.mp3", "stream"),
        love.audio.newSource("music/pixel tree.mp3", "stream")
    }

    for _, s in pairs(sounds.musicList) do
        s:setLooping(false)
        s:setVolume(0.05)
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
        crate.update(dt)
        decorations.update(dt)
        world:update(dt) 

        checkCollisions()
        crate.checkPlayerCollision()

        spawnTimer = spawnTimer + dt
        
        if spawnTimer >= enemySpawnInterval then
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
    decorations.draw()
    mainCharacter.draw()
    crate.drawTextEffects()
    crate.drawBonusTimers()

    local standardPadding = 10
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    local font = love.graphics.getFont()

    local xpText = "XP: " .. math.floor(xp)
    local xpTextY = standardPadding
    love.graphics.print(xpText, standardPadding, standardPadding, 0, 2)

    local timeText = "TIME: " .. math.floor(time) .. "s"
    local timeTextWidth = font:getWidth(timeText) * 2
    local timeTextX = (windowWidth - timeTextWidth) / 2 
    local timeTextY = standardPadding

    local bestTimeText = "BEST: " .. math.floor(bestTime) .. "s"
    local bestTimeWidth = font:getWidth(bestTimeText) * 2
    local bestTimeX = windowWidth - bestTimeWidth - standardPadding
    local bestTimeY = standardPadding

    love.graphics.print(timeText, timeTextX, timeTextY, 0, 2)
    love.graphics.print(bestTimeText, bestTimeX, bestTimeY, 0, 2)

    local padding = 10
    local baseX = padding
    local baseY = love.graphics.getHeight() - 150

    local healthPct = math.max(0, player.health / player.maxHealth)

    local xpPct = math.max(0, xp / xpThreshold)

    healthQuad:setViewport(0, 0, barMaxWidth * healthPct, barHeight)

    xpQuad:setViewport(0, 0, barMaxWidth * xpPct, barHeight)


    --health bar

    love.graphics.draw(healthBarFrame, -35, xpTextY)

    love.graphics.draw(healthBarFill, healthQuad, baseX + barOffset.x, xpTextY + 20)

    love.graphics.print(math.floor(player.health) .. "/" .. player.maxHealth, baseX + barOffset.x, xpTextY + 24)

    --xp bar

    love.graphics.draw(healthBarFrame, -35, xpTextY + barHeight + padding * 3)

    local xpTextX = standardPadding
    love.graphics.draw(xpBarFill, xpQuad, xpTextX + barOffset.x, xpTextY + barHeight + padding * 3 + 20)

    love.graphics.print(math.floor(xp) .. "/" .. xpThreshold, baseX + barOffset.x, xpTextY + barHeight + padding * 3 + 24)

    love.graphics.print("damage: " .. player.dmg, baseX, baseY + 40, 0, 2)
    love.graphics.print("speed: " .. player.speed, baseX, baseY + 80, 0, 2)
    love.graphics.print("attack speed: " .. player.arrowCooldown,   baseX, baseY + 120, 0, 2)

    if isPaused then
        local windowWidth = love.graphics.getWidth()
        local windowHeight = love.graphics.getHeight()

        if levelupMenuOpen then
            -- LEVEL UP MENU
            local menuWidth = 450
            local menuHeight = 400
            local menuX = (windowWidth - menuWidth) / 2
            local menuY = (windowHeight - menuHeight) / 2
            
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)

            local titleText = "LEVEL UP! Choose a power-up:"
            local titleWidth = font:getWidth(titleText) * 2
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(titleText, menuX + (menuWidth - titleWidth)/2, menuY + 30, 0, 2)

            local buttonX = menuX + 40
            local buttonY = menuY + 90
            local buttonWidth = menuWidth - 80
            local buttonHeight = 40

            drawButton("+40 Max Health", buttonX, buttonY, buttonWidth, buttonHeight, 
                      powerupChoice == "health")
            drawButton("+10 Damage", buttonX, buttonY + 50, buttonWidth, buttonHeight,
                      powerupChoice == "damage")
            drawButton("+5 Speed", buttonX, buttonY + 100, buttonWidth, buttonHeight,
                      powerupChoice == "speed")
            drawButton("+10% Attack Speed", buttonX, buttonY + 150, buttonWidth, buttonHeight,
                      powerupChoice == "shootingRate")
            drawButton("Heal to full HP", buttonX, buttonY + 200, buttonWidth, buttonHeight,
                      powerupChoice == "heal")
            drawButton("+1 Piercing", buttonX, buttonY + 250, buttonWidth, buttonHeight,
                      powerupChoice == "piercing")
        else
            -- REGULAR PAUSE MENU OR DEATH MENU
            if isDead then
                -- DEATH MENU (shows survival time)
                local menuWidth = 400
                local menuHeight = 250 
                local menuX = (windowWidth - menuWidth) / 2
                local menuY = (windowHeight - menuHeight) / 2
                    
                love.graphics.setColor(0, 0, 0, 0.7)
                love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)

                local buttonWidth = 300
                local buttonX = menuX + (menuWidth - buttonWidth) / 2

                love.graphics.setColor(1, 1, 1)
                local survivedText = "You survived: " .. math.floor(time) .. " seconds"
                local survivedWidth = font:getWidth(survivedText) * 1.5
                love.graphics.print(survivedText, menuX + (menuWidth - survivedWidth)/2, menuY + 30, 0, 1.5)

                if newRecord then
                    local recordText = "NEW RECORD!"
                    local recordWidth = font:getWidth(recordText) * 1.5
                    love.graphics.setColor(1, 1, 0) 
                    love.graphics.print(recordText, menuX + (menuWidth - recordWidth)/2, menuY + 60, 0, 1.5)
                    love.graphics.setColor(1, 1, 1) 
                end
                
                drawButton("RESTART", buttonX, menuY + 100, buttonWidth, 50, powerupChoice == "restart")
                drawButton("QUIT", buttonX, menuY + 170, buttonWidth, 50, powerupChoice == "quit")     
            else
                -- NORMAL PAUSE MENU
                local menuWidth = 400
                local menuHeight = 200
                local menuX = (windowWidth - menuWidth) / 2
                local menuY = (windowHeight - menuHeight) / 2
                    
                love.graphics.setColor(0, 0, 0, 0.7)
                love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)

                local buttonWidth = 300
                local buttonX = menuX + (menuWidth - buttonWidth) / 2
                    
                drawButton("RESTART", buttonX, menuY + 40, buttonWidth, 50, powerupChoice == "restart")
                drawButton("QUIT", buttonX, menuY + 120, buttonWidth, 50, powerupChoice == "quit")
            end
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
        if key == "6" then applyPowerup("piercing") isPaused = false end
        return
    end

    if not isDead then
        if key == "p" or key == "escape" then
         isPaused = not isPaused
        end

        if isPaused then
            if key == "r" then restartGame() end
            if key == "q" then love.event.quit() end
        end
    end
   
    if isDead then
        if key == "r" then restartGame() end
        if key == "q" then love.event.quit() end
    end
end

function restartGame()
    mainCharacter.load() 
    enemyUnit.load() 
    crate.load()
    projectile.projectiles = {}
    xp = 0
    time = 0
    newRecord = false
    spawnTimer = 0
    isDead = false
    isPaused = false
end

function checkCollisions()
    local playerRadius = 35
    local enemyRadius = 40
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

                    if time > bestTime then
                        bestTime = time
                        newRecord = true
                        saveBestTime() 
                        print("NEW RECORD! " .. math.floor(time) .. " seconds!")
                    else
                        newRecord = false
                    end
                end
                checkDeath()
                
                player.invincible = true
                player.invincibleTimer = player.iframeDuration

                break 
            end
        end
    end
end

function isPositionOnWater(x, y)
    if not gameMap then
        return false
    end
    
    -- Convert world coordinates to tile coordinates
    local tileX = math.floor(x / gameMap.tilewidth) + 1
    local tileY = math.floor(y / gameMap.tileheight) + 1
    
    -- Check water layer
    local waterLayer = gameMap.layers["water"]
    if waterLayer then
        -- Check if there's a water tile at this position
        if waterLayer.data[tileY] and waterLayer.data[tileY][tileX] then
            local tile = waterLayer.data[tileY][tileX]
            if tile and tile.gid and tile.gid > 0 then
                return true  -- Position is on water
            end
        end
    end
    
    -- Also check water shadow layer if it exists
    local waterShadowLayer = gameMap.layers["water shadow"]
    if waterShadowLayer then
        if waterShadowLayer.data[tileY] and waterShadowLayer.data[tileY][tileX] then
            local tile = waterShadowLayer.data[tileY][tileX]
            if tile and tile.gid and tile.gid > 0 then
                return true  -- Position is on water shadow
            end
        end
    end
    
    return false  -- Not on water
end

function checkDeath()
    if player.health <= 0 then
        local randomDeathSound = sounds.deathSounds[love.math.random(1, 5)]
        randomDeathSound:play()

        isDead = true
        isPaused = true
    end
end

function spawnEnemiesAtRandomPositions()
    local numberOfEnemies = math.floor(time / 30) + love.math.random(1, 2)
    local playerX = player.x
    local playerY = player.y
    
    local cameraZoom = 4
    local screenW = love.graphics.getWidth() / cameraZoom
    local screenH = love.graphics.getHeight() / cameraZoom
    
    local maxAttempts = 20
    
    for i = 1, numberOfEnemies do
        local spawnCordX, spawnCordY
        local validSpawn = false
        local attempts = 0

        while not validSpawn and attempts < maxAttempts do
            attempts = attempts + 1

            local minDistanceFromPlayer = 300 
            local maxDistanceFromPlayer = 500 

            local angle = love.math.random() * 2 * math.pi
            local distance = love.math.random(minDistanceFromPlayer, maxDistanceFromPlayer)
            
            spawnCordX = playerX + math.cos(angle) * distance
            spawnCordY = playerY + math.sin(angle) * distance

            local mapWorldW = gameMap.width * gameMap.tilewidth
            local mapWorldH = gameMap.height * gameMap.tileheight
            
            local spawnPadding = 50
            spawnCordX = math.max(spawnPadding, math.min(spawnCordX, mapWorldW - spawnPadding))
            spawnCordY = math.max(spawnPadding, math.min(spawnCordY, mapWorldH - spawnPadding))

            if not isPositionOnWater(spawnCordX, spawnCordY) then
                local dx = spawnCordX - playerX
                local dy = spawnCordY - playerY
                local actualDistance = math.sqrt(dx*dx + dy*dy)
                
                if actualDistance >= minDistanceFromPlayer then
                    validSpawn = true
                end
            end
        end
        
        if validSpawn then
            enemyUnit.spawn(spawnCordX, spawnCordY)
        else
            local fallbackDistance = 400
            local fallbackAngle = love.math.random() * 2 * math.pi
            spawnCordX = playerX + math.cos(fallbackAngle) * fallbackDistance
            spawnCordY = playerY + math.sin(fallbackAngle) * fallbackDistance

            local mapWorldW = gameMap.width * gameMap.tilewidth
            local mapWorldH = gameMap.height * gameMap.tileheight
            spawnCordX = math.max(50, math.min(spawnCordX, mapWorldW - 50))
            spawnCordY = math.max(50, math.min(spawnCordY, mapWorldH - 50))
            
            enemyUnit.spawn(spawnCordX, spawnCordY)
        end
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
            
            projectile.spawn(worldX, worldY, player.projectileSpeed, player.dmg, player.pierce)
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
        player.health = player.health + 40
    elseif choice == "damage" then
        player.dmg = player.dmg + 10
    elseif choice == "speed" then
        player.speed = player.speed + 5
    elseif choice == "heal" then
        player.health = player.maxHealth
    elseif choice == "shootingRate" then
        player.arrowCooldown = player.arrowCooldown - player.arrowCooldown / 10
    elseif choice == "piercing" then
        player.pierce = player.pierce + 1
    end

    levelupMenuOpen = false
end

function drawButton(text, x, y, width, height, isHovered)
    if isHovered then
        love.graphics.setColor(0.3, 0.3, 0.8, 0.9)
    else
        love.graphics.setColor(0.2, 0.2, 0.6, 0.8)
    end
    love.graphics.rectangle("fill", x, y, width, height, 5)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", x, y, width, height, 5)

    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text) * 2
    local textHeight = font:getHeight() * 2
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, x + (width - textWidth)/2, y + (height - textHeight)/2, 0, 2)
end

local lastChoice = nil

function love.mousemoved(x, y, dx, dy)
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    local currentChoice = nil

    if levelupMenuOpen then
        local menuWidth = 450
        local menuHeight = 400
        local menuX = (windowWidth - menuWidth) / 2
        local menuY = (windowHeight - menuHeight) / 2
        
        local buttonX = menuX + 40
        local buttonY = menuY + 90 
        local buttonWidth = menuWidth - 80 
        local buttonHeight = 40
        
        currentChoice = nil
        
        if x >= buttonX and x <= buttonX + buttonWidth then
            if y >= buttonY and y <= buttonY + 40 then
                currentChoice = "health"
            elseif y >= buttonY + 50 and y <= buttonY + 90 then
                currentChoice = "damage"
            elseif y >= buttonY + 100 and y <= buttonY + 140 then
                currentChoice = "speed"
            elseif y >= buttonY + 150 and y <= buttonY + 190 then
                currentChoice = "shootingRate"
            elseif y >= buttonY + 200 and y <= buttonY + 240 then
                currentChoice = "heal"
            elseif y >= buttonY + 250 and y <= buttonY + 290 then
                currentChoice = "piercing"
            end
        end
    elseif isPaused and not levelupMenuOpen then
        local menuWidth = 400
        local menuHeight = isDead and 250 or 200
        local menuX = (windowWidth - menuWidth) / 2
        local menuY = (windowHeight - menuHeight) / 2
        
        local buttonWidth = 300
        local buttonX = menuX + (menuWidth - buttonWidth) / 2
        
        currentChoice = nil
        if x >= buttonX and x <= buttonX + buttonWidth then
            if isDead then
                if y >= menuY + 100 and y <= menuY + 150 then  
                    currentChoice = "restart"
                elseif y >= menuY + 170 and y <= menuY + 220 then 
                    currentChoice = "quit"
                end
            else
                if y >= menuY + 40 and y <= menuY + 90 then  
                    currentChoice = "restart"
                elseif y >= menuY + 120 and y <= menuY + 170 then 
                    currentChoice = "quit"
                end
            end
        end
    end

     if currentChoice and currentChoice ~= lastChoice then
        hoverSound:stop()
        hoverSound:play() 
    end
    
    powerupChoice = currentChoice
    lastChoice = currentChoice 
end

function love.mousepressed(x, y, button)
    if button == 1 then 
        if levelupMenuOpen then
            if powerupChoice then
                clickSound:stop()  
                clickSound:play()   
                applyPowerup(powerupChoice)
                levelupMenuOpen = false
                isPaused = false
                powerupChoice = nil
                lastChoice = nil  
            end
        elseif isPaused and not levelupMenuOpen then
            if powerupChoice == "restart" then
                clickSound:stop()
                clickSound:play()
                restartGame()
            elseif powerupChoice == "quit" then
                clickSound:stop()
                clickSound:play()
                love.event.quit()
            end
        end
    end
end

function loadBestTime()
    if love.filesystem.getInfo("besttime.txt") then
        local contents = love.filesystem.read("besttime.txt")
        bestTime = tonumber(contents) or 0
    else
        bestTime = 0
    end
end

function saveBestTime()
    love.filesystem.write("besttime.txt", tostring(bestTime))
end