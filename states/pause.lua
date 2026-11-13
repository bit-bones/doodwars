local mouse = require "mouse"
local Gamestate = require "libs/hump/gamestate"
local options = require "states.options"
local ui = require "ui"
local graphics = require "graphics"

local pause = {}

function pause:init()
    self.drawModal = true
    self.buttons = {
        {
            label = "Resume",
            fn = function ()
                Gamestate.pop()
            end
        },
        {
            label = "Options",
            fn = function ()
                Gamestate.push(options)
            end,
        },
        {
            label = "Main menu",
            fn = function ()
                local menu = require "states.menu"
                Gamestate.switch(menu)
            end
        },
    }
end

function pause:enter(previous)
    self.previous = previous
    graphics.getModalLayout(self.buttons)
    mouse.setCursor("arrow")
end

function pause:draw()
    self.previous:draw()
    if self.drawModal then
        ui.modal("Pause")
    end
end

function pause:keypressed(key)
    if key == "escape" then
        mouse.setCursor("arrow")
        Gamestate.pop()
    end
end

function pause:mousemoved(x, y)
    mouse.modalMousemoved(x, y, self)
end

function pause:mousepressed(x, y, mouseButton)
    mouse.modalMousepressed(x, y, mouseButton, self)
end

function pause:resize()
    graphics.getModalLayout()
end

return pause