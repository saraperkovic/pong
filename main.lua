push = require 'push'
Class = require 'class'
require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243
PADDLE_SPEED = 200

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Pong')
    math.randomseed(os.time())

    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    player1Score = 0
    player2Score = 0

    servingPlayer = 1
    winningPlayer = 0

    menuOptions = {"Player vs AI", "Player vs Player", "Quit"}
    selectedOption = 1
    gameState = 'menu' -- start in menu
    gameMode = 'PVE'   -- default mode (will be set from menu)
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end

    elseif gameState == 'play' then
        -- paddle collision
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + player1.width

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - ball.width

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        -- top / bottom
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - ball.height then
            ball.y = VIRTUAL_HEIGHT - ball.height
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- left / right (score)
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end

    -- Controls (mode-dependent)
    if gameMode == 'PVE' then
        -- AI for player1 (only in play)
        if gameState == 'play' then
            -- Only track when ball is moving towards the AI (dx < 0).
            -- Also wait until ball is roughly on AI's half to avoid jitter in serve.
            if ball.dx < 0 and ball.x < VIRTUAL_WIDTH / 2 then
                local paddleCenter = player1.y + player1.height / 2
                local ballCenter = ball.y + ball.height / 2
                if ballCenter < paddleCenter - 2 then
                    player1.dy = -PADDLE_SPEED
                elseif ballCenter > paddleCenter + 2 then
                    player1.dy = PADDLE_SPEED
                else
                    player1.dy = 0
                end
            else
                player1.dy = 0
            end
        else
            player1.dy = 0
        end
    else
        -- PVP: player1 controlled by W/S
        if love.keyboard.isDown('w') then
            player1.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('s') then
            player1.dy = PADDLE_SPEED
        else
            player1.dy = 0
        end
    end

    -- player2 always keyboard (up/down)
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    -- MENU navigation
    if gameState == 'menu' then
        if key == 'up' then
            selectedOption = selectedOption - 1
            if selectedOption < 1 then selectedOption = #menuOptions end
        elseif key == 'down' then
            selectedOption = selectedOption + 1
            if selectedOption > #menuOptions then selectedOption = 1 end
        elseif key == 'enter' or key == 'return' then
            if selectedOption == 1 then
                gameMode = 'PVE'
                gameState = 'start'
            elseif selectedOption == 2 then
                gameMode = 'PVP'
                gameState = 'start'
            elseif selectedOption == 3 then
                love.event.quit()
            end
        end

    elseif gameState == 'start' then
        if key == 'enter' or key == 'return' then
            gameState = 'serve'
        end

    elseif gameState == 'serve' then
        if key == 'enter' or key == 'return' then
            gameState = 'play'
        end

    elseif gameState == 'done' then
        if key == 'enter' or key == 'return' then
            -- reset for a new match
            ball:reset()
            player1Score = 0
            player2Score = 0
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
            gameState = 'serve'
        end
    end
end

function love.draw()
    push:apply('start')
    love.graphics.clear(65/255, 2/255, 89/255, 204/255)

    if gameState == 'menu' then
        love.graphics.setFont(largeFont)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("PONG", 0, 40, VIRTUAL_WIDTH, "center")

        love.graphics.setFont(smallFont)
        for i, option in ipairs(menuOptions) do
            if i == selectedOption then
                love.graphics.setColor(1, 1, 0, 1) -- hover = yellow
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(option, 0, 80 + (i - 1) * 20, VIRTUAL_WIDTH, "center")
        end
        love.graphics.setColor(1,1,1,1)

        love.graphics.setFont(smallFont)
        love.graphics.printf("Use UP / DOWN to move, Enter to select", 0, VIRTUAL_HEIGHT - 30, VIRTUAL_WIDTH, "center")

    else
        -- other states: start / serve / play / done
        if gameState == 'start' then
            love.graphics.setFont(smallFont)
            love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
        elseif gameState == 'serve' then
            love.graphics.setFont(smallFont)
            love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 0, 10, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
        elseif gameState == 'done' then
            love.graphics.setFont(largeFont)
            love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
            love.graphics.setFont(smallFont)
            love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
        end

        displayScore()
        -- render paddles and ball
        love.graphics.setColor(1,1,1,1)
        player1:render()
        player2:render()
        ball:render()
    end

    displayFPS()
    push:apply('end')
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
end

function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(1,1,1,1)
end