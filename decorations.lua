local Decorations = {}
Decorations.objects = {}

function Decorations.load(map)
    Decorations.objects = {}

    Decorations.sprites = {
        bush = love.graphics.newImage("maps/Bushe1.png"),
        rock = love.graphics.newImage("maps/Water Rocks_01.png"),
        duck = love.graphics.newImage("maps/Rubber duck.png")
    }
    
    print("=== ACTUAL SPRITE SHEET SIZES ===")
    for name, sprite in pairs(Decorations.sprites) do
        print(name .. ": " .. sprite:getWidth() .. "x" .. sprite:getHeight())
    end

    Decorations.grids = {
 
        bush = anim8.newGrid(128, 128, Decorations.sprites.bush:getWidth(), Decorations.sprites.bush:getHeight()),

        rock = anim8.newGrid(64, 64, Decorations.sprites.rock:getWidth(), Decorations.sprites.rock:getHeight()),

        duck = anim8.newGrid(32, 32, Decorations.sprites.duck:getWidth(), Decorations.sprites.duck:getHeight())
    }

    Decorations.animations = {
        bush = anim8.newAnimation(Decorations.grids.bush('1-8', 1), 0.15), 
        rock = anim8.newAnimation(Decorations.grids.rock('1-16', 1), 0.1),  
        duck = anim8.newAnimation(Decorations.grids.duck('1-3', 1), 0.2)  
    }

    local bushFrames = Decorations.sprites.bush:getWidth() / 128  
    local rockFrames = Decorations.sprites.rock:getWidth() / 64   
    local duckFrames = Decorations.sprites.duck:getWidth() / 32  
    
    print("Calculated frames:")
    print("  Bush: " .. bushFrames .. " frames of 128×128")
    print("  Rock: " .. rockFrames .. " frames of 64×64")
    print("  Duck: " .. duckFrames .. " frames of 32×32")

    Decorations.frameData = {
        bush = {width = 128, height = 128, scale = 1}, 
        rock = {width = 64, height = 64, scale = 2},     
        duck = {width = 32, height = 32, scale = 2}      
    }

    local layerNames = {"bushes", "rocks", "ducks"}
    
    for _, layerName in ipairs(layerNames) do
        local layer = map.layers[layerName]
        
        if layer then
            print("Loading " .. layerName .. ": " .. #layer.objects .. " objects")
            
            for i, obj in ipairs(layer.objects) do
                local objType
                if layerName == "bushes" then objType = "bush"
                elseif layerName == "rocks" then objType = "rock"
                elseif layerName == "ducks" then objType = "duck"
                end

                local data = Decorations.frameData[objType]

                local x = obj.x
                local y = obj.y

                table.insert(Decorations.objects, {
                    x = x,
                    y = y,
                    type = objType,
                    width = data.width,
                    height = data.height,
                    scale = data.scale,
                    originalX = x,
                    originalY = y,
                    bobTimer = math.random() * 6.28,
                    bobSpeed = math.random(0.5, 1.5),
                    bobHeight = math.random(2, 8)
                })
                
                print("  " .. objType .. " at " .. x .. "," .. y)
            end
        end
    end
    
    print("Total decorations: " .. #Decorations.objects)
end

function Decorations.update(dt)
    for _, anim in pairs(Decorations.animations) do
        anim:update(dt)
    end

    for i, obj in ipairs(Decorations.objects) do
        obj.bobTimer = obj.bobTimer + dt * obj.bobSpeed

        if obj.type == "duck" then
            obj.y = obj.originalY + math.sin(obj.bobTimer) * 5
            obj.x = obj.originalX + math.cos(obj.bobTimer * 0.5) * 3
            
        elseif obj.type == "rock" then
            obj.y = obj.originalY + math.sin(obj.bobTimer * 1.5) * 2
            
        elseif obj.type == "bush" then
            obj.x = obj.originalX + math.sin(obj.bobTimer * 0.8) * 1
        end
    end
end

function Decorations.draw()
    for i, obj in ipairs(Decorations.objects) do
        local sprite = Decorations.sprites[obj.type]
        local anim = Decorations.animations[obj.type]
        local data = Decorations.frameData[obj.type]
        
        if sprite and anim then
            -- Calculate center offset (half of original frame size, not scaled)
            local offsetX = 0
            local offsetY = 0
            
            -- Draw with type-specific settings
            if obj.type == "duck" then
                love.graphics.setColor(1, 1, 1, 0.9)
                anim:draw(sprite, obj.x, obj.y, 0, data.scale, data.scale, offsetX, offsetY)
                
            elseif obj.type == "rock" then
                love.graphics.setColor(1, 1, 1, 0.8)
                anim:draw(sprite, obj.x, obj.y, 0, data.scale, data.scale, offsetX, offsetY)
                
            else
                love.graphics.setColor(1, 1, 1, 1)
                anim:draw(sprite, obj.x, obj.y, 0, data.scale, data.scale, offsetX, offsetY)
            end
        else
            -- Debug box if something missing
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.rectangle("fill", obj.x - 16, obj.y - 16, 32, 32)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Decorations