local Gamestate = require "libs/hump/gamestate"
local game = require "states/game"
local drawing = require "drawing"
local graphics = require "graphics"
local screen = graphics.screen
local fonts = graphics.fonts
local fontHeights = graphics.fontHeights
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor

local menu = {}

function menu:init()
    graphics.getLayout()
end

function menu:startGame()
    Gamestate.switch(game, {
        map = "map1",
        gameMode = "Doodomination",
    })
end

local buttons = {
    {
        label = "Play",
        fn = function()
            menu:startGame()
        end,
    },
    {
        label = "Quit",
        fn = function()
            love.event.quit()
        end,
    },
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

function menu:resize()
    graphics.getLayout()
end

return menu