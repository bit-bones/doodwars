local mouse = require "mouse"
local sti = require "libs/sti"
local Gamestate = require "libs/hump/gamestate"
local options = require "states.options"
local game = require "states.game"
local ui = require "ui"
local graphics = require "graphics"
local colors = graphics.colors
local screen = graphics.screen
local getColor = graphics.getColor
local setColor = graphics.setColor

local menu = {}

function menu:init()
    self.backgroundColor = love.math.random(4) -- color background
    self.settings = {}
    self.drawModal = true

    self.backButton = {
        bottom = true,
        label = "Back",
        fn = function ()
            self.escapePressed()
        end
    }

    self.startButton = {
        bottom = true,
        label = "Start game",
        fn = function ()
            if self.gameReady then
                self:startGame()
            end
        end
    }

    self.playerTypes = {
        {label = "Human"},
        {label = "Bot"},
        self.backButton
    }

    self.connectionTypes = {
        {
            label = "Local",
            fn = function ()
                self.settings.chosenConnectionType = "Local"
                -- self.availableModes = self.gamemodes
                self:enterGamemodeSelection()
            end
        },
        {
            label = "Online",
            fn = function ()
                self.settings.chosenConnectionType = "Online"
                -- table.remove(self.availableModes, 1)
                self:enterGamemodeSelection()
            end
        },
        self.backButton
    }
    -- for _, type in ipairs(self.connectionTypes) do
    --     type.fn = function ()
    --         self.settings.chosenConnectionType = type.label
    --         self:enterGamemodeSelection()
    --     end
    -- end

    self.teams = {
        {label = "Blue"},
        {label = "Red"},
        {label = "Green"},
        {label = "Yellow"},
    }
    for _, team in ipairs(self.teams) do
        team.fn = function ()
            self:enterPlayerSelection()
        end
    end
    table.insert(self.teams, self.backButton)
    table.insert(self.teams, self.startButton)

    self.maps = {}
    for _, map in ipairs(love.filesystem.getDirectoryItems("maps")) do
        table.insert(self.maps, {
            label = map,
            fn = function ()
                self.settings.chosenMap = map
                if self.settings.chosenGamemode == "Sandbox" then
                    self:startGame()
                    return
                end
                self:enterTeamSelection()
            end
        })
    end
    table.insert(self.maps, self.backButton)

    self.gamemodes = {
        {
            label = "Sandbox",
            fn = function ()
                self.settings.chosenGamemode = "Sandbox"
                self:enterMapSelection()
                self.settings.player = {
                    squads = self.teams
                }
            end
        },
        {
            label = "Doodomination",
            fn = function ()
                self.settings.chosenGamemode = "Doodomination"
                self:enterMapSelection()
                self.settings.player = {
                    squads = {
                        {label = "All"}
                    }
                }
            end
        },
        self.backButton
    }

    -- self.availableModes = self.gamemodes

    self.mainButtons = {
        {
            label = "Play",
            fn = function()
                self:enterConnectionSelection()
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
    self.gameReady = false
    graphics.getModalLayout(self.mainButtons)
    self.title = "Dood Wars"
end

function menu:startGame()
    Gamestate.switch(game, self.settings)
end

function menu:enterPlayerSelection()
    self.escapePressed = function ()
        self:enterTeamSelection()
    end
    graphics.getModalLayout(self.playerTypes)
    self.title = "Player type"
end

function menu:enterConnectionSelection()
    self.escapePressed = function ()
        self:enter()
    end
    graphics.getModalLayout(self.connectionTypes)
    self.title = "Connection"
end

function menu:enterGamemodeSelection()
    self.escapePressed = function ()
        self:enterConnectionSelection()
    end
    graphics.getModalLayout(self.gamemodes)
    self.title = "Gamemode"
end

function menu:enterMapSelection()
    self.escapePressed = function ()
        self:enterGamemodeSelection()
    end
    graphics.getModalLayout(self.maps)
    self.title = "Map"
end

function menu:enterTeamSelection()
    self.escapePressed = function ()
        self:enterMapSelection()
    end
    graphics.getModalLayout(self.teams)
    self.title = "Team"
end

function menu:draw()
    local previousColor = getColor()
    -- self.background:draw() -- map background
    self.background() -- color background
    if self.drawModal then
        ui.modal(self.title)
    end
    setColor(previousColor)
end

function menu:keypressed(key)
    if key == "escape" and self.escapePressed then
        self.escapePressed()
    end
end

function menu:mousemoved(x, y)
    mouse.modalMousemoved(x, y, self)
end

function menu:mousepressed(x, y, mouseButton)
    mouse.modalMousepressed(x, y, mouseButton, self)
end

function menu:resize()
    graphics.getModalLayout()
end

function menu:leave()
    mouse.setCursor("arrow")
    graphics.buttons = nil
end

return menu