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

M.mouseMap = {
--==================================================--
    [1] = { -- left click
        pressed = function (x, y, g)
            -- check if squad button was clicked
            if g.input.hoveredSquadId then
                local clickedSquad = g.localPlayer.squads[g.input.hoveredSquadId]
                -- new squad
                if g.gamemode ~= "Sandbox" then
                    if clickedSquad == g.localPlayer.squads[#g.localPlayer.squads] then
                        g.localPlayer.squads[g.input.hoveredSquadId + 1] = clickedSquad
                        g.localPlayer.squads[g.input.hoveredSquadId] = {
                            label = "Squad "..tostring(g.input.hoveredSquadId),
                            doodIds = {},
                        }
                    end
                    clickedSquad = g.localPlayer.squads[g.input.hoveredSquadId]
                end
                -- select squads
                if love.keyboard.isDown("lshift") then
                    if clickedSquad then
                        clickedSquad.selected = not clickedSquad.selected
                    end
                else
                    for _, squad in ipairs(g.localPlayer.squads) do
                        squad.selected = squad == clickedSquad
                    end
                end
                graphics.getinfoBarLayout(g)
            end

            local wx, wy = g.camera:worldCoords(x, y)

            -- check if a dood was clicked
            local clickedDood
            if g.input.hoveredDood and g.input.hoveredDood.ownerId == g.localPlayer.id then
                clickedDood = g.input.hoveredDood
            end

            if clickedDood and g.input.hoveredInfoBarDoodId and clickedDood == g.doods[g.input.hoveredInfoBarDoodId] then
                g.input.draggingInfoBarDoodId = g.input.hoveredInfoBarDoodId
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
                g.input.leftClickDown = true
                g.input.selectionBox.startX = wx
                g.input.selectionBox.startY = wy
            end
        end,

        released = function (x, y, g)
            if g.input.draggingInfoBarDoodId then
                local doodId = g.input.draggingInfoBarDoodId
                if g.input.hoveredSquadId then
                    local d = g.doods[doodId]
                    local hoveredSquad = g.localPlayer.squads[g.input.hoveredSquadId]
                    if hoveredSquad.label == "+" then
                        g.localPlayer.squads[g.input.hoveredSquadId + 1] = hoveredSquad
                        g.localPlayer.squads[g.input.hoveredSquadId] = {
                            label = "Squad "..tostring(g.input.hoveredSquadId),
                            doodIds = {},
                        }
                    end
                    local sourceSquad = g.localPlayer.squads[d.squadId]
                    local targetSquad = g.localPlayer.squads[g.input.hoveredSquadId]
                    local sourcePosition
                    for i, id in ipairs(sourceSquad.doodIds) do
                        if id == doodId then
                            sourcePosition = i
                            break
                        end
                    end
                    if sourcePosition and sourceSquad ~= targetSquad then
                        table.remove(sourceSquad.doodIds, sourcePosition)
                        table.insert(targetSquad.doodIds, doodId)
                        d.squadId = g.input.hoveredSquadId
                    end
                end
                g.input.draggingInfoBarDoodId = nil
                graphics.draggingBox = nil
                graphics.getinfoBarLayout(g)
                return
            end

            -- select doods inside selection box
            if g.input.leftClickDown then
                for _, d in ipairs(g.doods) do
                    d.selected = d.insideSelectionBox and not d.playerControlled and d.state ~= "downed"
                    d.insideSelectionBox = false
                end
                g.input.leftClickDown = false
                g.input.selectionBox = {}
                -- graphics.getinfoBarLayout(g)
            end
        end,
    },
--==================================================--
    [2] = { -- right click
        released = function (x, y, g)
            if g.input.hoveringInfoBar then return end
            local wx, wy = g.input.mouseWorldX, g.input.mouseWorldY

            local clickedShrine
            if g.input.hoveredShrineId then
                clickedShrine = g.shrines[g.input.hoveredShrineId]
            end

            local clickedDood
            if g.input.hoveredDood then
                clickedDood = g.input.hoveredDood
            end

            for _, d in ipairs(g.doods) do
                if d.selected and d.state ~= "downed" then
                    if clickedDood then
                        if clickedDood.team ~= d.team then
                            dood.setAttackTarget(d, g, clickedDood.index)
                            d.command = "attack"
                        elseif clickedDood ~= d and clickedDood.team == d.team and clickedDood.state == "downed" and clickedDood.puller == nil then
                            d.rescueTarget = clickedDood
                            d.command = "rescue"
                        end
                    elseif clickedShrine then
                        if clickedShrine.team ~= d.team then
                            if clickedShrine.state == "broken" then
                                dood.setConvertTarget(d, g, clickedShrine.index)
                            else
                                dood.setAttackTarget(d, g, clickedShrine.index, "shrine")
                                d.command = "attack shrine"
                            end
                        else
                            if clickedShrine == "broken" or clickedShrine.hp < clickedShrine.maxHp then
                                dood.setRepairTarget(d, g, clickedShrine.index)
                                d.command = "repair shrine"
                            else
                                dood.clearTargets(d)
                                d.route = nil
                                d.moveTargetX = wx
                                d.moveTargetY = wy
                                d.command = "move"
                            end
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
            g.input.middleMouseDown = true
            M.setCursor("sizeall")
        end,

        released = function (x, y, g)
            g.input.middleMouseDown = false
            M.setCursor("arrow")

        end,
    },
--==================================================--
}



-- game
function M.getHoveredDood(x, y, g)
    g.input.hoveredInfoBarDoodId = nil
    g.input.hoveredDood = nil
    local hoveredInfoBarDood
    if not g.input.leftClickDown then
        for _, doodId in ipairs(graphics.infoBarDoods) do
            local d = g.doods[doodId]
            if M.mouseHover(x, y, d.infoBarBox) then
                g.input.hoveredInfoBarDoodId = doodId
                hoveredInfoBarDood = d
                break
            end
        end
        local frontDepth = -math.huge
        for _, d in ipairs(g.doods) do
            local worldBoxHovered = false
            if not hoveredInfoBarDood and not g.input.leftClickDown then
                worldBoxHovered = M.mouseHover(g.input.mouseWorldX, g.input.mouseWorldY, d.box) and d.sortY and d.sortY > frontDepth
                if worldBoxHovered then
                    frontDepth = d.sortY
                end
            end
            d.hovered = d == hoveredInfoBarDood or worldBoxHovered
            if d.hovered then
                g.input.hoveringAny = true
                g.input.hoveredDood = d
            end
        end
    end
end

function M.mousepressed(x, y, button, g)
    local action = M.mouseMap[button]
    if action and action.pressed then
        action.pressed(x, y, g)
    end
    if not g.input.hoveringDoodsContainer then
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
    local player = g.localPlayer
    g.input.hoveredShrineId = nil
    g.input.hoveredSquadId = nil
    g.input.hoveringAny = false
    g.input.hoveringInfoBar = M.mouseHover(x, y, graphics.infoBarContainer)
    g.input.hoveringDoodsContainer = M.mouseHover(x, y, graphics.doodsContainer)
    g.input.hoveringSquadsContainer = M.mouseHover(x, y, graphics.squadsContainer)

    g.input.mouseWorldX, g.input.mouseWorldY = g.camera:worldCoords(x, y)

    -- shrines
    local hoveredShrineId = nil
    for i, shrine in ipairs(g.shrines) do
        if M.mouseHover(g.input.mouseWorldX, g.input.mouseWorldY, shrine.box) then
            hoveredShrineId = i
            g.input.hoveringAny = true
            break
        end
    end
    if hoveredShrineId then
        g.input.hoveredShrineId = hoveredShrineId
    end

    -- middle mouse panning
    if g.input.middleMouseDown then
        g.camera:lookAt(g.camera.x - dx, g.camera.y - dy)
        return
    end

    -- selection box
    if g.input.leftClickDown and not g.input.hoveringAny then
        g.input.selectionBox.x = math.min(g.input.selectionBox.startX, g.input.mouseWorldX)
        g.input.selectionBox.y = math.min(g.input.selectionBox.startY, g.input.mouseWorldY)
        g.input.selectionBox.w = math.abs(g.input.mouseWorldX - g.input.selectionBox.startX)
        g.input.selectionBox.h = math.abs(g.input.mouseWorldY - g.input.selectionBox.startY)
        for _, d in ipairs(g.doods) do
            if d.ownerId == player.id then
                d.insideSelectionBox = M.mouseHover(d.bodyX, d.bodyY, g.input.selectionBox)
            end
        end
        return
    end

    M.getHoveredDood(x, y, g)

    if g.input.draggingInfoBarDoodId and love.mouse.isDown(1) then
        graphics.getDraggingBox(x, y, g)
    end

    --squads
    if g.input.hoveringSquadsContainer then
        for i, squad in ipairs(g.localPlayer.squads) do
            squad.infoBarButton.hovered = M.mouseHover(x, y, squad.infoBarButton.box) and not g.input.leftClickDown
            if squad.infoBarButton.hovered then
                g.input.hoveredSquadId = i
                g.input.hoveringAny = true
            end
        end
    end

    if not g.input.leftClickDown and not g.input.middleMouseDown then
        if g.input.hoveringAny then
            M.setCursor("hand")
        else
            M.setCursor("arrow")
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
    M.resolveModalButtonHover(x, y, state)
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

return M