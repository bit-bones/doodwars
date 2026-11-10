local mouse = require "mouse_map"
local graphics = require "graphics"
local container = graphics.container
local fonts = graphics.fonts
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor

local M = {}

function M.drawModal(titleText)
    local rectangle = love.graphics.rectangle
    local previousColor = getColor()
    local titleY = container.y + 50

    setColor(colors.transparentGray)
    rectangle("fill", container.x, container.y, container.w, container.h, 10, 10)
    setColor(colors.white)
    love.graphics.setFont(fonts.slabsTitle)
    love.graphics.printf(titleText, container.x, titleY, container.w, "center")
    love.graphics.setFont(fonts.slabsButtons)
    for _, button in ipairs(graphics.buttons) do
        if button.hovered then
            rectangle("line", button.box.x, button.box.y, button.box.w, button.box.h, 10, 10)
        end
        love.graphics.printf(button.label, button.box.x, button.textY, button.box.w, "center")
    end

    setColor(previousColor)
end

return M