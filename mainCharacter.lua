mainCharacter = {}

function mainCharacter.load()
    wf = require "libraries/windfield"
    world = wf.newWorld(0, 0)

    camera = require "libraries/camera"
    cam = camera()
    cam:zoom(4)

    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require "libraries/sti"
    gameMap = sti("maps/map.lua")

    require "projectile"
    projectile.load()

    player = {}
    player.collider = world:newBSGRectangleCollider(400, 250, 12, 18, 4)
    player.collider:setFixedRotation(true)
    player.x = 32
    player.y = 32
    player.speed = 150
    player.health = 100
    player.maxHealth = 100
    player.dmg = 25
    player.projectileSpeed = 300
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
    if gameMap.layers["walls"] then
        for i, obj in pairs(gameMap.layers["walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType("static")
            table.insert(walls, wall)
        end
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

    local halfW = 12 / 2
    local halfH = 18 / 2
    local mapW = 90 * 16
    local mapH = 90 * 16

    local x = math.max(halfW, math.min(player.collider:getX(), mapW - halfW))
    local y = math.max(halfH, math.min(player.collider:getY(), mapH - halfH))
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

    local zoom = 4

    local screenW = love.graphics.getWidth() / zoom
    local screenH = love.graphics.getHeight() / zoom
    
    local camX = math.max(screenW/2, math.min(player.x, mapW - screenW/2))
    local camY = math.max(screenH/2, math.min(player.y, mapH - screenH/2))

    cam:lookAt(camX, camY)

    mainCharacter.camX = camX
    mainCharacter.camY = camY
    mainCharacter.zoom = zoom

    particles.update(dt)
end

function mainCharacter.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["ground"], 0, 0, 4, 4)
        gameMap:drawLayer(gameMap.layers["flowers"], 0, 0, 4, 4)

        if player.invincible then
            love.graphics.setColor(1, 1, 1, 0.5)
        end

        local ox = 96
        local oy = 96
        player.anim:draw(player.currentSprite, player.x, player.y, 0, 0.3, 0.3, ox, oy)

        love.graphics.setColor(1, 1, 1)

        enemyUnit.draw()

        particles.draw()

        projectile.draw()

        gameMap:drawLayer(gameMap.layers["trees"], 0, 0, 4, 4)
        
        love.graphics.setColor(1, 1, 1)

    cam:detach()
end