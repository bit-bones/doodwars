local mouse = require "mouse_map"
local Gamestate = require "libs/hump/gamestate"
local drawing = require "drawing"
local graphics = require "graphics"

local pause = {}

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
            local menu = require "states.menu"
            Gamestate.switch(menu)
        end
    },
}

function pause:enter(previous)
    self.previous = previous
    graphics.getLayout(buttons)
end

function pause:draw()
    self.previous:draw()
    drawing.drawModal("Pause")
end

function pause:keypressed(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

function pause:mousemoved(x, y)
    for _, button in ipairs(graphics.buttons) do
        button.hovered = mouse.M.mouseHover(x, y, button.box)
    end
end

function pause:mousepressed(x, y, inputButton)
    for _, button in ipairs(graphics.buttons) do
        if button.hovered then
            button.fn()
            print("clicked "..button.label)
            return
        end
    end
end

function pause:resize()
    graphics.getLayout()
end

return pause