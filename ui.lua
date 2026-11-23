local Gamestate = require "libs/hump/gamestate"
local graphics = require "graphics"
local fonts = graphics.fonts
local fontHeights = graphics.fontHeights
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor
local rectangle = graphics.rectangle
local setScissor = graphics.setScissor

local M = {}

M.backButton = {
    label = "Back",
    fn = function ()
        local state = Gamestate.current()
        state.escapePressed()
    end
}

function M.draggingBox(g)
    if g.input.draggingInfoBarDoodId and love.mouse.isDown(1) and graphics.draggingBox then
        local name = g.doods[g.input.draggingInfoBarDoodId].name
        local pf = love.graphics.getFont()
        local pc = getColor()
        setColor(colors.transparentGray)
        rectangle("fill", graphics.draggingBox)
        setColor(colors.neutral)
        love.graphics.setFont(fonts.slabsInfoBar)
        graphics.printC(name, graphics.draggingBox, fontHeights.slabsInfoBar)
        love.graphics.setFont(pf)
        setColor(pc)
    end
end

function M.drawHealthBar(value, max, x, y, w, h)
    local plw = love.graphics.getLineWidth()
    local pc = getColor()

    setColor(colors.transparentGray)
    love.graphics.setLineWidth(2)
    graphics.rectangle("line", x, y, w, h)

    local percent = math.max(0, math.min(1, value / max))
    local color = colors.Green
    if percent <= 0.50 then
        color = colors.Yellow
    end
    if percent <= 0.20 then
        color = colors.Red
    end
    setColor(color)
    love.graphics.rectangle("fill", x, y, w * percent, h)
    -- setColor(colors.transparentGray)
    -- love.graphics.printf(percent * 100, x, y, w, "center")

    love.graphics.setLineWidth(plw)
    setColor(pc)
end

function M.infoBar(g)
    local previousFont = love.graphics.getFont()
    local previousColor = getColor()

    -- background
    setColor((colors[g.localPlayer.team.."Hud"] or colors.neutralHud))
    rectangle("fill", graphics.infoBarContainer)
    setColor(colors.transparentGray)
    rectangle("fill", graphics.squadsContainer)
    rectangle("fill", graphics.doodsContainer)

    -- squads container
    setScissor(graphics.squadsContainer)
    setColor(colors.neutral)
    love.graphics.setFont(fonts.squadButtons)
    for _, squad in ipairs(g.localPlayer.squads) do
        local button = squad.infoBarButton
        if squad.selected then
            local pc = getColor()
            setColor(colors.transparentGray)
            rectangle("fill", button.box, 5, 5)
            setColor(pc)
        end
        love.graphics.printf(squad.label, button.box.x, button.labelY, button.box.w, "center")
    end
    if g.input.hoveredSquadId then
        local button = g.localPlayer.squads[g.input.hoveredSquadId].infoBarButton
        rectangle("line", button.box, 5, 5)
    end

    -- doods container
    setScissor(graphics.doodsContainer)
    for _, doodId in ipairs(graphics.infoBarDoods) do
        local d = g.doods[doodId]
        if d.selected then
            setColor(colors.transparentGray)
            rectangle("fill", d.infoBarBox)
        end
        setColor(colors.neutral)
        d.animation[d.dir]:draw(
            d.animation.image,
            d.infoBarBox.x,
            d.infoBarBox.y,
            0, 4, 4
        )
        love.graphics.setFont(fonts.slabsInfoBar)
        M.drawHealthBar(d.hp, d.maxHp, d.infoBarBox.x + 10, d.infoBarBox.y + 5, d.infoBarBox.w - 20, 5)
        love.graphics.printf(d.name, d.infoBarBox.x, d.infoBarBox.y + 15, d.infoBarBox.w, "center")
        love.graphics.printf(d.state, d.infoBarBox.x, d.infoBarBox.y + d.infoBarBox.h - fontHeights.slabsInfoBar - 5, d.infoBarBox.w, "center")
    end
    if g.input.hoveredDood then
        local d = g.input.hoveredDood
        if g.localPlayer.squads[d.squadId].selected and d.ownerId == g.localPlayer.id then
            love.graphics.setLineWidth(2)
            setColor(d.boxColor or colors.neutral)
            rectangle("line", d.infoBarBox)
            love.graphics.setLineWidth(1)
        end
    end

    love.graphics.setFont(previousFont)
    setScissor()
    setColor(previousColor)
end

function M.modal(titleText, tabs)
    local previousColor = getColor()
    local previousFont = love.graphics.getFont()
    local modalContainer = graphics.modalContainer
    local buttonScissor = graphics.buttonScissor

    setColor(colors.transparentGray)
    rectangle("fill", graphics.modalContainer, 10, 10)
    setColor(colors.neutral)
    love.graphics.setFont(fonts.slabsTitle)
    love.graphics.printf(titleText, modalContainer.x, modalContainer.titleY, modalContainer.w, "center")
    love.graphics.line(buttonScissor.x, buttonScissor.y, buttonScissor.x + buttonScissor.w, buttonScissor.y)
    setScissor(buttonScissor)
    love.graphics.setFont(fonts.slabsButtons)
    for _, button in ipairs(graphics.mainButtons) do
        if button.drawFill then
            local pc = getColor()
            setColor(0.8, 0.8, 0.8, 0.9)
            rectangle("fill", button.box.x + 1, button.box.y + 1, button.box.w - 2, button.box.h - 2, 9, 9)
            setColor(pc)
        end
        if button.hovered then
            local pc = getColor()
            rectangle("line", button.box, 10, 10)
            setColor(pc)
        end
        if button.label then
            local pc = getColor()
            setColor((button.labelColor or colors.neutral))
            love.graphics.printf(button.label, button.box.x, button.textY, button.box.w, "center")
            setColor(pc)
        end
        if button.context then
            local pf = love.graphics.getFont()
            local pc = getColor()
            love.graphics.setFont(fonts.squadButtons)
            setColor((button.context.color or colors.neutral))
            love.graphics.printf(button.context.text, button.box.x + 20, button.textY + fontHeights.squadButtons / 2, button.box.w, "left")
            setColor(pc)
            love.graphics.setFont(pf)
        end
    end
    setScissor()

    if graphics.bottomButtons and #graphics.bottomButtons > 0 then
        setColor(colors.neutral)

        love.graphics.line(buttonScissor.x, buttonScissor.y + buttonScissor.h, buttonScissor.x + buttonScissor.w, buttonScissor.y + buttonScissor.h)
        for _, button in ipairs(graphics.bottomButtons) do
            if button.hovered then
                rectangle("line", button.box, 10, 10)
            end
            if button.label then
                local pc = getColor()
                setColor((button.labelColor or colors.neutral))
                love.graphics.printf(button.label, button.box.x, button.textY, button.box.w, "center")
                setColor(pc)
            end
        end
    end

    setColor(previousColor)
    love.graphics.setFont(previousFont)
end

return M
