local M = {}

M.fonts = {
    debugWorld = love.graphics.newFont(10),
    debugHud = love.graphics.newFont(12),
    slabsTitle = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 75),
    slabsButtons = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 40),
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

M.screen = {}
M.modalContainer = {}

local buttonPadding = 150
local buttonSpacing = 20
local buttonH = M.fontHeights.slabsButtons * 2

function M.getScreen()
    M.screen.w, M.screen.h = love.graphics.getDimensions()
    M.screen.centerX = M.screen.w / 2
    M.screen.centerY = M.screen.h / 2
end

function M.getinfoBarLayout()
    local container = {}
    M.getScreen()

    container.h = 200
    container.w = M.screen.w
    container.y = 0 + M.screen.h - container.h
    container.x = 0

    

    M.infoBarContainer = container
end

function M.getModalLayout(buttons)
    M.getScreen()

    M.modalContainer.w = 800
    M.modalContainer.h = 800
    M.modalContainer.x = M.screen.centerX - M.modalContainer.w / 2
    M.modalContainer.y = M.screen.centerY - M.modalContainer.h / 2

    M.buttons = buttons or M.buttons
    if not M.buttons then return end
    local topY = M.screen.centerY - ((#M.buttons * buttonH) / 2)
    for i, button in ipairs(M.buttons) do
        button.offset = i * M.fontHeights.slabsButtons * 2 + buttonSpacing
        button.box = {
            x = M.modalContainer.x + buttonPadding,
            y = topY + button.offset - M.fontHeights.slabsButtons / 2,
            w = M.modalContainer.w - buttonPadding * 2,
            h = buttonH,
        }
        button.textY = button.box.y + button.box.h / 4
    end
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