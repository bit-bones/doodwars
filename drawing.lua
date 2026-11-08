local graphics = require "graphics"
local screen = graphics.screen
local fonts = graphics.fonts
local fontHeights = graphics.fontHeights
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor

local M = {}

local containerW = screen.w / 2
local containerH = screen.h / 1.5
local container = {
    x = screen.centerX - containerW / 2,
    y = screen.centerY - containerH / 1.5,
    w = containerW,
    h = containerH,
}

local title = { 
    x = container.x,
    y = container.y + 20,
}

function M.drawModal(titleText, buttons)

    local previousColor = getColor()

    setColor(colors.transparentGray)
    love.graphics.rectangle("fill", container.x, container.y, container.w, container.h)

    setColor(colors.white)
    love.graphics.setFont(fonts.slabsTitle)
    love.graphics.printf(titleText, title.x, title.y, container.x + container.w, "center")

    setColor(previousColor)
end

return M