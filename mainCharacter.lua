mainCharacter = {}

function mainCharacter.load()
    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest", "nearest")

    player = {}
    player.x = 400
    player.y = 200
    player.speed = 500
    player.spriteSheet = love.graphics.newImage("sprites/player-sheet.png")
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid("1-4", 1), 0.2)
    player.animations.left = anim8.newAnimation( player.grid("1-4", 2), 0.2)
    player.animations.right = anim8.newAnimation( player.grid("1-4", 3), 0.2)
    player.animations.up = anim8.newAnimation( player.grid("1-4", 4), 0.2)

    player.anim = player.animations.left

    background = love.graphics.newImage("sprites/background.png")
 
end

function mainCharacter.update(dt)
    local isMoving = false

    if love.keyboard.isDown("a") then
        player.x = player.x - player.speed * dt
        player.anim = player.animations.left
        isMoving = true
    end
        if love.keyboard.isDown("d") then
        player.x = player.x + player.speed * dt
        player.anim = player.animations.right
        isMoving = true
    end
        if love.keyboard.isDown("w") then
        player.y = player.y - player.speed * dt
        player.anim = player.animations.up
        isMoving = true
    end
        if love.keyboard.isDown("s") then
        player.y = player.y + player.speed * dt
        player.anim = player.animations.down
        isMoving = true
    end

    if isMoving == false then
        player.anim:gotoFrame(2)
    end

    player.anim:update(dt)
end

function mainCharacter.draw()
    love.graphics.draw(background, 0, 0)
    player.anim:draw(player.spriteSheet, player.x, player.y, nil, 10)
end