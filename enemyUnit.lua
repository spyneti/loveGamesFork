enemyUnit = {}
enemyUnit.enemies = {} -- A list to hold all enemies

local enemySpriteSheet

function enemyUnit.spawn(x, y)
    local e = {}

    -- Collider setup (assuming 12x18 sprite size, like the player)
    e.collider = world:newRectangleCollider(x, y, 6, 7)
    e.collider:setFixedRotation(true)
    e.collider:setMass(1) -- Give it mass so it can be moved

    e.x = x
    e.y = y
    e.speed = 100
    e.dmg = 50
    e.spriteSheet = enemySpriteSheet 
    e.grid = anim8.newGrid(12, 18, e.spriteSheet:getWidth(), e.spriteSheet:getHeight())

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
    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    enemySpriteSheet = love.graphics.newImage("sprites/player-sheet.png")

end

local function getDirectionToPlayer(enemy)
    -- We assume 'player' is available
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
        e.anim:draw(e.spriteSheet, e.x, e.y, 0, 1.33, 1.33, 6, 9)

        -- love.graphics.setColor(0, 1, 0, 0.5) -- Semi-transparent green for hitbox
        -- e.collider:draw('line')

        -- Debug circle for the center
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", e.x, e.y, 1)

        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.setColor(1, 1, 1) -- Reset color
end