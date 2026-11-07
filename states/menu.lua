local Gamestate = require "libs/hump/gamestate"
local game = require "states/game"

local graphics = require"graphics"
local screen = graphics.screen
local fonts = graphics.fonts
local fontHeights = graphics.fontHeights

local menu = {}

function menu:init()
    print("menu initialized")
end

function menu:startGame()
    Gamestate.switch(game, {
        map = "maps/map1shrinetest.lua",
        navmesh = "maps/map1shrinetest-navmesh",
        gameMode = "Doodomination",
    })
end

function menu:draw()
    local pc = graphics.getColor()
    graphics.setColor(0.2, 0.4, 0.2)
    love.graphics.rectangle("fill", 0, 0, screen.w, screen.h)
    graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.slabsTitle)
    love.graphics.printf("Dood Wars", 0, 30, 0 + screen.w, "center")
    graphics.setColor(pc)
end

function menu:keyreleased(key)
    if key == "return" then
        menu:startGame()
    end
end

return menu