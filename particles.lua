particles = {}
particles.list = {}

function particles.spawn(x, y, colorType)
    -- Spawn 8 to 12 particles per hit
    for i = 1, math.random(8, 12) do
        local p = {}
        p.x = x
        p.y = y
        
        -- Give them a random speed and direction (spread)
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 150)
        
        p.dx = math.cos(angle) * speed
        p.dy = math.sin(angle) * speed
        
        -- Life controls how long they last (0.3 to 0.6 seconds)
        p.life = math.random(3, 6) / 10
        p.maxLife = p.life
        
        -- Color setting (default to red for blood)
        p.color = {1, 0, 0} 
        if colorType == "spark" then p.color = {1, 1, 0.8} end
        
        table.insert(particles.list, p)
    end
end

function particles.update(dt)
    for i = #particles.list, 1, -1 do
        local p = particles.list[i]
        
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.life = p.life - dt
        
        if p.life <= 0 then
            table.remove(particles.list, i)
        end
    end
end

function particles.draw()
    for _, p in ipairs(particles.list) do
        -- Calculate opacity (alpha) based on remaining life
        local alpha = p.life / p.maxLife
        
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        
        -- Draw a tiny square (2x2 pixels)
        love.graphics.rectangle("fill", p.x, p.y, 8, 8)
    end
    -- Reset color so other things don't look transparent
    love.graphics.setColor(1, 1, 1, 1)
end