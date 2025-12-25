enemyUnit = {}
enemyUnit.enemies = {}

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

    timeBuff = time / 10

    -- Simple collision box like the old version
    e.collider = world:newRectangleCollider(x, y, 40, 40)
    e.collider:setFixedRotation(true)
    e.collider:setCollisionClass('Enemy')

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
        left  = anim8.newAnimation(e.grid("1-6", 2), 0.2):flipH(),
        right = anim8.newAnimation(e.grid("1-6", 2), 0.2),
        attackRight = anim8.newAnimation(e.grid("1-6", 3), 0.1, "pauseAtEnd"),
        attackLeft  = anim8.newAnimation(e.grid("1-6", 3), 0.1, "pauseAtEnd"):flipH()
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

function getDirectionToPlayer(enemy)
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y

    local len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then
        dx = dx / len
        dy = dy / len
    end

    return dx, dy
end

function enemyUnit.update(dt)
    bossTime = bossTime + dt

    for i, e in ipairs(enemyUnit.enemies) do
        
        if e.isBoss then
            e.attackTimer = e.attackTimer + dt
            if e.attackTimer >= e.attackInterval then
                e.isAttacking = true
                e.attackTimer = 0

                if e.facing == "right" then
                    e.anim = e.animations.attackRight
                else
                    e.anim = e.animations.attackLeft
                end
                
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
                e.collider:setLinearVelocity(0, 0)  -- Stop when attacking
                
                if e.anim.status == "paused" then 
                    e.isAttacking = false
                    e.anim = e.animations.right 
                end
                
                e.anim:update(dt)
                goto continue
            end
        end
        
        if e.isAttacking then
            goto continue
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

        -- Move using physics like the old version
        local vx = dx * e.speed
        local vy = dy * e.speed
        
        e.collider:setLinearVelocity(vx, vy)
        
        -- Update position from collider
        e.x = e.collider:getX()
        e.y = e.collider:getY()

        e.anim:update(dt)

        ::continue::
    end  -- This ends the for loop

    for i = #enemyUnit.dynamites, 1, -1 do
        local d = enemyUnit.dynamites[i]
        d.timer = d.timer - dt

        if d.timer <= 0 then
            local dist = math.sqrt((d.x - player.x)^2 + (d.y - player.y)^2)
            
            if dist < d.radius then
                player.health = player.health - d.damage
                checkDeath()
            end

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
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.circle("fill", d.x, d.y, d.radius)
        
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.circle("line", d.x, d.y, d.radius)
        
        local percent = 1 - (d.timer / 5.0)
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.circle("fill", d.x, d.y, d.radius * percent)
    end

    love.graphics.setColor(1, 1, 1)
end

function checkCollisions()
    -- Since both player and enemies now have 40x40 colliders, we can use simpler check
    local collisionSize = 40
    local collisionDistanceSquared = collisionSize * collisionSize  -- 40 * 40 = 1600

    if player.invincible == false then
        for i = #enemyUnit.enemies, 1, -1 do
            local e = enemyUnit.enemies[i] 

            local dx = player.x - e.x
            local dy = player.y - e.y
            local distanceSquared = (dx * dx) + (dy * dy)

            if distanceSquared < collisionDistanceSquared then
                
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