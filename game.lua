-- Includes and scene setup
local hiScore = require("hiscore")
local composer = require("composer")

local scene = composer.newScene()
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

-- "Constants"
local SEPARATION_FROM_BORDER = 40
local CIRCLE_SPEED_INCREMENT = 0.0001
local INITIAL_CIRCLE_SPEED = 0.985
local MAX_CIRCLE_SPEED = 0.95
local MIN_CIRCLE_SCALE = 0.06  
local INITIAL_FRAMES_TO_SPAN = display.fps * 1.5
local MIN_FRAMES_TO_SPAN = display.fps / 3
local BONUS_BLINKS = 4
local BONUS_BLINK_TIME = 300
local SCORE_EVERY_EXTRA_LIFE = 5000

local FRAME_BONUS = 4
local BONUS_SCORE = 100
local BONUS_SCORE_EXTRA_LIFE = 500
local NORMAL_SCORE = 20

local LIVES = 5
local LIVE_WIDTH = 6
local LIVE_SEPARATION = 4
local FONT = "fonts/citaro_voor_dubbele_hoogte_breed.ttf"

-- Game variables
local circles = {}

local framesToSpan = INITIAL_FRAMES_TO_SPAN
local currentFrame = 0
local circleSpeed = INITIAL_CIRCLE_SPEED

local score = 0
local scoreForExtraLife = 0
local lives = LIVES
local playing = true
local bonusTimes = 0

-- Audio files
local soundEffects = {
    bonus1 = audio.loadSound("audio/bonus1.wav"),
    bonus2 = audio.loadSound("audio/bonus2.wav"),
    explosion1 = audio.loadSound("audio/explosion1.wav"),
    explosion2 = audio.loadSound("audio/explosion2.wav"),
    explosion3 = audio.loadSound("audio/explosion3.wav"),
    failure = audio.loadSound("audio/failure.wav"),
    gameOver = audio.loadSound("audio/gameOver.wav"),
    getReady = audio.loadSound("audio/getReady.wav"),
    newHighScore = audio.loadSound("audio/newHighScore.wav")
}

-- Layers
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()
local buttonsGroup = display.newGroup()

-- Texts
local scoreY = display.safeScreenOriginY + 24 + LIVE_WIDTH * 2
local scoreText = display.newText(uiGroup, score, display.contentCenterX, scoreY, FONT, 40)
scoreText:setFillColor(1, 1, 1)

local bonusText = display.newText(uiGroup, "", display.contentCenterX, scoreY + 28, FONT, 20)
bonusText:setFillColor(1, 1, 1)

local gameOverText = display.newText(uiGroup, "GAME OVER", display.contentCenterX, display.contentCenterY, FONT, 60)
gameOverText:setFillColor(1, 1, 1)
gameOverText.alpha = 0

local pauseText = display.newText(uiGroup, "PAUSED", display.contentCenterX, display.contentCenterY, FONT, 60)
pauseText:setFillColor(1, 1, 1)
pauseText.isVisible = false

local newHiScoreText = display.newText(uiGroup, "NEW HI-SCORE!", display.contentCenterX, display.contentCenterY + 60, FONT, 40)
newHiScoreText:setFillColor(1, 1, 1)
newHiScoreText.alpha = 0

-- Buttons
local pauseBtn = display.newImage(uiGroup, "img/pause.png", display.contentWidth - 24, display.safeScreenOriginY + 36)
pauseBtn:scale(0.3, 0.3)

local retryCircle = display.newCircle(buttonsGroup, 68, display.contentHeight - 70, 52)
retryCircle:setFillColor(0, 1, 0)
retryCircle.alpha = .6

local retryText = display.newText(buttonsGroup, "RETRY", 68, display.contentHeight - 70, FONT, 40)
retryText:setFillColor(1, 1, 1)

local cancelCircle = display.newCircle(buttonsGroup, display.contentWidth - 68, display.contentHeight - 70, 52)
cancelCircle:setFillColor(1, 0, 0)
cancelCircle.alpha = .6

local cancelText = display.newText(buttonsGroup, "CANCEL", display.contentWidth - 68, display.contentHeight - 70, FONT, 40)
cancelText:setFillColor(1, 1, 1)

local function beatRetry()
    transition.to(retryCircle, {
        time = 1500,
        iterations = 0,
        xScale = 1.2,
        yScale = 1.2,
        alpha = .4,
        transition=easing.outElastic
    })
end

-- Local Functions
local random = math.random

-- Score
local function increaseScore(amount)
    score = score + amount
    scoreForExtraLife = scoreForExtraLife + amount
end

-- Bonus
local function checkBonusBlink(obj) 
    bonusTimes = bonusTimes + 1
    if (bonusTimes == BONUS_BLINKS) then
        transition.cancel(bonusText)
        bonusText.alpha = 0
    end
end

local function bonusBlink(text) 
    bonusText.text = text
    bonusText.alpha = 1
    bonusTimes = 0
    transition.cancel(bonusText)
    transition.blink(bonusText, {
        time = BONUS_BLINK_TIME,
        onRepeat = checkBonusBlink
    })
end

-- Lives
local livesCircles = {}
for i = 0, LIVES - 1 do 
    local x = display.contentCenterX 
                - (LIVES * (LIVE_WIDTH + LIVE_SEPARATION) + LIVE_SEPARATION) / 2 
                + ((LIVE_WIDTH + LIVE_SEPARATION) * i) + LIVE_SEPARATION 
                + (LIVE_WIDTH / 2)
    local live = display.newCircle(uiGroup, x, display.safeScreenOriginY + 10, LIVE_WIDTH / 2)
    live:setFillColor(1, 0, 0)
    livesCircles[#livesCircles + 1] = live
end

local function showLives()
    for i, live in pairs(livesCircles) do
        live.isVisible = true
    end
end

local function checkExtraLife()
    if (scoreForExtraLife >= SCORE_EVERY_EXTRA_LIFE) then
        scoreForExtraLife = scoreForExtraLife - SCORE_EVERY_EXTRA_LIFE
        if (lives < LIVES) then
            lives = lives + 1
            bonusBlink("EXTRA LIFE")
        else
            increaseScore(BONUS_SCORE_EXTRA_LIFE)
            bonusBlink("BONUS")
        end
    end
end

-- Reset game
local function reset()
    score = 0
    scoreForExtraLife = 0
    scoreText.text = score

    lives = LIVES
    showLives()

    circles = {}

    circleSpeed = INITIAL_CIRCLE_SPEED
    framesToSpan = INITIAL_FRAMES_TO_SPAN
    currentFrame = 0

    playing = true

    transition.cancelAll()
    gameOverText.alpha = 0
    newHiScoreText.alpha = 0
    pauseBtn.isVisible = true
    buttonsGroup.isVisible = false

    audio.play(soundEffects["getReady"])
end

-- Circle tapped
local function circleTap(event) 

    if (playing and event.target.isOK) then 
        if (event.target.frame <= FRAME_BONUS) then
            increaseScore(BONUS_SCORE)
            audio.play(soundEffects["bonus" .. random(1, 2)])
            bonusBlink("BONUS")
        else
            increaseScore(NORMAL_SCORE)
            audio.play(soundEffects["explosion" .. random(1, 3)])
        end

        checkExtraLife()
        scoreText.text = score
        display.remove(event.target)
        for i, circle in pairs(circles) do
            if (circle == event.target) then
                circles[i] = nil
            end
        end

        -- Explosion
        local explosion = display.newCircle(mainGroup, event.target.x, event.target.y, 32)
        explosion:setFillColor(1, 1, 1)
        explosion.alpha = 0.5
        transition.fadeOut(explosion, {
            time = 800,
            transition = easing.outBounce,
            onComplete = function(obj)
                display.remove(obj)
            end
        })
    end
    
end

-- Create circle
local function spanCircle()

    local x = random(SEPARATION_FROM_BORDER, display.contentWidth - SEPARATION_FROM_BORDER)
    local y = random(SEPARATION_FROM_BORDER, display.contentHeight - SEPARATION_FROM_BORDER)

    local circle = display.newCircle(mainGroup, x, y, display.contentWidth)
    circle:setFillColor(0.9, 0, 0)
    circle.scaleFactor = circleSpeed
    circle.isOK = false
    circle.frame = 0
    circleSpeed = circleSpeed - CIRCLE_SPEED_INCREMENT
    if (circleSpeed < MAX_CIRCLE_SPEED) then 
        circleSpeed = MAX_CIRCLE_SPEED
    end

    circle:addEventListener("tap", circleTap)

    table.insert(circles, circle)

end

-- Game actions
local function restart() 
    for i, circle in pairs(circles) do
        display.remove(circle)
    end
    reset()
    spanCircle()
end

local function showNewGame()
    buttonsGroup.isVisible = true
    retryCircle.width = 52
    retryCircle.height = 52
    beatRetry()
end

local function pause()
    playing = not playing
    pauseText.isVisible = not playing
end

local function exit() 
    composer.gotoScene("title")
end

-- Update circles (gameLoop)
local function updateCircles()

    if (playing) then
        currentFrame = currentFrame + 1
        if (framesToSpan <= currentFrame) then
            currentFrame = 0
            framesToSpan = framesToSpan - 0.5
            if (framesToSpan <= MIN_FRAMES_TO_SPAN) then
                framesToSpan = MIN_FRAMES_TO_SPAN
            end
            spanCircle()
        end

        for i, circle in pairs(circles) do
            local currentScale = circle.contentWidth / display.contentWidth
            if (currentScale >= MIN_CIRCLE_SCALE) then
                circle:scale(circle.scaleFactor, circle.scaleFactor)
                local currentAlpha = 0.1
                if (currentScale >= 0.7) then
                    circle:setFillColor(0.9, 0, 0)
                elseif (currentScale >= 0.5) then
                    circle:setFillColor(0.8, 1 - currentScale, 0)
                    currentAlpha = 0.1
                elseif (currentScale >= 0.2) then
                    circle:setFillColor(0.5, 0.3, 0)
                    currentAlpha = 0.3
                else
                    currentAlpha = 1 - currentScale
                    circle.isOK = true
                    circle.frame = circle.frame + 1
                    circle:setFillColor(currentScale, 1 - currentScale, 0)
                end
                circle.alpha = currentAlpha
            else 
                display.remove(circle)
                circles[i] = nil

                livesCircles[lives].isVisible = false
                lives = lives - 1

                if (lives == 0) then
                    playing = false
                    transition.fadeIn(gameOverText, {
                        time = 500
                    })

                    if (score > hiScore.value) then
                        hiScore.value = score
                        hiScore:save()
                        newHiScoreText.alpha = 1
                        transition.blink(newHiScoreText, {
                            time = 2000
                        })
                        audio.play(soundEffects["newHighScore"], {
                            onComplete = showNewGame
                        })
                    else
                        audio.play(soundEffects["gameOver"], {
                            onComplete = showNewGame
                        })
                    end

                    pauseBtn.isVisible = false
                else
                    audio.play(soundEffects["failure"])
                end
            end
        end
    end

end

-- Init game and setup listeners
math.randomseed(os.time())
hiScore:load()

Runtime:addEventListener("enterFrame", updateCircles)
pauseBtn:addEventListener("tap", pause)
retryCircle:addEventListener("tap", restart)
cancelCircle:addEventListener("tap", exit)

-- Scene functions
function scene:create(event)
    local sceneGroup = self.view
end

function scene:show(event)
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if (phase == "will") then
        uiGroup.isVisible = true
        mainGroup.isVisible = true
        buttonsGroup.isVisible = false
    elseif (phase == "did") then
        restart()
    end

end

function scene:hide(event)
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if (phase == "will") then
        uiGroup.isVisible = false
        mainGroup.isVisible = false
        buttonsGroup.isVisible = false
    elseif (phase == "did") then
 
    end

end
 
function scene:destroy(event)
 
end

return scene