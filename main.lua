local score = 0

function love.load()
    require "mainCharacter"
    mainCharacter.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
end

function love.update(dt)
    mainCharacter.update(dt)
    score = score + 1
end

function love.draw()
    mainCharacter.draw()
    time = math.floor(love.timer.getTime())
    standardPadding = 10

    scoreText = "SCORE: " .. score
    font = love.graphics.getFont()
    scoreTextWidth = (font:getWidth(scoreText)) * 2

    timeText = "TIME: " .. time
    TimeTextWidth = (font:getWidth(timeText)) * 2

    windowWidth = love.graphics.getWidth()
    windowHeight = love.graphics.getHeight()

    scoreTextX = standardPadding
    scoreTextY = standardPadding

    timeTextX = windowWidth - TimeTextWidth - standardPadding
    timeTextY = standardPadding

    love.graphics.print(scoreText, scoreTextX, scoreTextY, 0, 2 )
    love.graphics.print(timeText , timeTextX, timeTextY, 0, 2)
end