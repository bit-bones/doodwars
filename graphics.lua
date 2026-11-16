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

M.colors = {
    neutral =              {1, 1, 1, 1},
    dimNeutral =           {0.7, 0.7, 0.7, 1},
    transparentGray =      {0, 0, 0, 0.25},
    selectionBoxOutline =  {0.1, 1, 0.1, 1},
    selectionBoxFill =     {0.1, 1, 0.1, 0.1},
    blue =                 {0.2, 0.35, 0.5},
    red =                  {0.6, 0.2, 0.2},
    yellow =               {0.55, 0.5, 0.1},
    green =                {0.35, 0.55, 0.15},
}
M.backgrounds = {M.colors.blue, M.colors.red, M.colors.yellow, M.colors.green}

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

    -- if g.player.squads then
    --     for i, squad in ipairs(g.player.squads) do
    --         local height = M.fontHeights.squadButtons + 10
    --         local offset = height * i
    --         squad.infoBarButton = {
    --             box = {
    --                 x = M.squadsContainer.x,
    --                 y = M.squadsContainer.y + offset - 20,
    --                 w = M.squadsContainer.w,
    --                 h = height,
    --             },
    --         }
    --         squad.infoBarButton.labelY = squad.infoBarButton.box.y + (squad.infoBarButton.box.h / 2) - (M.fontHeights.slabsInfoBar / 2)
    --     end
    -- end

    if g.doods then
        for _, d in ipairs(g.doods) do
            if d.selected then
                table.insert(M.selectedDoods, d)
            end
        end
    end

    for i, d in ipairs(M.selectedDoods) do
        local size = 126
        local offset = size * i
        d.infoBarBox = {
            x = M.squadsContainer.x + M.squadsContainer.w + offset - 100 - M.infoBarScissorOffset,
            y = M.infoBarContainer.centerY - size / 2,
            w = size,
            h = size,
        }
    end
end

function M.getModalLayout(buttons, bottomButtons)
    M.getScreen()

    M.modalContainer.w = 800
    M.modalContainer.h = 900
    M.modalContainer.x = M.screen.centerX - M.modalContainer.w / 2
    M.modalContainer.y = M.screen.centerY - M.modalContainer.h / 2
    M.modalContainer.titleY = M.modalContainer.y + M.titleSpacing

    M.buttonScissor = {
        x = M.modalContainer.x + buttonPadding,
        y = M.modalContainer.y + M.fontHeights.slabsTitle + (M.titleSpacing * 2),
        w = M.modalContainer.w - buttonPadding * 2,
        h = M.modalContainer.h - (M.fontHeights.slabsTitle * 2) - (M.titleSpacing * 4)
    }

    -- bottomY = M.modalContainer.y + M.modalContainer.h - M.fontHeights.slabsTitle - (M.titleSpacing * 2)

    M.buttons = buttons or M.buttons
    if M.buttons then
        local topY = M.screen.centerY - ((#M.buttons * buttonH) / 2)
        M.anyBottomButtons = false
        for i, button in ipairs(M.buttons) do
            if button.bottom then
                M.anyBottomButtons = true
                button.box = {
                    x = M.modalContainer.x + buttonPadding,
                    y = M.buttonScissor.y + M.buttonScissor.h + (buttonH / 2),
                    w = M.modalContainer.w - buttonPadding * 2,
                    h = buttonH,
                }
            else
                button.offset = i * M.fontHeights.slabsButtons * 2
                button.box = {
                    x = M.modalContainer.x + buttonPadding,
                    y = topY + button.offset - M.fontHeights.slabsButtons / 2,
                    w = M.modalContainer.w - buttonPadding * 2,
                    h = buttonH,
                }
            end
            button.textY = button.box.y + button.box.h / 4
        end
    end

    -- if bottomButtons == "none" then
    --     M.bottomButtons = nil
    --     return
    -- end
    -- M.bottomButtons = bottomButtons or M.bottomButtons
    -- if M.bottomButtons then
    --     for i, button in ipairs(M.bottomButtons) do
    --         button.box = {
    --             x = M.modalContainer.x + buttonPadding,
    --             y = M.buttonScissor.y + M.buttonScissor.h + (buttonH / 2),
    --             w = M.modalContainer.w - buttonPadding * 2,
    --             h = buttonH,
    --         }
    --         button.textY = button.box.y + button.box.h / 4
    --     end
    -- end
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