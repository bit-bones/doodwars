require "debug_helpers"

local Gamestate = require "libs/hump/gamestate"
local game = require "states.game"
local menu = require "states.menu"
local graphics = require "graphics"
local mouse = require "mouse_map"

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