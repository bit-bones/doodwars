local M = {}

local vPadding, hPadding = 80, 500

M.screen = {}
M.container = {}

function M.getLayout()
    M.screen.w, M.screen.h = love.graphics.getDimensions()
    M.screen.centerX = M.screen.w / 2
    M.screen.centerY = M.screen.h / 2

    M.container.w = M.screen.w - hPadding
    M.container.h = M.screen.h - vPadding
    M.container.x = M.screen.centerX - M.container.w / 2
    M.container.y = M.screen.centerY - M.container.h / 2
end

M.fonts = {
    debugWorld = love.graphics.newFont(10),
    debugHud = love.graphics.newFont(12),
    slabsTitle = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 70),
    slabsButtons = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 40),
}

M.fontHeights = {}
for i, font in pairs(M.fonts) do
    M.fontHeights[i] = font:getHeight()
end

M.colors = {
    white =                 {1, 1, 1, 1},
    transparentGray =       {0, 0, 0, 0.1},
    selectionBoxOutline =   {0.1, 1, 0.1, 1},
    selectionBoxFill =      {0.1, 1, 0.1, 0.1},
}

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