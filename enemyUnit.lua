enemyUnit = {}

local enemy = {}

function enemyUnit.load()
    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    enemy.x = 300
    enemy.y = 200
    enemy.speed = 100

    enemy.spriteSheet = love.graphics.newImage("sprites/player-sheet.png")
    enemy.grid = anim8.newGrid(12, 18, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight())

    enemy.animations = {
        down  = anim8.newAnimation(enemy.grid("1-4", 1), 0.2),
        left  = anim8.newAnimation(enemy.grid("1-4", 2), 0.2),
        right = anim8.newAnimation(enemy.grid("1-4", 3), 0.2),
        up    = anim8.newAnimation(enemy.grid("1-4", 4), 0.2)
    }

    enemy.anim = enemy.animations.left
end


-- Use the global player here (NOT mainCharacter.player)
local function getDirectionToPlayer()
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
    local dx, dy = getDirectionToPlayer()

    -- determine animation
    if math.abs(dx) > math.abs(dy) then
        enemy.anim = dx > 0 and enemy.animations.right or enemy.animations.left
    else
        enemy.anim = dy > 0 and enemy.animations.down or enemy.animations.up
    end

    enemy.x = enemy.x + dx * enemy.speed * dt
    enemy.y = enemy.y + dy * enemy.speed * dt

    enemy.anim:update(dt)
end


function enemyUnit.draw()
    enemy.anim:draw(enemy.spriteSheet, enemy.x, enemy.y, nil, 5)
end
