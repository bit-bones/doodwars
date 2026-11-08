local Gamestate = require "libs/hump/gamestate"

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

function pause:draw()
    self.previous:draw()

    local pc = getColor()

    setColor(colors.transparentGray)
    love.graphics.rectangle("fill", screen.centerX - screen.w / 2, screen.centerY - screen.h / 2, screen.w / 2, screen.h / 2, 5, 5)

    setColor(colors.white)
    love.graphics.setFont(fonts.slabsPause)
    love.graphics.printf("Pause", screen.centerX - screen.w / 2, screen.centerY - screen.h / 2, 500, "center")

    setColor(pc)
end

function pause:keypressed(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

return pause