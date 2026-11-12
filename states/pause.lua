local mouse = require "mouse_map"
local Gamestate = require "libs/hump/gamestate"
local options = require "states.options"
local drawing = require "drawing"
local graphics = require "graphics"
local hoveredButton

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
    mouse.M.setCursor("arrow")
end

function pause:draw()
    self.previous:draw()
    if self.drawModal then
        drawing.modal("Pause")
    end
end

function pause:keypressed(key)
    if key == "escape" then
        mouse.M.setCursor("arrow")
        Gamestate.pop()
    end
end

function pause:mousemoved(x, y)
    local hoveringAnyButton = false
    for _, button in ipairs(graphics.buttons) do
        button.hovered = mouse.M.mouseHover(x, y, button.box)
        if button.hovered then
            self.hoveredButton = button
            hoveringAnyButton = true
        end
    end
    if hoveringAnyButton then
        mouse.M.setCursor("hand")
    else
        mouse.M.setCursor("arrow")
        self.hoveredButton = nil
    end
end

function pause:mousepressed(x, y, inputButton)
    mouse.M.setCursor("arrow")
    if self.hoveredButton then
        print("clicked "..self.hoveredButton.label)
        if self.hoveredButton.fn then
            self.hoveredButton.fn()
        end
    end
end

function pause:resize()
    graphics.getModalLayout()
end

return pause