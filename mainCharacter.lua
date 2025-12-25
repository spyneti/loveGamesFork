mainCharacter = {}

function mainCharacter.load()
    wf = require "libraries/windfield"
    world = wf.newWorld(0, 0)

    _G.world = world

    zoom = 1.5

    camera = require "libraries/camera"
    cam = camera()
    cam:zoom(zoom)

    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require "libraries/sti"
    gameMap = sti("maps/map.lua")

    require "projectile"
    projectile.load()
    player = {}


    player.x = 300
    player.y = 300
    player.colliderW = 48
    player.colliderH = 48
    player.collider = world:newRectangleCollider(player.x, player.y, player.colliderW, player.colliderH)
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

    local function spawnColliders(layerName)
        if gameMap.layers[layerName] then
            for i, obj in pairs(gameMap.layers[layerName].objects) do
                
                local x = obj.x
                local y = obj.y
                local w = obj.width
                local h = obj.height

                -- FIX: Tiled "Insert Tile" objects draw from Bottom-Left.
                -- We must shift them up to match Box2D (Top-Left).
                if obj.gid then
                    y = y - h
                end

                -- Create collider at RAW 1x size
                local wall = world:newRectangleCollider(x, y, w, h)
                wall:setType("static")
                table.insert(walls, wall)
            end
        end
    end

    spawnColliders("rocks_collision")
    spawnColliders("walls_collision")
    spawnColliders("bushes")

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

    player.collider:setAngle(0)

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

    local screenW = love.graphics.getWidth() / zoom
    local screenH = love.graphics.getHeight() / zoom
  
    local camX = math.max(screenW/zoom, math.min(player.x, mapWorldW - screenW/zoom))
    local camY = math.max(screenH/zoom, math.min(player.y, mapWorldH - screenH/zoom))

    cam:lookAt(camX, camY)

    mainCharacter.camX = camX
    mainCharacter.camY = camY

    particles.update(dt)
end

function mainCharacter.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["ground"], 0, 0, 1, 1)

        gameMap:update(dt)
        
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

        gameMap:drawLayer(gameMap.layers["tree"], 0, 0, 1, 1)
        
        love.graphics.setColor(1, 1, 1)

    cam:detach()
    
    love.graphics.setColor(1, 1, 1)
end