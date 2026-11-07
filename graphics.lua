local M = {}

M.screen = {}
function M.getScreen()
    M.screen.w, M.screen.h = love.graphics.getDimensions()
    M.screen.centerX = M.screen.w / 2
    M.screen.centerY = M.screen.h / 2
end
M.getScreen()

M.fonts = {
    debugWorld = love.graphics.newFont(10),
    debugHud = love.graphics.newFont(12),
    slabsTitle = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 75),
    slabsPause = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 30),
}

M.fontHeights = {}
for i, font in pairs(M.fonts) do
    M.fontHeights[i] = font:getHeight()
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