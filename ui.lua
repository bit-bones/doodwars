local mouse = require "mouse"
local graphics = require "graphics"
local Gamestate = require "libs/hump/gamestate"
local fonts = graphics.fonts
local fontHeights = graphics.fontHeights
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor

local rectangle = love.graphics.rectangle

local M = {}

M.backButton = {
    label = "Back",
    fn = function ()
        local state = Gamestate.current()
        state.escapePressed()
    end
}

function M.infoBar(g)
    local previousFont = love.graphics.getFont()
    local previousColor = getColor()
    local container = graphics.infoBarContainer
    local squadsContainer = graphics.squadsContainer
    local doodsContainer = graphics.doodsContainer

    -- background
    setColor(0, 0, 0, 0.3)
    rectangle("fill", container.x, container.y, container.w, container.h)
    setColor(0, 0, 0, 0.2)
    rectangle("fill", squadsContainer.x, squadsContainer.y, squadsContainer.w, squadsContainer.h)
    rectangle("fill", doodsContainer.x, doodsContainer.y, doodsContainer.w, doodsContainer.h)

    -- -- squads container
    -- love.graphics.setScissor(squadsContainer.x, squadsContainer.y, squadsContainer.w, squadsContainer.h)
    -- setColor(colors.neutral)
    -- love.graphics.setFont(fonts.squadButtons)
    -- for _, squad in ipairs(g.player.squads) do
    --     local button = squad.infoBarButton
    --     love.graphics.printf(squad.label, button.box.x, button.labelY, button.box.w, "center")
    --     if button.hovered then
    --         rectangle("line", button.box.x, button.box.y, button.box.w, button.box.h, 5, 5)
    --     end
    -- end
    -- doods container
    love.graphics.setScissor(doodsContainer.x, doodsContainer.y, doodsContainer.w, doodsContainer.h)
    love.graphics.setLineWidth(3)
    for _, d in ipairs(graphics.selectedDoods) do
        if d.hovered then
            setColor(0.15, 0.15, 0.15, 0.9)
            rectangle("fill", d.infoBarBox.x, d.infoBarBox.y, d.infoBarBox.w, d.infoBarBox.h)
        end
        setColor(colors[d.color])
        rectangle("line", d.infoBarBox.x, d.infoBarBox.y, d.infoBarBox.w, d.infoBarBox.h)
        setColor(colors.neutral)
        d.animation[d.dir]:draw(
            d.animation.image,
            d.infoBarBox.x,
            d.infoBarBox.y,
            0, 4, 4
        )
        love.graphics.setFont(fonts.slabsInfoBar)
        love.graphics.printf(d.name, d.infoBarBox.x, d.infoBarBox.y + 5, d.infoBarBox.w, "center")
        love.graphics.printf(d.state, d.infoBarBox.x, d.infoBarBox.y + d.infoBarBox.h - fontHeights.slabsInfoBar - 5, d.infoBarBox.w, "center")
    end

    love.graphics.setLineWidth(1)
    love.graphics.setScissor()
    love.graphics.setFont(previousFont)
    setColor(previousColor)
end

function M.modal(titleText, tabs)
    local previousColor = getColor()
    local previousFont = love.graphics.getFont()
    local container = graphics.modalContainer
    local buttonScissor = graphics.buttonScissor

    setColor(colors.transparentGray)
    rectangle("fill", container.x, container.y, container.w, container.h, 10, 10)
    setColor(colors.neutral)
    love.graphics.setFont(fonts.slabsTitle)
    love.graphics.printf(titleText, container.x, container.titleY, container.w, "center")
    love.graphics.line(buttonScissor.x, buttonScissor.y, buttonScissor.x + buttonScissor.w, buttonScissor.y)
    love.graphics.setScissor(buttonScissor.x, buttonScissor.y, buttonScissor.w, buttonScissor.h)
    love.graphics.setFont(fonts.slabsButtons)
    for _, button in ipairs(graphics.mainButtons) do
        if button.hovered then
            rectangle("line", button.box.x, button.box.y, button.box.w, button.box.h, 10, 10)
        end
        if button.label then
            love.graphics.printf(button.label, button.box.x, button.textY, button.box.w, "center") 
        end
        if button.context then
            local pf = love.graphics.getFont()
            local pc = getColor()
            love.graphics.setFont(fonts.squadButtons)
            setColor(colors.dimNeutral)
            love.graphics.printf(button.context, button.box.x, button.textY, button.box.w, "left")
            setColor(pc)
            love.graphics.setFont(pf)
        end
    end
    love.graphics.setScissor()

    if graphics.bottomButtons and #graphics.bottomButtons > 0 then
        love.graphics.line(buttonScissor.x, buttonScissor.y + buttonScissor.h, buttonScissor.x + buttonScissor.w, buttonScissor.y + buttonScissor.h)
        for _, button in ipairs(graphics.bottomButtons) do
            if button.hovered then
                rectangle("line", button.box.x, button.box.y, button.box.w, button.box.h, 10, 10)
            end
            if button.label then
                love.graphics.printf(button.label, button.box.x, button.textY, button.box.w, "center") 
            end
        end
    end

    setColor(previousColor)
    love.graphics.setFont(previousFont)
end

return M
