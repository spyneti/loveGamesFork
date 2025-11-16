projectile = {}

projectile.projectiles = {}

function projectile.spawn(x, y, speed, dmg)
    local p = {}
    p.x = player.x
    p.y = player.y

    p.targetX = x
    p.targetY = y
    
    local dx = p.targetX - p.x
    local dy = p.targetY - p.y
    
    local len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then
        p.dirX = dx / len
        p.dirY = dy / len
    else
        p.dirX = 0
        p.dirY = 0
    end

    p.rotation = math.atan2(p.dirY, p.dirX)
    
    p.speed = speed
    p.dmg = dmg
    table.insert(projectile.projectiles, p)
end

function projectile.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    projectileImage = love.graphics.newImage("sprites/arrow.png")

end

function projectile.update(dt)
    -- Loop backwards for safe removal of projectiles
    for i = #projectile.projectiles, 1, -1 do
        local p = projectile.projectiles[i]

        p.x = p.x + p.dirX * p.speed * dt
        p.y = p.y + p.dirY * p.speed * dt
        
        local travelDistance = math.sqrt((p.x - player.x)^2 + (p.y - player.y)^2)
        if travelDistance > 500 then
            table.remove(projectile.projectiles, i)
            break
        end

        local projectileRadius = 3
        local enemyRadius = 6
        local collisionRadiusSumSquared = (projectileRadius + enemyRadius) * (projectileRadius + enemyRadius)

        local hitEnemy = false

        for j = #enemyUnit.enemies, 1, -1 do
            local e = enemyUnit.enemies[j] 
            
            -- Use sprite coordinates for collision check
            local dx = p.x - e.x
            local dy = p.y - e.y
            local distanceSquared = (dx * dx) + (dy * dy)

            if distanceSquared < collisionRadiusSumSquared then

                
                
                e.health = e.health - p.dmg 
                
                if e.health <= 0 then
                    xp = xp + e.xpGain
                    checkLevelUp()
                    table.remove(enemyUnit.enemies, j)
                end
                
                -- Mark projectile for removal
                hitEnemy = true
                break 
            end
        end

        if hitEnemy then
            table.remove(projectile.projectiles, i)
        end
    end
end
function projectile.draw()
    for i, p in ipairs(projectile.projectiles) do

        love.graphics.draw(projectileImage, p.x, p.y, p.rotation, 1, 1, 6, 9)
        
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.setColor(1, 1, 1)
end
