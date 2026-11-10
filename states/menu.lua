local mouse = require "mouse_map"
local Gamestate = require "libs/hump/gamestate"
local game = require "states.game"
local drawing = require "drawing"
local graphics = require "graphics"
local screen = graphics.screen
local getColor = graphics.getColor
local setColor = graphics.setColor

local menu = {}

local buttons = {
    {
        label = "Play",
        fn = function()
            menu:startGame()
        end,
    },
    {
        label = "Options",
        fn = function ()
            
        end,
    },
    {
        label = "Quit",
        fn = function()
            love.event.quit()
        end,
    },
}

function menu:enter()
    graphics.getLayout(buttons)
end

function menu:startGame()
    Gamestate.switch(game, {
        map = "map1",
        gameMode = "Doodomination",
    })
end

function menu:draw()
    local previousColor = getColor()

    setColor(0.2, 0.4, 0.2)
    love.graphics.rectangle("fill", 0, 0, screen.w, screen.h)

    drawing.drawModal("Dood Wars")

    setColor(previousColor)
end

function menu:keyreleased(key)
    if key == "return" then
        menu:startGame()
    end
end

function menu:mousemoved(x, y)
    for _, button in ipairs(graphics.buttons) do
        button.hovered = mouse.M.mouseHover(x, y, button.box)
    end
end

function menu:mousepressed(x, y, inputButton)
    for _, button in ipairs(graphics.buttons) do
        if button.hovered then
            button.fn()
            print("clicked "..button.label)
            return
        end
    end
end

function menu:resize()
    graphics.getLayout()
end

return menu