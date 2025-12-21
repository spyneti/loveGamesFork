enemyUnit = {}
enemyUnit.enemies = {} -- A list to hold all enemies

local enemySpriteSheet
local tntSpriteSheet
local torchSpriteSheet

local bossTime = 0
local bossInterval = 50

function enemyUnit.spawn(x, y)
    local e = {}

    local spawningBoss = false

    if bossTime >= bossInterval then 
        spawningBoss = true
        bossTime = 0
    end

    e.collider = world:newRectangleCollider(x, y, 64, 64)
    e.collider:setFixedRotation(true)
    e.collider:setMass(1)

    timeBuff = time / 10

    e.x = x
    e.y = y

    local startingHealth = 20
    local startingSpeed = 200
    local startingDamage = 20
    local startingXp = 100
    
    if not spawningBoss then
        e.health = startingHealth + timeBuff
        e.speed = startingSpeed + timeBuff
        e.dmg = startingDamage + timeBuff
        e.xpGain = startingXp + (timeBuff * 2)
        e.spriteSheet = torchSpriteSheet 
        e.grid = anim8.newGrid(192, 192, e.spriteSheet:getWidth(), e.spriteSheet:getHeight())
        e.isBoss = false
    else 
        e.health = (startingHealth + timeBuff) * 5
        e.speed = (startingSpeed + timeBuff) * 0.5
        e.dmg = (startingDamage + timeBuff) * 5
        e.xpGain = (startingXp + (timeBuff * 2)) * 10
        e.spriteSheet = tntSpriteSheet
        e.grid = anim8.newGrid(192, 192, e.spriteSheet:getWidth(), e.spriteSheet:getHeight())
        e.isBoss = true
        e.attackTimer = 0
        e.attackInterval = 4
    end
    e.animations = {
        -- down  = anim8.newAnimation(e.grid("1-4", 1), 0.2),
        left  = anim8.newAnimation(e.grid("1-6", 2), 0.2):flipH(),
        right = anim8.newAnimation(e.grid("1-6", 2), 0.2),
        attackRight = anim8.newAnimation(e.grid("1-6", 3), 0.1, "pauseAtEnd"),
        attackLeft  = anim8.newAnimation(e.grid("1-6", 3), 0.1, "pauseAtEnd"):flipH()
        -- up    = anim8.newAnimation(e.grid("1-4", 4), 0.2)
    }
    e.facing = "right"
    e.anim = e.animations.right

    table.insert(enemyUnit.enemies, e)
end


function enemyUnit.load()
    enemyUnit.enemies = {}
    enemyUnit.dynamites = {}
    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    enemySpriteSheet = love.graphics.newImage("sprites/player-sheet.png")
    tntSpriteSheet = love.graphics.newImage("sprites/enemy-tnt.png")
    torchSpriteSheet = love.graphics.newImage("sprites/enemy-torch.png")
    time = 0
end

local function getDirectionToPlayer(enemy)
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y

    local len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then
        dx = dx / len
        dy = dy / len
    end

    local checkDistance = 60
    local checkX = enemy.x + dx * checkDistance
    local checkY = enemy.y + dy * checkDistance
    
    if not (isPositionOnWater and isPositionOnWater(checkX, checkY)) then
        return dx, dy  
    end

    for i = 0, 7 do
        local angle = i * math.pi / 4
        local testDx = math.cos(angle)
        local testDy = math.sin(angle)
        
        checkX = enemy.x + testDx * checkDistance
        checkY = enemy.y + testDy * checkDistance
        
        if not (isPositionOnWater and isPositionOnWater(checkX, checkY)) then
            return testDx, testDy
        end
    end

    local randomAngle = love.math.random() * 2 * math.pi
    return math.cos(randomAngle), math.sin(randomAngle)
end

function enemyUnit.update(dt)
    bossTime = bossTime + dt

    for i, e in ipairs(enemyUnit.enemies) do
        
        if e.isBoss then
            e.attackTimer = e.attackTimer + dt
            if e.attackTimer >= e.attackInterval then
                e.isAttacking = true
                e.attackTimer = 0 -- Reset timer

                if e.facing == "right" then
                    e.anim = e.animations.attackRight
                else
                    e.anim = e.animations.attackLeft
                end
                -- Create a new Dynamite objects
                local bigWeakDynamite = {
                    x = player.x + math.random(-100, 100), 
                    y = player.y + math.random(-100, 100),
                    timer = 1.5,       
                    radius = 60,       
                    damage = 30 + timeBuff      
                }
                local smallStrongDynamite = {
                    x = player.x + math.random(-80, 80), 
                    y = player.y + math.random(-80, 80),
                    timer = 1.5,       
                    radius = 30,       
                    damage = 60 + timeBuff      
                }
                local bigStrongdynamite = {
                    x = player.x + math.random(-155, 155), 
                    y = player.y + math.random(-155, 155),
                    timer = 4,       
                    radius = 75,       
                    damage = 75 + timeBuff      
                }
                table.insert(enemyUnit.dynamites, bigWeakDynamite)
                table.insert(enemyUnit.dynamites, smallStrongDynamite)
                table.insert(enemyUnit.dynamites, bigStrongdynamite)
            end

            if e.isAttacking then
                e.collider:setLinearVelocity(0, 0) 
                
                if e.anim.status == "paused" then 
                    e.isAttacking = false
                    e.anim = e.animations.right 
                end
                
                e.anim:update(dt)

                goto continue
            end
        end

        local dx, dy = getDirectionToPlayer(e)

        if math.abs(dx) > math.abs(dy) then
            if dx > 0 then 
                e.anim = e.animations.right
                e.facing = "right"
            else 
                e.anim = e.animations.left
                e.facing = "left"
            end
        else
            if dx > 0 and e.facing == "right" then
                e.anim = e.animations.right
            elseif dx > 0 and e.facing == "left" then
                e.anim = e.animations.left
            end
        end

        local vx = dx * e.speed
        local vy = dy * e.speed
    
        e.collider:setLinearVelocity(vx, vy)
      
        e.x = e.collider:getX()
        e.y = e.collider:getY()

        e.anim:update(dt)

        ::continue::

    end

    for i = #enemyUnit.dynamites, 1, -1 do
        local d = enemyUnit.dynamites[i]
        d.timer = d.timer - dt

        if d.timer <= 0 then
            -- Check distance between dynamite and player
            local dist = math.sqrt((d.x - player.x)^2 + (d.y - player.y)^2)
            
            if dist < d.radius then
                -- Assuming you have a player.takeDamage function
                player.health = player.health - d.damage
                checkDeath()
            end

            -- Remove dynamite from the list
            table.remove(enemyUnit.dynamites, i)
        end
    end
end

function enemyUnit.draw()
    for i, e in ipairs(enemyUnit.enemies) do
        local ox = 96
        local oy = 96
        if e.isBoss then 
            e.anim:draw(e.spriteSheet, e.x, e.y, 0, 1.5, 1.5, ox, oy)
        else 
            e.anim:draw(e.spriteSheet, e.x, e.y, 0, 1, 1, ox, oy)
        end
    end

    for i, d in ipairs(enemyUnit.dynamites) do
        -- Draw the "Zone" (Red Circle)
        -- We make it blink or fade based on the timer for effect
        love.graphics.setColor(1, 0, 0, 0.5) -- Red with 50% opacity
        love.graphics.circle("fill", d.x, d.y, d.radius)
        
        -- Draw an outline
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.circle("line", d.x, d.y, d.radius)
        
        -- Optional: Draw a smaller expanding circle to show when it will pop
        local percent = 1 - (d.timer / 5.0) -- Goes from 0 to 1
        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow
        love.graphics.circle("fill", d.x, d.y, d.radius * percent)
    end

    love.graphics.setColor(1, 1, 1) -- Reset color
end