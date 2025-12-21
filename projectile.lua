projectile = {}
projectile.projectiles = {}

function projectile.spawn(x, y, speed, dmg, pierce)
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
    
    p.pierce = pierce -- how many enemies it can hit before dying
    p.hitList = {}   -- a list to remember enemies we already hit
    
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
        
        -- Distance cleanup
        local travelDistance = math.sqrt((p.x - player.x)^2 + (p.y - player.y)^2)
        if travelDistance > 500 then
            table.remove(projectile.projectiles, i)
            -- We use goto to skip the rest of the loop for this removed projectile
            goto continue 
        end

        local projectileRadius = 3
        local enemyRadius = 9

        -- Loop through enemies
        for j = #enemyUnit.enemies, 1, -1 do
            local e = enemyUnit.enemies[j] 

            if e.isBoss then 
                local enemyRadius = 30
            end
            
            local collisionRadiusSumSquared = (projectileRadius + enemyRadius) * (projectileRadius + enemyRadius)
            
            -- Only check collision if we haven't hit this specific enemy yet
            if not p.hitList[e] then
            
                local dx = p.x - e.x
                local dy = p.y - e.y
                local distanceSquared = (dx * dx) + (dy * dy)

                if distanceSquared < collisionRadiusSumSquared then
                    
                    -- mark as hit so we dont hit them again next frame
                    p.hitList[e] = true

                    particles.spawn(e.x, e.y, "blood")

                    e.health = e.health - p.dmg
                    -- reduce pierce count
                    p.pierce = p.pierce - 1

                    -- Enemy Death Logic
                    if e.health <= 0 then
                        xp = xp + e.xpGain
                        checkLevelUp()
                        table.remove(enemyUnit.enemies, j)
                    end
                    
                    -- if the projectile ran out of pierce power, break the enemy loop
                    if p.pierce <= 0 then
                        break 
                    end
                end
            end
        end

        if p.pierce <= 0 then
            table.remove(projectile.projectiles, i)
        end

        ::continue::
    end
end

function projectile.draw()
    for i, p in ipairs(projectile.projectiles) do
        love.graphics.draw(projectileImage, p.x, p.y, p.rotation, 0.3, 0.3, 6, 9)
    end
    love.graphics.setColor(1, 1, 1)
end