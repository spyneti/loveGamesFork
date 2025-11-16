local score = 0
local spawnInterval = 2
local spawnTimer = 0 
local cooldown = 0

function love.load()
    require "mainCharacter"
    require "enemyUnit"

    mainCharacter.load()  
    enemyUnit.load() 

    love.graphics.setDefaultFilter("nearest", "nearest")
end

function love.update(dt) 
    mainCharacter.update(dt) 
    enemyUnit.update(dt)
    world:update(dt) 
    score = score + 1

    checkCollisions()

    spawnTimer = spawnTimer + dt
    
    if spawnTimer >= spawnInterval then
        spawnEnemiesAtRandomPositions()
        spawnTimer = 0
    end

    if love.mouse.isDown(1) then
        mouseDown(1)
    end
end

function love.draw()
    mainCharacter.draw()

    time = math.floor(love.timer.getTime())
    standardPadding = 10

    local scoreText = "SCORE: " .. score
    local font = love.graphics.getFont()
    local scoreTextWidth = (font:getWidth(scoreText)) * 2

    local timeText = "TIME: " .. time
    local TimeTextWidth = (font:getWidth(timeText)) * 2

    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()

    scoreTextX = standardPadding
    scoreTextY = standardPadding

    local timeTextX = windowWidth - TimeTextWidth - standardPadding
    local timeTextY = standardPadding

    love.graphics.print(scoreText, scoreTextX, scoreTextY, 0, 2 )
    love.graphics.print(timeText , timeTextX, timeTextY, 0, 2)

    -- debug player health
    love.graphics.print("health: " .. player.health , timeTextX - 300, timeTextY, 0, 2)
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
                    -- Reset player position and health
                    player.collider:setPosition(32, 32)
                    player.health = 100
                end
                
                player.invincible = true
                player.invincibleTimer = player.iframeDuration

                break 
            end
        end
    end
end

function spawnEnemiesAtRandomPositions()
    local numberOfEnemies = math.floor(score / 1000) + love.math.random(1, 3)
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
        local arrowCooldown = mainCharacter.arrowCooldown
        

        if cooldown >= 0 then
            cooldown = cooldown - love.timer.getDelta()
        else
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