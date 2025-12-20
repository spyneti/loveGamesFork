enemyUnit = {}
enemyUnit.enemies = {} -- A list to hold all enemies

local enemySpriteSheet

local bossTime = 0

function enemyUnit.spawn(x, y)
    local e = {}

    local spawningBoss = false

    if bossTime >= 10 then 
        spawningBoss = true
        bossTime = 0
    end

    e.collider = world:newRectangleCollider(x, y, 6,7)
    e.collider:setFixedRotation(true)
    e.collider:setMass(1)

    timeBuff = time / 10

    e.x = x
    e.y = y

    local startingHealth = 20
    local startingSpeed = 100
    local startingDamage = 20
    local startingXp = 100
    
    if not spawningBoss then
        e.health = startingHealth + timeBuff
        e.speed = startingSpeed + timeBuff
        e.dmg = startingDamage + timeBuff
        e.xpGain = startingXp + (timeBuff * 2)
        e.spriteSheet = enemySpriteSheet 
        e.grid = anim8.newGrid(12, 18, e.spriteSheet:getWidth(), e.spriteSheet:getHeight())
        e.isBoss = false
    else 
        e.health = (startingHealth + timeBuff) * 5
        e.speed = (startingSpeed + timeBuff) * 0.5
        e.dmg = (startingDamage + timeBuff) * 5
        e.xpGain = (startingXp + (timeBuff * 2)) * 10
        e.spriteSheet = enemySpriteSheet 
        e.grid = anim8.newGrid(12, 18, e.spriteSheet:getWidth(), e.spriteSheet:getHeight())
        e.isBoss = true
    end
    e.animations = {
        down  = anim8.newAnimation(e.grid("1-4", 1), 0.2),
        left  = anim8.newAnimation(e.grid("1-4", 2), 0.2),
        right = anim8.newAnimation(e.grid("1-4", 3), 0.2),
        up    = anim8.newAnimation(e.grid("1-4", 4), 0.2)
    }
    e.anim = e.animations.left

    table.insert(enemyUnit.enemies, e)
end


function enemyUnit.load()
    enemyUnit.enemies = {}
    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    enemySpriteSheet = love.graphics.newImage("sprites/player-sheet.png")
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

    return dx, dy
end

function enemyUnit.update(dt)
    bossTime = bossTime + dt

    for i, e in ipairs(enemyUnit.enemies) do
        local dx, dy = getDirectionToPlayer(e)

        if math.abs(dx) > math.abs(dy) then
            e.anim = dx > 0 and e.animations.right or e.animations.left
        else
            e.anim = dy > 0 and e.animations.down or e.animations.up
        end

        local vx = dx * e.speed
        local vy = dy * e.speed
        
        -- Set velocity on the collider
        e.collider:setLinearVelocity(vx, vy)
        
        -- Update the sprite position from the collider position
        e.x = e.collider:getX()
        e.y = e.collider:getY()

        e.anim:update(dt)
    end
end

function enemyUnit.draw()
    for i, e in ipairs(enemyUnit.enemies) do
        love.graphics.setColor(0.7, 0, 0)
        if e.isBoss then 
            e.anim:draw(e.spriteSheet, e.x, e.y, 0, 2, 2, 6, 9)
        else 
            e.anim:draw(e.spriteSheet, e.x, e.y, 0, 1.33, 1.33, 6, 9)
        end
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.setColor(1, 1, 1) -- Reset color
end