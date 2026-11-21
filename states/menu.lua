local mouse = require "mouse"
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

local function resetButton(button)
    button.drawFill = false
    button.labelColor = colors.neutral
    button.context.color = colors.dimNeutral
    button.context.text = "Empty"
end

function menu:init()
    self.drawModal = true
    self.backgroundColor = love.math.random(4) -- color background

    self.settingsButton = {
        label = "Settings"
    }

    self.startButton = {
        label = "Start game",
        fn = function ()
            -- if self.gameReady then
                self:startGame()
            -- end
        end
    }

    self.playerTypes = {
        {
            label = "You",
            fn = function ()
                for i, player in ipairs(self.settings.players) do
                    if player.type == "You" then
                        resetButton(self.teams[i])
                        self.settings.players[i].type = "Empty"
                    end
                end
                self.settings.players[self.chosenTeamIndex] = {
                    id = self.chosenTeamIndex,
                    type = "You",
                    team = self.chosenTeam,
                }
                self.teams[self.chosenTeamIndex].drawFill = true
                self.teams[self.chosenTeamIndex].labelColor = colors[self.chosenTeam]
                self.teams[self.chosenTeamIndex].context.color = colors[self.chosenTeam]
                self.teams[self.chosenTeamIndex].context.text = "You"
                self:enterTeamSelection()
            end
        },
        {
            label = "Bot",
            fn = function ()
               self.settings.players[self.chosenTeamIndex] = {
                    id = self.chosenTeamIndex,
                    type = "Bot",
                    team = self.chosenTeam,
                }
                self.teams[self.chosenTeamIndex].drawFill = true
                self.teams[self.chosenTeamIndex].labelColor = colors[self.chosenTeam]
                self.teams[self.chosenTeamIndex].context.color = colors[self.chosenTeam]
                self.teams[self.chosenTeamIndex].context.text = "Bot"
                self:enterTeamSelection()
            end
        },
        {
            label = "Empty",
            fn = function ()
                resetButton(self.teams[self.chosenTeamIndex])
                self.settings.players[self.chosenTeamIndex].type = "Empty"
                self:enterTeamSelection()
            end
        },
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
    }

    self.teams = {
        {label = "Blue"},
        {label = "Red"},
        {label = "Green"},
        {label = "Yellow"},
    }
    for i, team in ipairs(self.teams) do
        team.context = {
            color = colors.dimNeutral,
            text = "Empty",
        }
        team.fn = function ()
            self.chosenTeamIndex = i
            self.chosenTeam = team.label
            self:enterPlayerSelection()
        end
    end

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

    self.gamemodes = {
        {
            label = "Sandbox",
            fn = function ()
                self.settings.chosenGamemode = "Sandbox"
                self:enterMapSelection()
                self.settings.players[1] = {
                    id = 1,
                    type = "You",
                    team = "none",
                    squads = {
                        {label = "Blue", doodIds = {}},
                        {label = "Red", doodIds = {}},
                        {label = "Green", doodIds = {}},
                        {label = "Yellow", doodIds = {}},
                    },
                    -- [2] = nil,
                    -- [3] = nil,
                    -- [4] = nil,
                }


            end
        },
        {
            label = "Doodomination",
            fn = function ()
                self.settings.chosenGamemode = "Doodomination"
                self:enterMapSelection()
            end
        },
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
    for _, button in ipairs(self.teams) do
        resetButton(button)
    end
    self.settings = {
        players = {
            {type = "Empty", team = "Blue"},
            {type = "Empty", team = "Red"},
            {type = "Empty", team = "Green"},
            {type = "Empty", team = "Yellow"},
        }
    }
    self.escapePressed = function ()
        love.event.quit()
    end
    self.gameReady = false
    graphics.getModalLayout(self.mainButtons, {})
    self.title = "Dood Wars"
end

function menu:startGame()
    Gamestate.switch(game, self.settings)
end

function menu:enterPlayerSelection()
    self.escapePressed = function ()
        self:enterTeamSelection()
    end
    graphics.getModalLayout(self.playerTypes, {ui.backButton})
    self.title = "Player type"
end

function menu:enterConnectionSelection()
    self.escapePressed = function ()
        self:enter()
    end
    graphics.getModalLayout(self.connectionTypes, {ui.backButton})
    self.title = "Connection"
end

function menu:enterGamemodeSelection()
    self.escapePressed = function ()
        self:enterConnectionSelection()
    end
    graphics.getModalLayout(self.gamemodes, {ui.backButton})
    self.title = "Gamemode"
end

function menu:enterMapSelection()
    self.escapePressed = function ()
        self:enterGamemodeSelection()
    end
    graphics.getModalLayout(self.maps, {ui.backButton})
    self.title = "Map"
end

function menu:enterTeamSelection()
    self.escapePressed = function ()
        self:enterMapSelection()
    end
    graphics.getModalLayout(self.teams, {self.startButton, ui.backButton})
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

function menu:wheelmoved(x, y)
    mouse.modalWheelMoved(x, y, self)
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
    graphics.buttons = {}
end

return menu