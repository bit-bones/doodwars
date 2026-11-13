local mouse = require "mouse"
local Gamestate = require "libs/hump/gamestate"
local ui = require "ui"
local graphics = require "graphics"
local colors = graphics.colors

local options = {}

function options:init()
    self.tabs = {
        {label = "Video"}
    }
end

function options:enter(previous)
    self.previous = previous
    self.previous.drawModal = false
    graphics.getModalLayout(self.tabs)
end

function options:draw()
    self.previous:draw()
    ui.modal("Options")
end

function options:keypressed(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

function options:resize()
    graphics.getModalLayout()
end

function options:leave()
    self.previous.drawModal = true
    graphics.getModalLayout(self.previous.buttons)
end

return options