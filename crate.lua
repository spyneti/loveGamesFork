local crate = {}
crate.activeBonuses = {}
crate.particleTexts = {}
crate.crates = {}
crate.spawnTimer = 0
crate.spawnInterval = 2

crate.types = {
    {
        name = "Health crate",
        color = {1, 0.3, 0.3}, -- Red
        reward = "health",
        value = 50
    },
    {
        name = "Damage crate", 
        color = {1, 0.5, 0}, -- Orange
        reward = "damage",
        value = 20
    },
    {
        name = "Speed crate",
        color = {0.3, 0.3, 1}, -- Blue
        reward = "speed", 
        value = 10
    },
    {
        name = "XP crate",
        color = {0.5, 0, 0.8}, -- Purple
        reward = "xp",
        value = 500
    }
}

function crate.load()
    crate.crates = {}
    crate.particleTexts = {}
    crate.activeBonuses = {}
    crate.spawnTimer = 0
    
    crate.spriteSheet = love.graphics.newImage("sprites/crates.png")
    
    local sheetWidth = 52   
    local sheetHeight = 70  
    
    crate.crateQuad = love.graphics.newQuad(
        19,   
        19,   
        32,   
        32,   
        sheetWidth, 
        sheetHeight   
    )

    crate.spriteWidth = 32
    crate.spriteHeight = 32
end

function crate.update(dt)
    if not isPaused then
        crate.spawnTimer = crate.spawnTimer + dt

        if crate.spawnTimer >= crate.spawnInterval then
            crate.spawnRandomcrate()
            crate.spawnTimer = 0
        end

        crate.updateTextEffects(dt)
        crate.updateBonuses(dt)
    end
end

function crate.spawnRandomcrate()
    local playerX = player.x
    local playerY = player.y
 
    local screenW = love.graphics.getWidth() / 4
    local screenH = love.graphics.getHeight() / 4
 
    local spawnRangeX = screenW * 0.8  
    local spawnRangeY = screenH * 0.8 
    
    local spawnX = playerX + love.math.random(-spawnRangeX/2, spawnRangeX/2)
    local spawnY = playerY + love.math.random(-spawnRangeY/2, spawnRangeY/2)
    
    local crateType = crate.types[love.math.random(1, #crate.types)]
    
    table.insert(crate.crates, {
        x = spawnX,
        y = spawnY,
        width = crate.spriteWidth,   
        height = crate.spriteHeight,  
        type = crateType,
        collected = false
    })
end

function crate.draw()
    local scale = 0.3 
    for i, c in ipairs(crate.crates) do
        if not c.collected then
            if crate.spriteSheet and crate.crateQuad then
                love.graphics.setColor(c.type.color)
                love.graphics.draw(crate.spriteSheet, crate.crateQuad, 
                    c.x - (c.width * scale)/2,  
                    c.y - (c.height * scale)/2, 
                    0,
                    scale, scale) 
            else
                love.graphics.setColor(c.type.color)
                love.graphics.rectangle("fill", 
                    c.x - (c.width * scale)/2,  
                    c.y - (c.height * scale)/2,
                    c.width * scale,  
                    c.height * scale) 
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function crate.drawBonusTimers()
    local yPos = 200 
    for i, bonus in ipairs(crate.activeBonuses) do
        local text = ""
        if bonus.type == "damage" then
            text = "Damage +" .. bonus.value .. ": " .. math.ceil(bonus.timer) .. "s"
        elseif bonus.type == "speed" then
            text = "Speed +" .. bonus.value .. ": " .. math.ceil(bonus.timer) .. "s"
        elseif bonus.type == "health" then
            text = "Health +" .. bonus.value .. ": " .. math.ceil(bonus.timer) .. "s"
        end
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(text, 10, yPos, 0, 1.5)
        yPos = yPos + 25
    end
end

function crate.checkPlayerCollision()
    local playerRadius = 12
    local crateRadius = 6
    
    for i = #crate.crates, 1, -1 do
        local c = crate.crates[i]
        
        if not c.collected then
            local dx = player.x - c.x
            local dy = player.y - c.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < (playerRadius + crateRadius) then
                crate.applyReward(c.type, c.x, c.y)
                c.collected = true
                table.remove(crate.crates, i)
                return true
            end
        end
    end
    return false
end

function crate.applyReward(crateType, x, y)
    local rewardText = ""

    if crateType.reward == "xp" then
        xp = xp + crateType.value
        rewardText = "+" .. crateType.value .. " XP!"
        checkLevelUp()
    else
        local bonus = {
            type = crateType.reward,
            value = crateType.value,
            timer = 20,
            originalValue = nil
        }
    
    if crateType.reward == "health" then
            player.health = math.min(player.health + crateType.value, player.maxHealth)
            rewardText = "+" .. crateType.value .. " Health! (20s)"
            bonus.originalValue = nil  -- Health is instant, not temporary stat
        elseif crateType.reward == "damage" then
            bonus.originalValue = player.dmg
            player.dmg = player.dmg + crateType.value
            rewardText = "+" .. crateType.value .. " Damage! (20s)"
        elseif crateType.reward == "speed" then
            bonus.originalValue = player.speed
            player.speed = player.speed + crateType.value
            rewardText = "+" .. crateType.value .. " Speed! (20s)"
        end

         table.insert(crate.activeBonuses, bonus)
    end

    print("Collected " .. crateType.name .. ": " .. rewardText)
    
    if x and y then
        local camX = mainCharacter.camX
        local camY = mainCharacter.camY
        local zoom = mainCharacter.zoom
        local screenX = (x - camX) * zoom + love.graphics.getWidth() / 2
        local screenY = (y - camY) * zoom + love.graphics.getHeight() / 2
        crate.createTextEffect(screenX, screenY, rewardText)
    end
end

function crate.createTextEffect(x, y, text)
    table.insert(crate.particleTexts, {
        x = x,
        y = y,
        text = text,
        lifetime = 1.5,
        alpha = 1
    })
end

function crate.updateTextEffects(dt)
    for i = #crate.particleTexts, 1, -1 do
        local effect = crate.particleTexts[i]
        effect.lifetime = effect.lifetime - dt
        effect.y = effect.y - 60 * dt
        effect.alpha = effect.lifetime / 1.5
        
        if effect.lifetime <= 0 then
            table.remove(crate.particleTexts, i)
        end
    end
end

function crate.drawTextEffects()
    for _, effect in ipairs(crate.particleTexts) do
        love.graphics.setColor(1, 1, 1, effect.alpha)
        love.graphics.print(effect.text, effect.x, effect.y, 0, 1.5)
    end
    love.graphics.setColor(1, 1, 1)
end

function crate.updateBonuses(dt)
    if not isPaused then
        for i = #crate.activeBonuses, 1, -1 do
            local bonus = crate.activeBonuses[i]
            bonus.timer = bonus.timer - dt

            if bonus.timer <= 0 then
                if bonus.type == "damage" and bonus.originalValue then
                    player.dmg = bonus.originalValue
                    print("Damage bonus expired!")
                elseif bonus.type == "speed" and bonus.originalValue then
                    player.speed = bonus.originalValue
                    print("Speed bonus expired!")
                end
                
                table.remove(crate.activeBonuses, i)
            end
        end
    end
end

return crate