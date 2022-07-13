Class = require 'class'
push = require 'push'
require 'Paddle'
require "Ball"



WINDOW_WIDTH = 1366
WINDOW_HEIGHT = 768

VIRTUAL_WIDTH = 400
VIRTUAL_HEIGHT = 250
PADDLE_SPEED = 200


function love.load()
	--it is for bluriness on text
	love.graphics.setDefaultFilter('nearest', 'nearest')
	
	love.window.setTitle("PONG")
	
	
	-- "seed" the RNG so that calls to random are always random
    -- use the current time, since that will vary on startup every time
	math.randomseed(os.time())
	
	
	-- create new font for Text
	smallFont = love.graphics.newFont("font.ttf", 8)
	scoreFont = love.graphics.newFont("font.ttf", 25)
	largeFont = love.graphics.newFont('font.ttf', 16)
	
	sounds = {
		["paddle_hit"] = love.audio.newSource("sounds/paddle_hit.wav", "static"),
		["score"] = love.audio.newSource("sounds/score.wav", "static"),
		["wall_hit"] = love.audio.newSource("sounds/wall_hit.wav", "static")
	}
	
	--set the boarder of the game playground
	push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
		fullscreen = false,
		resizable = true,
		vsync = true})
		
	--left player score
	player1Score = 0
	--right player score
	player2Score = 0
	servingPlayer = 1
	
	player1 = Paddle(6, 20, 3.5, 25)
	player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 50, 3.5, 25)
	ball = Ball(VIRTUAL_WIDTH / 2 - 3, VIRTUAL_HEIGHT / 2 - 3, 4, 4)
		

	gameState = "start"
end

function love.resize(w, h)
	push:resize(w, h)
end

function love.update(dt)

	if gameState == "serve" then
		ball.dy = math.random(-50, 50)
		if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
	elseif gameState == "play" then
		-- detect ball collision with paddles, reversing dx if true and
        -- slightly increasing it, then altering the dy based on the position of collision
		if ball:collide(player1) then
			ball.dx = -ball.dx * 1.03
			ball.x = player1.x + 5    --check this one
			
			-- keep velocity going in the same direction, but randomize it
			if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
			
			sounds["paddle_hit"]:play()
		end
		
		if ball:collide(player2) then
			ball.dx = -ball.dx * 1.03
			ball.x = player2.x - 5    
			
			-- keep velocity going in the same direction, but randomize it
			if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
			
			sounds["paddle_hit"]:play()
		end
		
		-- detect upper and lower screen boundary collision and reverse if collided
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
			sounds["wall_hit"]:play()
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
			sounds["wall_hit"]:play()
        end
		
		-- if we reach the left or right edge of the screen, 
		-- go back to start and update the score
		if ball.x < 0 then
			servingPlayer = 1
			player2Score = player2Score + 1
			sounds["score"]:play()
			-- if we've reached a score of 10, the game is over; set the
			-- state to done so we can show the victory message
			if player2Score == 5 then
				winningPlayer = 2
				gameState = 'done'
			else
				gameState = 'serve'
				-- places the ball in the middle of the screen, no velocity
				ball:reset()
			end
		end
		
		if ball.x > VIRTUAL_WIDTH then
			servingPlayer = 2
			player1Score = player1Score + 1
			sounds["score"]:play()
			-- if we've reached a score of 10, the game is over; set the
			-- state to done so we can show the victory message
			if player1Score == 5 then
				winningPlayer = 1
				gameState = 'done'
			else
				gameState = 'serve'
				ball:reset()
			end
		end
	end
	
	
	--Move the left paddle up and down
	if love.keyboard.isDown("w") then
		player1.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown("s") then
		player1.dy = PADDLE_SPEED
	else
		player1.dy = 0
	end
	
	--Move the right paddle up and down
	if love.keyboard.isDown("up") then
		player2.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown("down") then
		player2.dy = PADDLE_SPEED
	else
		player2.dy = 0
	end
	
	--assign the velocity to the ball in play mode
	if gameState == "play" then
		ball:update(dt)
	end
	
	player1:update(dt)
	player2:update(dt)
end

function love.draw()
	--calling the library
	push:apply("start")
	
	
	--set the playground color
	love.graphics.clear(40/255, 45/255, 52/255, 1)
	
	displayScore()
	
	--set font for the text
	love.graphics.setFont(smallFont)
	if gameState == "start" then
		--print the text on the screen
		love.graphics.printf("PONG", 0, 5, VIRTUAL_WIDTH, "center")
		love.graphics.printf("Press ENTER/RETURN to start the name", 0, 15, VIRTUAL_WIDTH, "center")
	elseif gameState == 'serve' then
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
		love.graphics.printf('(AND DO NOT BELIEVE WHATEVER YOUR ARE SEEING)', 0, 30, VIRTUAL_WIDTH, 'center')
	elseif gameState == "play" then
		love.graphics.printf("PLAYING PONG..!", 0, 5, VIRTUAL_WIDTH, "center")
	elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
	end
	
	
	--create left paddle
	player1:render()
	
	--create right paddle
	player2:render()
	--love.graphics.rectangle("fill", VIRTUAL_WIDTH - 10, player2Y, 4, 20)
	
	--create ball at center
	--love.graphics.rectangle("fill", ballX, ballY, 5, 5)
	ball:render()
	
	displayFPS()
	--end the library
	push:apply("end")
end

function love.keypressed(key)
	--set the 'escape key' for quit the game
	if key == "escape" then
		love.event.quit()
	elseif key == "kpenter" or key == "return" then
		if gameState == "start" then
			gameState = "serve"
		elseif gameState == "serve" then
			gameState = "play"
		elseif gameState == 'done' then
            -- game is simply in a restart phase here, but will set the serving
            -- player to the opponent of whomever won for fairness!
            gameState = 'serve'

            ball:reset()

            -- reset scores to 0
            player1Score = 0
            player2Score = 0

            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
		end
	end
end

function displayFPS()
	love.graphics.setFont(smallFont)
	love.graphics.setColor(0, 255/255, 0, 255/255)
	love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
end

function displayScore()
	--set font for the score
	love.graphics.setFont(scoreFont)
	--print the score text on screen for left player
	love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 60, VIRTUAL_HEIGHT / 2 - 20)
	--print the score text on screen for right player
	love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 45, VIRTUAL_HEIGHT / 2 - 20)
end