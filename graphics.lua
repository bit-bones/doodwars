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
    white =                 {1, 1, 1, 1},
    transparentGray =       {0, 0, 0, 0.2},
    selectionBoxOutline =   {0.1, 1, 0.1, 1},
    selectionBoxFill =      {0.1, 1, 0.1, 0.1},
}

M.screen = {}
M.container = {}

local buttonPadding = 150
local buttonSpacing = 20
local buttonH = M.fontHeights.slabsButtons * 2

function M.getLayout(buttons)
    M.screen.w, M.screen.h = love.graphics.getDimensions()
    M.screen.centerX = M.screen.w / 2
    M.screen.centerY = M.screen.h / 2

    M.container.w = 800
    M.container.h = 800
    M.container.x = M.screen.centerX - M.container.w / 2
    M.container.y = M.screen.centerY - M.container.h / 2

    M.buttons = buttons or M.buttons
    if not M.buttons then return end
    local topY = M.screen.centerY - ((#M.buttons * buttonH) / 2)
    for i, button in ipairs(M.buttons) do
        button.offset = i * M.fontHeights.slabsButtons * 2 + buttonSpacing
        button.box = {
            x = M.container.x + buttonPadding,
            y = topY + button.offset - M.fontHeights.slabsButtons / 2,
            w = M.container.w - buttonPadding * 2,
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