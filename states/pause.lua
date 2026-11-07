local Gamestate = require "libs/hump/gamestate"
local graphics = require "graphics"
local screen = graphics.screen

local pause = {}

function pause:enter(previous)
    self.previous = previous
end

function pause:draw()
    self.previous:draw()

    local pc = graphics.getColor()
    graphics.setColor(0, 0, 0, 0.1)
    love.graphics.rectangle("fill", screen.centerX - screen.w / 2, screen.centerY - screen.h / 2, screen.w / 2, screen.h / 2, 5, 5)
    graphics.setColor(1,1,1,1)
    love.graphics.setFont(graphics.fonts.slabsPause)
    love.graphics.printf("Pause", screen.centerX - screen.w / 2, screen.centerY - screen.h / 2, 500, "center")
    graphics.setColor(pc)
end

function pause:keypressed(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

return pause