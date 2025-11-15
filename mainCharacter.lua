mainCharacter = {}

function mainCharacter.load()
    camera = require "libraries/camera"
    cam = camera()
    cam:zoom(4)

    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require "libraries/sti"
    gameMap = sti("maps/map.lua")

    player = {}
    player.x = 32
    player.y = 32
    player.speed = 100
    player.spriteSheet = love.graphics.newImage("sprites/player-sheet.png")
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid("1-4", 1), 0.2)
    player.animations.left = anim8.newAnimation( player.grid("1-4", 2), 0.2)
    player.animations.right = anim8.newAnimation( player.grid("1-4", 3), 0.2)
    player.animations.up = anim8.newAnimation( player.grid("1-4", 4), 0.2)

    player.anim = player.animations.left
 
end

function mainCharacter.update(dt)
    local dx, dy = 0, 0
    local isMoving = false

    if love.keyboard.isDown("a") then
        dx = dx - 1
        player.anim = player.animations.left
        isMoving = true
    end
    if love.keyboard.isDown("d") then
        dx = dx + 1
        player.anim = player.animations.right
        isMoving = true
    end
    if love.keyboard.isDown("w") then
        dy = dy - 1
        player.anim = player.animations.up
        isMoving = true
    end
    if love.keyboard.isDown("s") then
        dy = dy + 1
        player.anim = player.animations.down
        isMoving = true
    end

    local currentSpeed = player.speed
    if dx ~= 0 and dy ~= 0 then
        currentSpeed = currentSpeed / math.sqrt(2)
    end

    if isMoving == false then
        player.anim:gotoFrame(2)
    end

    player.x = player.x + dx * currentSpeed * dt
    player.y = player.y + dy * currentSpeed * dt

    player.anim:update(dt)

    local zoom = 4

    local screenW = love.graphics.getWidth() / zoom
    local screenH = love.graphics.getHeight() / zoom

    local mapW = 30 * 16 
    local mapH = 30 * 16

    local camX = math.max(screenW/2, math.min(player.x, mapW - screenW/2))
    local camY = math.max(screenH/2, math.min(player.y, mapH - screenH/2))

    cam:lookAt(camX, camY)

end

function mainCharacter.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["ground"], 0, 0, 4, 4)
        player.anim:draw(player.spriteSheet, player.x, player.y, 0, 1.33, 1.33, 6, 9)
        gameMap:drawLayer(gameMap.layers["trees"], 0, 0, 4, 4)
    cam:detach()
end