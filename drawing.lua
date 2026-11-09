local graphics = require "graphics"
local container = graphics.container
local title = graphics.title
local screen = graphics.screen
local fonts = graphics.fonts
local fontHeights = graphics.fontHeights
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor

local M = {}

function M.drawModal(titleText, buttons)
    local previousColor = getColor()
    local titleY = container.y + 50

    setColor(colors.transparentGray)
    love.graphics.rectangle("fill", container.x, container.y, container.w, container.h)
    setColor(colors.white)
    love.graphics.setFont(fonts.slabsTitle)
    love.graphics.printf(titleText, container.x, titleY, container.w, "center")
    love.graphics.setFont(fonts.slabsButtons)
    for i, button in ipairs(buttons) do
        local offset = i * fontHeights.slabsButtons * 2
        love.graphics.printf(button.label, container.x, screen.centerY + offset, container.w, "center")
    end

    setColor(previousColor)
end

return M