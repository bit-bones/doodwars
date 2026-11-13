require "debug-helpers"
local Gamestate = require "libs/hump/gamestate"
local menu = require "states.menu"
local graphics = require "graphics"

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(menu)
end

function love.keypressed(key)
    if key == "f11" then
        local fullscreen = love.window.getFullscreen()
        fullscreen = not fullscreen
        love.window.setFullscreen(fullscreen)
    end
end

function love.resize()
    graphics.getScreen()
end