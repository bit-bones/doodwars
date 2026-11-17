local dood = require "dood"
local graphics = require "graphics"

local M = {}

function M.setCursor(cursor)
    love.mouse.setCursor(love.mouse.getSystemCursor(cursor))
end

function M.mouseHover(x, y, rectangle)
    if rectangle == nil then
        return false
    end
    return x > rectangle.x and x < rectangle.x + rectangle.w and y > rectangle.y and y < rectangle.y + rectangle.h
end

local states = {}

M.mouseMap = {
--==================================================--
    [1] = { -- left click
        pressed = function (x, y, g)
            local wx, wy = g.camera:worldCoords(x, y)

            -- check if a dood was clicked
            local clickedDood
            if g.hoveredDood then
                clickedDood = g.hoveredDood
            elseif g.hoveredInfoBarDood then
                clickedDood = g.hoveredInfoBarDood
            end
            -- toggle player control
            if love.keyboard.isDown("lctrl") then
                if clickedDood and clickedDood.state ~= "downed" then
                    clickedDood.command = nil
                    clickedDood.moveTargetX = nil
                    clickedDood.moveTargetY = nil

                    if clickedDood == g.controlledDood then
                        clickedDood.scanTimer = 0
                        g.controlledDood = nil
                    else
                        g.controlledDood = clickedDood
                        clickedDood.selected = false
                    end
                end
            -- select doods cumulatively
            elseif love.keyboard.isDown("lshift") then
                if clickedDood and clickedDood ~= g.controlledDood then
                    clickedDood.selected = not clickedDood.selected
                end
            -- hurt dood
            elseif love.keyboard.isDown("x") then
                if clickedDood then
                    if clickedDood.state ~= "downed" and clickedDood.hp > 0 then
                        clickedDood.animation = clickedDood.animations.hurt
                        clickedDood.hurtTimer = dood.DEFAULTS.HURT_TIME
                        clickedDood.hp = clickedDood.hp - 50
                    end
                end

            else
                for _, d in ipairs(g.doods) do
                    d.selected = (clickedDood ~= g.controlledDood and d == clickedDood)
                end
            end

            for _, d in ipairs(g.doods) do
                d.playerControlled = (d == g.controlledDood)
            end

            if clickedDood == nil then
                states.leftClickDown = true
                g.selectionBox.startX = wx
                g.selectionBox.startY = wy
            end
        end,

        released = function (x, y, g)
            -- select doods inside selection box
            if states.leftClickDown then
                for _, d in ipairs(g.doods) do
                    d.selected = d.insideSelectionBox and not d.playerControlled
                    d.insideSelectionBox = false
                end
                states.leftClickDown = false
                g.selectionBox = {}
                graphics.getinfoBarLayout(g)
            end
        end,
    },
--==================================================--
    [2] = { -- right click
        released = function (x, y, g)
            if g.hoveringInfoBar then return end
            local wx, wy = g.mouseWorldX, g.mouseWorldY
            local clickedDood
            if g.hoveredDood then
                clickedDood = g.hoveredDood
            end

            for _, d in ipairs(g.doods) do
                if d.selected and d.state ~= "downed" then
                    if clickedDood then
                        if clickedDood.color ~= d.color then
                            dood.setAttackTarget(d, g, clickedDood.index)
                            d.command = "attack"
                        elseif clickedDood ~= d and clickedDood.color == d.color and clickedDood.state == "downed" and clickedDood.puller == nil then
                            d.rescueTarget = clickedDood
                            d.command = "rescue"
                        end
                    else
                        dood.clearTargets(d)
                        d.route = nil
                        d.moveTargetX = wx
                        d.moveTargetY = wy
                        d.command = "move"
                    end
                end
            end
        end,
    },
--==================================================--
    [3] = { -- middle mouse button
        pressed = function (x, y, g)
            states.middleMouseDown = true
            M.setCursor("sizeall")
        end,

        released = function (x, y, g)
            states.middleMouseDown = false
            M.setCursor("arrow")

        end,
    },
--==================================================--
}



-- game
function M.mousepressed(x, y, button, g)
    local action = M.mouseMap[button]
    if action and action.pressed then
        action.pressed(x, y, g)
    end
    if not g.hoveringInfoBar then
        graphics.infoBarScissorOffset = 0
    end
    graphics.getinfoBarLayout(g)
end

function M.mousereleased(x, y, button, g)
    local action = M.mouseMap[button]
    if action and action.released then
        action.released(x, y, g)
    end
end

function M.mousemoved(x, y, dx, dy, g)
    g.hoveredSquadButton = nil
    g.hoveringInfoBar = M.mouseHover(x, y, graphics.infoBarContainer)
    g.hoveredDood = nil
    g.mouseWorldX, g.mouseWorldY = g.camera:worldCoords(x, y)

    -- selection box
    if states.leftClickDown then
        g.selectionBox.x = math.min(g.selectionBox.startX, g.mouseWorldX)
        g.selectionBox.y = math.min(g.selectionBox.startY, g.mouseWorldY)
        g.selectionBox.w = math.abs(g.mouseWorldX - g.selectionBox.startX)
        g.selectionBox.h = math.abs(g.mouseWorldY - g.selectionBox.startY)
    end

    -- middle mouse panning
    if states.middleMouseDown then
        g.camera:lookAt(g.camera.x - dx, g.camera.y - dy)
    end

    dood.getHoveredDood(x, y, g)

    -- if g.hoveringInfoBar then
    --     for _, squad in ipairs(g.player.squads) do
    --         squad.infoBarButton.hovered = M.mouseHover(x, y, squad.infoBarButton.box)
    --         if squad.infoBarButton.hovered then
    --             g.hoveredSquadButton = squad
    --             states.hoveringAny = true
    --         end
    --     end
    -- end

    if not g.draggingSelectionBox and not g.mouseStates.middleMouseDown then
        if states.hoveringAny then
            M.setCursor("hand")
        else
            M.setCursor("arrow")
            states.hoveringAny = false
        end
    end
end

-- modal
function M.resolveModalButtonHover(x, y, state)
    local hoveringAnyButton = false
    for _, button in ipairs(graphics.mainButtons) do
        button.hovered = M.mouseHover(x, y, button.box)
        if button.hovered then
            state.hoveredButton = button
            hoveringAnyButton = true
        end
    end
    for _, button in ipairs(graphics.bottomButtons) do
        button.hovered = M.mouseHover(x, y, button.box)
        if button.hovered then
            state.hoveredButton = button
            hoveringAnyButton = true
        end
    end
    if hoveringAnyButton then
        M.setCursor("hand")
    else
        M.setCursor("arrow")
        state.hoveredButton = nil
    end
end

function M.modalWheelMoved(x, y, state)
    if M.hoveringModalScissor then
        if y > 0 then
            graphics.buttonScissorOffset = graphics.buttonScissorOffset - 20
        elseif y < 0 then
            graphics.buttonScissorOffset = graphics.buttonScissorOffset + 20
        end
        graphics.buttonScissorOffset = math.max(0, math.min(graphics.maxScissorOffset, graphics.buttonScissorOffset))
        graphics.getModalLayout()
    end
end

function M.modalMousepressed(x, y, mouseButton, state)
    if mouseButton ~= 1 then return end
    -- M.resolveModalButtonHover(x, y, state)
    if state.hoveredButton then
        if state.hoveredButton.fn then
            state.hoveredButton.fn()
        end
    end
    M.resolveModalButtonHover(x, y, state)
end

function M.modalMousemoved(x, y, state)
    M.hoveringModalScissor = M.mouseHover(x, y, graphics.buttonScissor)
    M.resolveModalButtonHover(x, y, state)
end

M.states = states

return M