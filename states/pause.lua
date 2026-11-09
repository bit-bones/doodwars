local Gamestate = require "libs/hump/gamestate"
-- local menu = require "states/menu"
local drawing = require "drawing"
local graphics = require "graphics"
local screen = graphics.screen
local fonts = graphics.fonts
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor

local pause = {}

function pause:enter(previous)
    self.previous = previous
end

local buttons = {
    {
        label = "Resume",
        fn = function ()
            Gamestate.pop()
        end
    },
    {
        label = "Options",
        fn = function ()
            
        end
    },
    {
        label = "Main menu",
        fn = function ()
            Gamestate.switch()
        end
    },
}

function pause:draw()
    self.previous:draw()

    drawing.drawModal("Pause", buttons)
end

function pause:keypressed(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

return pause