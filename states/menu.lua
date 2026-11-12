local mouse = require "mouse_map"
local sti = require "libs/sti"
local Gamestate = require "libs/hump/gamestate"
local options = require "states.options"
local game = require "states.game"
local drawing = require "drawing"
local graphics = require "graphics"
local colors = graphics.colors
local screen = graphics.screen
local getColor = graphics.getColor
local setColor = graphics.setColor

local menu = {}

function menu:init()
    self.backgroundColor = love.math.random(4) -- color background
    self.drawModal = true

    self.maps = {}
    for _, map in ipairs(love.filesystem.getDirectoryItems("maps")) do
        table.insert(self.maps, {
            label = map,
            fn = function ()
                self.chosenMap = map
                self:startGame()
            end
        })
    end

    self.gamemodes = {
        {label = "Sandbox"},
        {label = "Doodomination"},
    }
    for _, mode in ipairs(self.gamemodes) do
        mode.fn = function ()
            self.chosenMode = mode.label
            self:chooseMap()
        end
    end

    self.buttons = {
        {
            label = "Play",
            fn = function()
                self:chooseGamemode()
            end,
        },
        {
            label = "Options",
            fn = function ()
                Gamestate.push(options)
            end,
        },
        {
            label = "Quit",
            fn = function()
                love.event.quit()
            end,
        },
    }

    -- self.background = sti("maps/map1old/map1old-tilemap.lua", {"box2d"}) -- map background
    self.background = function ()
        setColor(graphics.backgrounds[self.backgroundColor])
        love.graphics.rectangle("fill", 0, 0, screen.w, screen.h) -- color background
    end
end

function menu:enter()
    graphics.getModalLayout(self.buttons)
    self.title = "Dood Wars"
end

function menu:startGame()
    Gamestate.switch(game, {
        map = self.chosenMap,
        gamemode = self.chosenMode,
    })
end

function menu:chooseMap()
    graphics.getModalLayout(self.maps)
    self.title = "Map"
end

function menu:chooseGamemode()
    graphics.getModalLayout(self.gamemodes)
    self.title = "Gamemode"
end

function menu:draw()
    local previousColor = getColor()
    -- self.background:draw() -- map background
    self.background() -- color background
    if self.drawModal then
        drawing.modal(self.title)
    end
    setColor(previousColor)
end

function menu:keypressed(key)
    if key == "escape" then
        if self.title == "Gamemode" then
            self:enter()
        elseif self.title == "Map" then
            self:chooseGamemode()
        end
    end
end

function menu:mousemoved(x, y)
    local hoveringAnyButton = false
    for _, button in ipairs(graphics.buttons) do
        button.hovered = mouse.M.mouseHover(x, y, button.box)
        if button.hovered then
            self.hoveredButton = button
            hoveringAnyButton = true
        end
    end
    if hoveringAnyButton then
        mouse.M.setCursor("hand")
    else
        mouse.M.setCursor("arrow")
        self.hoveredButton = nil
    end
end

function menu:mousepressed(x, y, inputButton)
    mouse.M.setCursor("arrow")
    if self.hoveredButton then
        print("clicked "..self.hoveredButton.label)
        if self.hoveredButton.fn then
            self.hoveredButton.fn()
        end
    end
end

function menu:resize()
    graphics.getModalLayout()
end

return menu