local M = {}

M.fonts = {
    debugWorld = love.graphics.newFont(10),
    debugHud = love.graphics.newFont(12),
    slabsTitle = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 75),
    slabsButtons = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 40),
    slabsInfoBar = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 15),
    squadButtons = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 20),
}

M.fontHeights = {}
for i, font in pairs(M.fonts) do
    M.fontHeights[i] = font:getHeight()
end

local hudTransparency = 0.8

M.colors = {
    neutral =              {1, 1, 1, 1},
    dimNeutral =           {0.7, 0.7, 0.7, 1},
    transparentGray =      {0, 0, 0, 0.25},
    selectionBoxOutline =  {0.1, 1, 0.1, 1},
    selectionBoxFill =     {0.1, 1, 0.1, 0.1},
    neutralHud =           {0.7, 0.7, 0.7, hudTransparency},
    Blue =                 {0.2, 0.35, 0.5},
    BlueHud =              {0.2, 0.35, 0.5, hudTransparency},
    Red =                  {0.6, 0.2, 0.2},
    RedHud =               {0.6, 0.2, 0.2, hudTransparency},
    Yellow =               {0.55, 0.5, 0.1},
    YellowHud =            {0.55, 0.5, 0.1, hudTransparency},
    Green =                {0.35, 0.55, 0.15},
    GreenHud =             {0.35, 0.55, 0.15, hudTransparency},
}
M.backgrounds = {M.colors.Blue, M.colors.Red, M.colors.Yellow, M.colors.Green}

M.maxScissorOffset = 0
M.buttonScissorOffset = 0
M.titleSpacing = 50
M.infoBarScissorOffset = 0
M.screen = {}
M.modalContainer = {}

local buttonPadding = 150
local buttonH = M.fontHeights.slabsButtons * 2

function M.getScreen()
    M.screen.w, M.screen.h = love.graphics.getDimensions()
    M.screen.centerX = M.screen.w / 2
    M.screen.centerY = M.screen.h / 2
end

function M.getinfoBarLayout(g)
    M.infoBarDoods = {}
    M.infoBarContainer = {}
    M.selectedDoods = {}
    M.getScreen()

    M.infoBarContainer.h = 175
    M.infoBarContainer.w = M.screen.w
    M.infoBarContainer.y = 0 + M.screen.h - M.infoBarContainer.h
    M.infoBarContainer.x = 0
    M.infoBarContainer.centerY = M.infoBarContainer.y + M.infoBarContainer.h / 2

    M.squadsContainer = {
        h = M.infoBarContainer.h - 10,
        w = 180,
        x = M.infoBarContainer.x + 5,
        y = M.infoBarContainer.y + 5,
    }

    M.doodsContainer = {
        x = M.squadsContainer.x + M.squadsContainer.w + 5,
        y = M.infoBarContainer.y + 5,
        w = M.infoBarContainer.w - M.squadsContainer.w - 15,
        h = M.squadsContainer.h
    }

    if g.localPlayer.squads then
        for i, squad in ipairs(g.localPlayer.squads) do
            local height = M.fontHeights.squadButtons + 10
            local offset = height * i
            squad.infoBarButton = {
                box = {
                    x = M.squadsContainer.x,
                    y = M.squadsContainer.y + offset - 20,
                    w = M.squadsContainer.w,
                    h = height,
                },
            }
            squad.infoBarButton.labelY = squad.infoBarButton.box.y + (squad.infoBarButton.box.h / 2) - (M.fontHeights.slabsInfoBar / 2)

            if squad.selected and squad.doodIds and #squad.doodIds > 0 then
                for _, doodId in ipairs(squad.doodIds) do
                    table.insert(M.infoBarDoods, doodId)
                end
            end
        end

        for i, doodId in ipairs(M.infoBarDoods) do
            local size = 126
            local offset = size * i
            g.doods[doodId].infoBarBox = {
                x = M.squadsContainer.x + M.squadsContainer.w + offset - 100 - M.infoBarScissorOffset,
                y = M.infoBarContainer.centerY - size / 2,
                w = size,
                h = size,
            }
        end
    end
end

function M.getModalLayout(mainButtons, bottomButtons)
    M.getScreen()

    M.modalContainer.w = 850
    M.modalContainer.h = 850
    M.modalContainer.x = M.screen.centerX - M.modalContainer.w / 2
    M.modalContainer.y = M.screen.centerY - M.modalContainer.h / 2
    M.modalContainer.titleY = M.modalContainer.y + M.titleSpacing

    local bottomButtonW = (M.modalContainer.w - buttonPadding * 2) / 2

    M.buttonScissor = {
        x = M.modalContainer.x + buttonPadding - 10,
        y = M.modalContainer.y + M.fontHeights.slabsTitle + (M.titleSpacing * 2),
        w = (M.modalContainer.w - buttonPadding * 2) + 20,
        h = M.modalContainer.h - (M.fontHeights.slabsTitle * 2) - (M.titleSpacing * 4)
    }

    M.mainButtons = mainButtons or M.mainButtons
    if M.mainButtons then
        local requiredH = #M.mainButtons * buttonH
        M.maxScissorOffset = math.max(0, requiredH - M.buttonScissor.h)
        local topY = M.buttonScissor.y
        if requiredH <= M.buttonScissor.h then
            topY = topY + (M.buttonScissor.h - requiredH) / 2
        end
        M.buttonScissorOffset = math.max(0, math.min(M.maxScissorOffset, M.buttonScissorOffset))
        for i, button in ipairs(M.mainButtons) do
            button.box = {
                x = M.modalContainer.x + buttonPadding,
                y = topY + (i - 1) * buttonH - M.buttonScissorOffset,
                w = M.modalContainer.w - buttonPadding * 2,
                h = buttonH,
            }
            button.textY = button.box.y + button.box.h / 4
        end
    end

    M.bottomButtons = bottomButtons or M.bottomButtons
    if #M.bottomButtons > 0 then
        for i, button in ipairs(M.bottomButtons) do
            if #M.bottomButtons == 1 then
                button.box = {
                x = M.modalContainer.x + M.modalContainer.w / 2 - bottomButtonW / 2,
            }
            elseif #M.bottomButtons == 2 then
                button.offset = i * bottomButtonW
                button.box = {
                x = M.modalContainer.x + buttonPadding + button.offset - (M.buttonScissor.w / 2),
            }
            elseif #M.bottomButtons == 3 then
                button.offset = i * bottomButtonW
                button.box = {
                x = M.modalContainer.x + buttonPadding + button.offset - (bottomButtonW * 1.5),
            }
            end
            button.box.y = M.buttonScissor.y + M.buttonScissor.h + (buttonH / 2)
            button.box.h = buttonH
            button.box.w = bottomButtonW
            button.textY = button.box.y + button.box.h / 4
        end
    end
end

function M.rectangle(mode, x, y, width, height, rx, ry, segments)
    if type(x) == "table" then
        local box = x
        x = box.x
        y = box.y
        width = box.w
        height = box.h
    end
    love.graphics.rectangle(mode, x, y, width, height, rx, ry, segments)
end

function M.getColor()
    return {love.graphics.getColor()}
end

function M.setColor(r, g, b, a)
    if r and not g then
        love.graphics.setColor(r)
    else
        a = a or 1
        love.graphics.setColor(r, g, b, a)
    end
end

return M