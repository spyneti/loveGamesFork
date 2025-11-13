function love.load()
    require "mainCharacter"
    mainCharacter.load()
end

function love.update(dt)
    mainCharacter.update(dt)
end

function love.draw()
    mainCharacter.draw()
    love.graphics.print("Hello World!", 400, 200)
end