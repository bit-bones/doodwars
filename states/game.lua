local game = {}

local Gamestate = require "libs/hump/gamestate"
local cam = require "libs/hump/camera"
local sti = require "libs/sti"
local pathfun = require("libs/pathfun")
local ui      = require("ui")

local dood = require("dood")
local shrineRegistry = require("shrine")
local keyboard = require("keyboard")
local mouse = require("mouse")

local graphics = require "graphics"
local screen = graphics.screen
local colors = graphics.colors
local getColor = graphics.getColor
local setColor = graphics.setColor
local fonts = graphics.fonts

function game:enter(previous, settings)
    graphics.getinfoBarLayout()
    love.physics.setMeter(32)

    self.data = {
        gamemode = settings.gamemode,
        map = sti("maps/"..settings.map.."/"..settings.map.."-tilemap.lua", {"box2d"}),
        navmesh =  require ("maps."..settings.map.."."..settings.map.."-navmesh"),
        world = love.physics.newWorld(0, 0, true),
        camera = cam.new(0, 0, 2),
        stopCheckTime = 0.5,
        controlledDood = nil,
        currentZoom = 0.5,
        zoomSpeed = 0.15,
        keyPanSpeed = 150,
        cameraLocked = false,
        mouseWorldX = 0,
        mouseWorldY = 0,
        mouseStates = {},
        keyStates = {},
        layouts = {},
        doods = {},
        shrines = {},
        bases = {},
        props = {},
        selectionBox = {},
    }

    self.data.navigation = pathfun.Navigation(self.data.navmesh)
    self.data.camera.x = 875
    self.data.camera.y = 875

    local map = self.data.map
    map:box2d_init(self.data.world)
    local body = love.physics.newBody(self.data.world, 0, 0, "static")
    body:setAwake(false)

    local rightX = 0 + map.width * map.tilewidth
    local bottomY = 0 + map.height * map.tileheight
    self.data.boundary = {
        rightX = rightX,
        bottomY = bottomY,
        top = love.physics.newFixture(body, love.physics.newEdgeShape(0, 0, rightX, 0)),
        bottom = love.physics.newFixture(body, love.physics.newEdgeShape(0, bottomY, rightX, bottomY)),
        left = love.physics.newFixture(body, love.physics.newEdgeShape(0, 0, 0, bottomY)),
        right = love.physics.newFixture(body, love.physics.newEdgeShape(rightX, 0, rightX, bottomY)),
    }

    local propLayer = map.layers["depth-objects"]
    if propLayer then
        for _, prop in ipairs(propLayer.objects) do
            if prop.type == "trees" then
                local x = propLayer.x + prop.x
                local y = propLayer.y + prop.y

                table.insert(self.data.props, {
                    x = x,
                    y = y,
                    tileX = math.floor(x / map.tilewidth) + 1,
                    tileY = math.floor(y / map.tileheight) + 1,
                })
            else
                print("prop has no type")
            end
        end
    end

    local markerLayer = map.layers["objective-markers"]
    if markerLayer then
        for i, object in ipairs(markerLayer.objects) do
            if object.type == "shrine" then
                local x = markerLayer.x + object.x
                local y = markerLayer.y + object.y

                local body = love.physics.newBody(self.data.world, x, y, "static")
                body:setAwake(false)
                body:setActive(false)
                local shape = love.physics.newCircleShape(0, 0, 50)
                local fixture = love.physics.newFixture(body, shape, 0)

                table.insert(self.data.shrines, {
                    x = x,
                    y = y,
                    index = i,
                    tileX = math.floor(x / map.tilewidth) + 1,
                    tileY = math.floor(y / map.tileheight) + 1,
                    state = object.properties.state or "normal",
                    team = object.properties.color or "neutral",
                    body = body,
                    shape = shape,
                    fixture = fixture,
                })

                table.insert(self.data.bases, {
                    x = x,
                    y = y,
                    index = i,
                    tileX = math.floor(x / map.tilewidth) + 1,
                    tileY = math.floor(y / map.tileheight) + 1,
                })
            end
        end
    end

    local function drawProp(layer, prop)
        for row = math.max(1, prop.tileY - 4),
                math.min(layer.height, prop.tileY + 2) do
            for column = math.max(1, prop.tileX - 2),
                        math.min(layer.width, prop.tileX + 2) do
                local tile = layer.data[row] and layer.data[row][column]

                if tile then
                    local x, y = self.data.map:getLayerTilePosition(layer, tile, column, row)
                    local image = self.data.map.tilesets[tile.tileset].image

                    love.graphics.draw(
                        image,
                        tile.quad,
                        x + layer.x,
                        y + layer.y
                    )
                end
            end
        end
    end

    -- capture gameData because depthLayer will inherit "self" causing self.data to no longer work here
    local gameData = self.data
    local depthLayer = map:addCustomLayer("depth-render")

    function depthLayer:draw()
        local items = {}

        for _, prop in ipairs(gameData.props) do
            local currentProp = prop
            items[#items + 1] = {
                sortY = currentProp.y + 20,
                draw = function()
                    setColor(colors.neutral)
                    drawProp(map.layers["trees"], currentProp)
                end,
            }
        end

        for _, s in ipairs(gameData.shrines) do
            local currentShrine = s
            local sortY = currentShrine.y + 30
            items[#items + 1] = {
                sortY = sortY,
                draw = function()
                    setColor(colors.neutral)
                    shrineRegistry.drawShrine(currentShrine, gameData)
                end,
            }
        end

        for _, b in ipairs(gameData.bases) do
            local currentBase = b
            local sortY = currentBase.y - 20
            items[#items + 1] = {
                sortY = sortY,
                draw = function()
                    setColor(colors.neutral)
                    shrineRegistry.drawBase(currentBase, gameData)
                end,
            }
        end

        for _, d in ipairs(gameData.doods) do
            local currentDood = d
            local spriteHeight = currentDood.animation[currentDood.dir]:getDimensions()
            currentDood.sortY = currentDood.y + spriteHeight * currentDood.scale

            items[#items + 1] = {
                sortY = currentDood.sortY,
                draw = function()
                    if d.insideSelectionBox then
                        setColor(colors.dimNeutral)
                    else
                        setColor(colors.neutral)
                    end
                    currentDood.animation[currentDood.dir]:draw(
                        currentDood.animation.image,
                        currentDood.x,
                        currentDood.y,
                        0,
                        currentDood.scale,
                        currentDood.scale
                    )
                end,
            }
        end

        table.sort(items, function(a, b)
            return a.sortY < b.sortY
        end)

        for _, item in ipairs(items) do
            item.draw()
        end

        setColor(colors.neutral)
    end

    if #self.data.shrines > 0 then
        self.data.shrines[1].team = "blue"
        self.data.shrines[3].team = "red"
        self.data.shrines[7].team = "green"
        self.data.shrines[9].team = "yellow"
    end

    self.data.keyStates = keyboard.states
    self.data.mouseStates = mouse.states
end

function game:update(dt)
    self.data.world:update(dt)
    self.data.map:update(dt)
    dood.update(dt, self.data)
    keyboard.update(dt, self.data)

    local controlledDood = self.data.controlledDood
    if self.data.cameraLocked and controlledDood then
        local box = controlledDood.box
        self.data.camera:lockPosition(box.centerX, box.centerY)
    end
end

function game:draw()
    local map = self.data.map
    local camera = self.data.camera
    local altToggle = self.data.keyStates.altToggle

    local tx = screen.w / (2 * camera.scale) - camera.x
    local ty = screen.h / (2 * camera.scale) - camera.y
    local requiredW = math.ceil(screen.w / camera.scale)
    local requiredH = math.ceil(screen.h / camera.scale)
    local canvasW, canvasH = map.canvas:getDimensions()

    if requiredW > canvasW or requiredH > canvasH then
        map:resize(
            math.max(requiredW, canvasW),
            math.max(requiredH, canvasH)
        )
    elseif requiredW < canvasW or requiredH < canvasH then
        map:resize(
            math.min(requiredW, canvasW),
            math.min(requiredH, canvasH)
        )
    end

    map:draw(tx, ty, camera.scale)

     if altToggle == 5 then
        map:box2d_draw(tx, ty, camera.scale)
     end

    camera:attach()

    -- shrines
    if altToggle > 1 then
        love.graphics.setFont(fonts.debugWorld)
        for i, s in ipairs(self.data.shrines) do
            love.graphics.circle("line", s.x, s.y, s.shape:getRadius())
            love.graphics.print("index: "..i..
                                "\nx: "..s.x..
                                "\ny: "..s.y..
                                "\nstate: "..s.state..
                                "\nteam: "..s.team
                                ,s.x + 10, s.y)
        end
    end

    -- doods
    for i, d in pairs(self.data.doods) do
        local box = d.box
        local attackerSelected = false
        d.boxColor = colors.neutral

        -- set box color
        if d.playerControlled then d.boxColor = {0, 0.9, 1}     -- blue
        elseif d.selected then d.boxColor = {0.1, 1, 0.1} -- green
        elseif d.attackers then
            for _, attacker in pairs(d.attackers) do
                if attacker.selected then
                    attackerSelected = true
                    d.boxColor = {1, 0.3, 0.3}                -- red
                end
            end
        end

        -- arrow
        if d.selected or attackerSelected or d.playerControlled then
            local pc = graphics.getColor()
            graphics.setColor(d.boxColor)
            love.graphics.polygon("fill", d.arrow)
            graphics.setColor(pc)
        end

        -- debug info
        if altToggle == 3 or altToggle == 2 and d.selected then
            if d.moveTargetX and d.moveTargetY then
                local pc = graphics.getColor()
                graphics.setColor(d.boxColor)
                love.graphics.circle("fill", d.moveTargetX, d.moveTargetY, 3)
                graphics.setColor(pc)
            end

            local rescueTarget = d.rescueTarget and d.rescueTarget.index
            local attackTarget = d.attackTarget and d.attackTarget.index
            local puller = d.puller and d.puller.index
            local hasJoint = (d.joint ~= nil)

            local attackerCount = 0
            if d.attackers then
                for _, _ in pairs(d.attackers) do
                    attackerCount = attackerCount + 1
                end
            end

            love.graphics.setFont(fonts.debugWorld)
            love.graphics.print("\nindex: "..d.index..
                                "\nhealth: "..math.floor(d.hp)..
                                "\nx: "..math.floor(d.bodyX)..
                                "\ny: "..math.floor(d.bodyY)..
                                "\ncommand: "..(d.command or "none")..
                                "\nstate: "..d.state..
                                "\ndir: "..d.dir..
                                "\ncolor: "..d.color..
                                "\nselected: "..tostring(d.selected)..
                                "\ncontrolled: "..tostring(d.playerControlled)..
                                "\nattackers: "..(attackerCount or "none")..
                                "\nattack target: "..(attackTarget or "none")..
                                "\nrescue target: "..(rescueTarget or "none")..
                                "\npuller: "..(puller or "none")..
                                "\nhas joint: "..tostring(hasJoint)..
                                "\nwander timer: "..string.format("%.1f", tostring(d.wanderTimer))..
                                "\nscan timer: "..string.format("%.1f", tostring(d.scanTimer))..
                                "\nhurt timer: "..string.format("%.1f", tostring(d.hurtTimer))..
                                "\nattack timer: "..string.format("%.1f", tostring(d.attackTimer))
                                ,box.x + box.w, box.y + box.h)

            if altToggle >= 4 then
                love.graphics.circle("line", d.bodyX, d.bodyY, d.shape:getRadius())
            end
        end
    end

    -- box
    if self.data.hoveredDood and not self.data.draggingSelectionBox then
        local d = self.data.hoveredDood
        local pc = graphics.getColor()
        graphics.setColor(d.boxColor)
        love.graphics.rectangle("line", d.box.x, d.box.y, d.box.w, d.box.h)
        graphics.setColor(pc)
    end

    -- navmesh
    if altToggle >= 4 then
        local pc = graphics.getColor()
        for _, polyMap in ipairs(self.data.navmesh) do
            for _, polygon in ipairs(polyMap) do
                local vertices = {}

                for _, point in ipairs(polygon) do
                    vertices[#vertices + 1] = point[1]
                    vertices[#vertices + 1] = point[2]
                end

                if #vertices >= 6 then
                    graphics.setColor(0.1, 0.9, 0.7, 0.18)
                    love.graphics.polygon("fill", vertices)

                    graphics.setColor(1, 0.8, 0.1, 0.9)
                    love.graphics.polygon("line", vertices)
                end
            end
        end
        graphics.setColor(pc)
    end

    -- selection box
    local box = self.data.selectionBox
    if self.data.mouseStates.leftClickDown and box.w and box.h then
        local previousLineWidth = love.graphics.getLineWidth()
        local previousColor = getColor()

        love.graphics.setLineWidth(1 / self.data.camera.scale)
        setColor(colors.selectionBoxFill)
        love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
        setColor(colors.selectionBoxOutline)
        love.graphics.rectangle("line", box.x, box.y, box.w, box.h)

        love.graphics.setLineWidth(previousLineWidth)
        setColor(previousColor)
    end

   self.data.camera:detach()

    -- hud
    ui.infoBar(game.data)

    local controlledDood = self.data.controlledDood
    local controlledDoodIndex = controlledDood and controlledDood.index or "none"
    love.graphics.setFont(fonts.debugHud)
    love.graphics.print("\nmouseX: "..math.floor(self.data.mouseWorldX)..
                        "\nmouseY: "..math.floor(self.data.mouseWorldY)..
                        -- "\nzoom scale: "..self.data.camera.scale..
                        "\ncontrolling dood: "..(controlledDoodIndex or "none")..
                        "\nalt toggle: "..altToggle
                        ,10, 30)

end

function game:resize()
    graphics.getinfoBarLayout()
end

-- input controls
function game:keypressed(key)
    keyboard.keypressed(key, self.data)
end

function game:keyreleased(key)
    keyboard.keyreleased(key, self.data)
end

function game:mousepressed(x, y, button)
    mouse.mousepressed(x, y, button, self.data)
end

function game:mousereleased(x, y, button)
    mouse.mousereleased(x, y, button, self.data)
end

function game:mousemoved(x, y, dx, dy)
    mouse.mousemoved(x, y, dx, dy, self.data)
end

function game:wheelmoved(x, y)
    if y > 0 then
        self.data.camera:zoom(1 + self.data.zoomSpeed)
    elseif y < 0 then
        self.data.camera:zoom(1 - self.data.zoomSpeed)
    end
end

return game