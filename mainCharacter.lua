mainCharacter = {}

function mainCharacter.load()
    wf = require "libraries/windfield"
    world = wf.newWorld(0, 0)

    _G.world = world

    camera = require "libraries/camera"
    cam = camera()
    cam:zoom(1.5)

    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require "libraries/sti"
    gameMap = sti("maps/map.lua")

    require "projectile"
    projectile.load()
    player = {}


    player.x = 32
    player.y = 32
    player.collider = world:newBSGRectangleCollider(player.x, player.y, 48, 64, 4)
    player.collider:setFixedRotation(true)
    player.speed = 300
    player.health = 100
    player.maxHealth = 100
    player.dmg = 25
    player.projectileSpeed = 600
    player.arrowCooldown = 0.5
    player.pierce = 1

    player.invincible = false
    player.iframeDuration = 0.2
    player.invincibleTimer = 0


    player.idleSpriteSheet = love.graphics.newImage("sprites/Archer_Idle.png")
    player.runSpriteSheet = love.graphics.newImage("sprites/Archer_Run.png")

    player.idleGrid = anim8.newGrid(192, 192, player.idleSpriteSheet:getWidth(), player.idleSpriteSheet:getHeight())
    player.runGrid = anim8.newGrid(192, 192, player.runSpriteSheet:getWidth(), player.runSpriteSheet:getHeight())
    
    player.animations = {}

    -- player.animations.down = anim8.newAnimation( player.grid("1-4", 1), 0.2)
    player.animations.rightRun = anim8.newAnimation( player.runGrid("1-4", 1), 0.1)
    player.animations.leftRun = anim8.newAnimation( player.runGrid("1-4", 1), 0.1):flipH()
    
    player.animations.rightIdle = anim8.newAnimation( player.idleGrid("1-6", 1), 0.1)
    player.animations.leftIdle = anim8.newAnimation( player.idleGrid("1-6", 1), 0.1):flipH()

    -- player.animations.up = anim8.newAnimation( player.grid("1-4", 4), 0.2)

    player.facing = "right"

    player.anim = player.animations.rightIdle

    player.currentSprite = player.idleSpriteSheet

    walls = {}
    
    -- 1. ROCK COLLIDERS (centered to match visual rocks)
    if gameMap.layers["rocks_collision"] then
        for i, obj in pairs(gameMap.layers["rocks_collision"].objects) do
            -- Calculate CENTERED position (matches decorations.lua)
            local centerX = obj.x + obj.width/2
            local centerY = obj.y + obj.height/2
            
            -- Create collider at centered position (slightly smaller)
            local colliderWidth = obj.width * 0.8
            local colliderHeight = obj.height * 0.8
            
            local rockCollider = world:newRectangleCollider(
                centerX - colliderWidth/2,
                centerY - colliderHeight/2,
                colliderWidth,
                colliderHeight
            )
            rockCollider:setType("static")
            table.insert(walls, rockCollider)
        end
    end
    
    -- 2. WATER COLLIDERS (centered)
    if gameMap.layers["water_collision"] then
        for i, obj in pairs(gameMap.layers["water_collision"].objects) do
            -- Calculate CENTERED position
            local centerX = obj.x + obj.width/2
            local centerY = obj.y + obj.height/2
            
            -- Create collider at centered position
            local waterCollider = world:newRectangleCollider(
                centerX - obj.width/2,
                centerY - obj.height/2,
                obj.width,
                obj.height
            )
            waterCollider:setType("static")
            table.insert(walls, waterCollider)
        end
    end
    
    -- 3. WALL COLLIDERS (centered)
    if gameMap.layers["walls_collision"] then
        for i, obj in pairs(gameMap.layers["walls_collision"].objects) do
            -- Calculate CENTERED position
            local centerX = obj.x + obj.width/2
            local centerY = obj.y + obj.height/2
            
            -- Create collider at centered position
            local wall = world:newRectangleCollider(
                centerX - obj.width/2,
                centerY - obj.height/2,
                obj.width,
                obj.height
            )
            wall:setType("static")
            table.insert(walls, wall)
        end
    end
    
    -- 4. BUSH COLLIDERS (already centered - keep as is)
    if gameMap.layers["bushes"] then
        for i, obj in pairs(gameMap.layers["bushes"].objects) do
            local bushWidth = obj.width or 128
            local bushHeight = obj.height or 128
            local centerX = obj.x + bushWidth/2
            local centerY = obj.y + bushHeight/2

            local colliderWidth = bushWidth * 0.7
            local colliderHeight = bushHeight * 0.7

            local bushCollider = world:newRectangleCollider(
                centerX - colliderWidth/2, 
                centerY - colliderHeight/2, 
                colliderWidth, 
                colliderHeight
            )
            bushCollider:setType("static")
            table.insert(walls, bushCollider)
        end
        print("Created " .. #gameMap.layers["bushes"].objects .. " bush colliders (centered)")
    end

    player.walkSounds = {
        love.audio.newSource("walk/walk-grass-1 (sfx).mp3", "static"),
        love.audio.newSource("walk/walk-grass-2 (sfx).mp3", "static"),
        love.audio.newSource("walk/walk-grass-3 (sfx).mp3", "static"),
        love.audio.newSource("walk/walk-grass-4 (sfx).mp3", "static"),
        love.audio.newSource("walk/walk-grass-5 (sfx).mp3", "static"),
        love.audio.newSource("walk/walk-grass-6 (sfx).mp3", "static")
    }

    for _, sound in ipairs(player.walkSounds) do
        sound:setVolume(0.009)
    end

    player.stepTimer = 0
    player.currentStep = 1
end

function mainCharacter.update(dt)
    projectile.update(dt)

    local dx, dy = 0, 0
    local isMoving = false

    if love.keyboard.isDown("a") then
        dx = dx - 1
        player.anim = player.animations.leftRun
        player.facing = "left"
        player.currentSprite = player.runSpriteSheet
        isMoving = true
    end
    if love.keyboard.isDown("d") then
        dx = dx + 1
        player.anim = player.animations.rightRun
        player.facing = "right"
        player.currentSprite = player.runSpriteSheet
        isMoving = true
    end
    if love.keyboard.isDown("w") then
        dy = dy - 1
        isMoving = true
        player.currentSprite = player.runSpriteSheet

        if player.facing == "left" then
            player.anim = player.animations.leftRun
        else
            player.anim = player.animations.rightRun
        end
    end
    if love.keyboard.isDown("s") then
        dy = dy + 1
        isMoving = true
        player.currentSprite = player.runSpriteSheet

        if player.facing == "left" then
            player.anim = player.animations.leftRun
        else
            player.anim = player.animations.rightRun
        end
    end

    local currentSpeed = player.speed
    if dx ~= 0 and dy ~= 0 then
        currentSpeed = currentSpeed / math.sqrt(2)
    end

    if isMoving == false then
        if player.facing == "left" then
            player.anim = player.animations.leftIdle
        else
            player.anim = player.animations.rightIdle
        end
        player.currentSprite = player.idleSpriteSheet
    end

    if isMoving then
        if not player.stepTimer then
            player.stepTimer = 0
            player.currentStep = 1
        end
        
        player.stepTimer = player.stepTimer + dt

        if player.stepTimer >= 0.3 then 
            player.walkSounds[player.currentStep]:play()
            
            player.currentStep = player.currentStep + 1
            if player.currentStep > #player.walkSounds then
                player.currentStep = 1
            end
            
            player.stepTimer = 0
        end
    else
        if player.stepTimer then
            player.stepTimer = 0
            player.currentStep = 1
        end
    end

    local vx =  dx * currentSpeed 
    local vy =  dy * currentSpeed

    player.collider:setLinearVelocity(vx, vy)

    local halfW = 48 / 2
    local halfH = 64 / 2
    local mapWorldW = gameMap.width * gameMap.tilewidth    -- e.g., 90 × 64 = 5760
    local mapWorldH = gameMap.height * gameMap.tileheight

    local x = math.max(halfW, math.min(player.collider:getX(), mapWorldW - halfW))
    local y = math.max(halfH, math.min(player.collider:getY(), mapWorldH - halfH))
    player.collider:setPosition(x, y)


    player.x = player.collider:getX()
    player.y = player.collider:getY()

    player.anim:update(dt)

    if player.invincible then
        -- Count down the timer
        player.invincibleTimer = player.invincibleTimer - dt
        if player.invincibleTimer <= 0 then
            player.invincible = false
        end
    end

    local zoom = 1.5

    local screenW = love.graphics.getWidth() / zoom
    local screenH = love.graphics.getHeight() / zoom
  
    local camX = math.max(screenW/2, math.min(player.x, mapWorldW - screenW/2))
    local camY = math.max(screenH/2, math.min(player.y, mapWorldH - screenH/2))

    cam:lookAt(camX, camY)

    mainCharacter.camX = camX
    mainCharacter.camY = camY
    mainCharacter.zoom = zoom

    particles.update(dt)
end

function mainCharacter.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["ground"], 0, 0, 2, 2)
        gameMap:drawLayer(gameMap.layers["water"], 0, 0, 2, 2)
        gameMap:drawLayer(gameMap.layers["water shadow"], 0, 0, 2, 2)

        if decorations and decorations.draw then
            decorations.draw()
        end

        -- DEBUG: DRAW ALL COLLISION BOXES (INSIDE CAMERA - WILL MOVE WITH CAMERA)
        love.graphics.setColor(1, 0, 0, 0.3)  -- Red with transparency for walls
        for i, wall in ipairs(walls) do
            if wall:isActive() then
                local x, y, w, h = wall:getBoundingBox()
                love.graphics.rectangle("line", x, y, w, h)  -- Draw as LINE not FILL
            end
        end
        
        -- Draw player collision box (GREEN)
        love.graphics.setColor(0, 1, 0, 0.3)
        local playerX, playerY, playerW, playerH = player.collider:getBoundingBox()
        love.graphics.rectangle("line", playerX, playerY, playerW, playerH)
        
        -- Draw enemy collision boxes (BLUE)
        love.graphics.setColor(0, 0, 1, 0.3)
        for i, e in ipairs(enemyUnit.enemies) do
            if e.collider and e.collider:isActive() then
                local ex, ey, ew, eh = e.collider:getBoundingBox()
                love.graphics.rectangle("line", ex, ey, ew, eh)
            end
        end
        
        love.graphics.setColor(1, 1, 1)  -- Reset color

        if player.invincible then
            love.graphics.setColor(1, 1, 1, 0.5)
        end

        local ox = 96
        local oy = 96
        player.anim:draw(player.currentSprite, player.x, player.y, 0, 1, 1, ox, oy)

        love.graphics.setColor(1, 1, 1)

        crate.draw()
        
        enemyUnit.draw()

        particles.draw()

        projectile.draw()

        gameMap:drawLayer(gameMap.layers["tree"], 0, 0, 2, 2)
        
        love.graphics.setColor(1, 1, 1)

    cam:detach()
    
    -- DEBUG: Also draw simplified collision indicators (RED DOTS) for comparison
    love.graphics.setColor(1, 0, 0, 0.5)
    for i, wall in ipairs(walls) do
        if wall:isActive() then
            local x, y, w, h = wall:getBoundingBox()
            -- Draw a small dot at the center
            local centerX = x + w/2
            local centerY = y + h/2
            
            -- Convert to screen manually
            local camX, camY = cam:position()
            local zoom = cam.scale or 1.5
            local screenX = (centerX - camX) * zoom + love.graphics.getWidth()/2
            local screenY = (centerY - camY) * zoom + love.graphics.getHeight()/2
            
            love.graphics.circle("fill", screenX, screenY, 3)
        end
    end
    
    -- Draw text to show what's what
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("RED LINES = Collision boxes (move with camera)", 10, 10)
    love.graphics.print("RED DOTS = Same collision centers (fixed on screen)", 10, 30)
    love.graphics.print("GREEN = Player collision", 10, 50)
    love.graphics.print("BLUE = Enemy collisions", 10, 70)
    
    love.graphics.setColor(1, 1, 1)
end