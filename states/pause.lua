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
            label = "Restart",
            fn = function ()
                -- local game = require "states.game"
                -- game:enter()
                local menu = require "states.menu"
                menu:startGame()
            end
        },
        {
            label = "Main menu",
            fn = function ()
                local menu = require "states.menu"
                menu.backgroundColor = love.math.random(4) -- color background
                Gamestate.switch(menu)
            end
        },
    }
end

function pause:enter(previous)
    self.previous = previous
    local x, y = love.mouse.getPosition()
    graphics.getModalLayout(self.buttons, {})
    mouse.resolveModalButtonHover(x, y, self)

end

function pause:draw()
    self.previous:draw()
    if self.drawModal then
        ui.modal("Pause")
    end
end

function pause:keypressed(key)
    if key == "escape" then
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

function pause:leave()
    mouse.setCursor("arrow")
    graphics.buttons = {}
end

return pause