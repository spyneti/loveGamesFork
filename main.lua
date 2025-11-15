local score = 3000

function love.load()
    require "mainCharacter"
    require "enemyUnit"

    mainCharacter.load()  
    enemyUnit.load() 

    spawnEnemyAtRandomPosition()
    love.graphics.setDefaultFilter("nearest", "nearest")
end

function love.update(dt)
    world:update(dt) 
    
    mainCharacter.update(dt) 
    enemyUnit.update(dt)
    score = score + 1

    checkCollisions()
end

function love.draw()
    mainCharacter.draw()

    time = math.floor(love.timer.getTime())
    local standardPadding = 10

    local scoreText = "SCORE: " .. score
    local font = love.graphics.getFont()
    local scoreTextWidth = (font:getWidth(scoreText)) * 2

    local timeText = "TIME: " .. time
    local TimeTextWidth = (font:getWidth(timeText)) * 2

    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()

    local scoreTextX = standardPadding
    local scoreTextY = standardPadding

    local timeTextX = windowWidth - TimeTextWidth - standardPadding
    local timeTextY = standardPadding

    love.graphics.print(scoreText, scoreTextX, scoreTextY, 0, 2 )
    love.graphics.print(timeText , timeTextX, timeTextY, 0, 2)
    love.graphics.print("health: " .. player.health , timeTextX - 300, timeTextY, 0, 2)
end


function checkCollisions()
    local playerRadius = 3
    local enemyRadius = 3
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


function spawnEnemyAtRandomPosition()
    numberOfEnemies = math.floor(score / 1000) + love.math.random(1, 3)
    spawnX = love.graphics.getWidth()
    spawnY = love.graphics.getHeight()

    screenW = love.graphics.getWidth() / 4
    screenH = love.graphics.getHeight() / 4

    while spawnX < 50 or spawnX > screenW - 50 do
        spawnX = love.math.random(0, love.graphics.getWidth())
    end

    while spawnY < 50 or spawnY > screenH - 50 do
        spawnY = love.math.random(0, love.graphics.getHeight())
    end

    for i = 1, numberOfEnemies do
        enemyUnit.spawn(spawnX, spawnY)
    end
end