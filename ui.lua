local mouse = require "mouse"
local graphics = require "graphics"
local fonts = graphics.fonts
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor
local rectangle = love.graphics.rectangle

local M = {}

function M.infoBar(g)
    local previousColor = getColor()
    local container = graphics.infoBarContainer

    setColor(colors.transparentGray)
    rectangle("fill", container.x, container.y, container.w, container.h)
    setColor(colors.neutral)
    for i, d in ipairs(g.doods) do
        local currentDood = d
        if currentDood.selected then
            currentDood.animation[currentDood.dir]:draw(
                currentDood.animation.image,
                container.x + 20,
                container.y + 20,
                0, 4, 4
            )
            love.graphics.printf(currentDood.state, container.x + 20, container.y + 50, container.w, "center")
        end
    end

    setColor(previousColor)
end

function M.modal(titleText, tabs)
    local previousColor = getColor()
    local previousFont = love.graphics.getFont()
    local container = graphics.modalContainer
    local titleY = container.y + 50

    setColor(colors.transparentGray)
    rectangle("fill", container.x, container.y, container.w, container.h, 10, 10)
    setColor(colors.neutral)
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
    love.graphics.setFont(previousFont)
end

return M