-- Includes and scene setup
local hiScore = require("hiscore")
local composer = require("composer")
local scene = composer.newScene()

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

-- Texts and buttons
local FONT = "fonts/citaro_voor_dubbele_hoogte_breed.ttf"

local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

local titleText = display.newText(uiGroup, "CIRCLEXPLOSION", display.contentCenterX, 20, FONT, 60)
titleText:setFillColor(1, 1, 1)

local hiScoreText = display.newText(uiGroup, "HI-SCORE", display.contentCenterX, display.contentCenterY - 20, FONT, 40)
hiScoreText:setFillColor(1, 1, 1)

local hiScoreValueText = display.newText(uiGroup, "-", display.contentCenterX, display.contentCenterY + 20, FONT, 40)
hiScoreValueText:setFillColor(1, 1, 1)

local circle = display.newCircle(mainGroup, display.contentCenterX, display.contentHeight - 80, 64)
circle:setFillColor(0, 1, 0)
circle.alpha = .6

local startText = display.newText(uiGroup, "START", display.contentCenterX, display.contentHeight - 80, FONT, 40)
startText:setFillColor(1, 1, 1)

-- Animations
local function beatCircle()
    transition.to(circle, {
        time = 1500,
        iterations = 0,
        xScale = 1.2,
        yScale = 1.2,
        alpha = .4,
        transition = easing.outElastic
    })
end

-- Functions
local function gotoGame(event)
    composer.gotoScene("game", {
        effect = "fade",
        time = 600
    })
end

-- Init
circle:addEventListener("tap", gotoGame)

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
    elseif (phase == "did") then
        circle.width = 64
        circle.height = 64
        beatCircle()
        hiScore:load()
        hiScoreValueText.text = hiScore.value
    end

end

function scene:hide(event)
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if (phase == "will") then
        uiGroup.isVisible = false
        mainGroup.isVisible = false
    elseif (phase == "did") then

    end

end
 
function scene:destroy(event)
 
end

return scene