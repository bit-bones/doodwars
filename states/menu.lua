local Gamestate = require "libs/hump/gamestate"
local game = require "states/game"

local graphics = require "graphics"
local screen = graphics.screen
local fonts = graphics.fonts
local fontHeights = graphics.fontHeights
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor

local drawing = require "drawing"


local menu = {}

function menu:init()
    print("menu initialized")
end

function menu:startGame()
    Gamestate.switch(game, {
        map = "map1",
        gameMode = "Doodomination",
    })
end

local buttons = {
    {label = "Play"},
    {label = "Quit"},
}

function menu:draw()
    local previousColor = getColor()

    setColor(0.2, 0.4, 0.2)
    love.graphics.rectangle("fill", 0, 0, screen.w, screen.h)

    drawing.drawModal("Dood Wars", buttons)

    setColor(previousColor)
end

function menu:keyreleased(key)
    if key == "return" then
        menu:startGame()
    end
end

return menu