require("debug_helpers")

local game = require("game")
local dood = require("dood")
local shrineRegistry = require("shrine")

local key_map = require("key_map")
local keyRegistry = key_map.M

local mouse_map = require("mouse_map")
local mouseRegistry = mouse_map.M

local sti = require("libs/sti")
local navmesh = require("maps/map1shrinetest-navmesh")

local drawOrder

function love.load()
    drawOrder = {}

    love.physics.setMeter(32)
    game.world = love.physics.newWorld(0, 0, true)

    love.graphics.setDefaultFilter("nearest", "nearest")

    game.map = sti("maps/map1shrinetest.lua", {"box2d"})
    local map = game.map
    map:box2d_init(game.world)

    local body = love.physics.newBody(game.world, 0, 0, "static")
    body:setAwake(false)
    local rightX = 0 + map.width * map.tilewidth
    local bottomY = 0 + map.height * map.tileheight
    game.boundary = {
        rightX = rightX,
        bottomY = bottomY,
        top = love.physics.newFixture(body, love.physics.newEdgeShape(0, 0, rightX, 0)),
        bottom = love.physics.newFixture(body, love.physics.newEdgeShape(0, bottomY, rightX, bottomY)),
        left = love.physics.newFixture(body, love.physics.newEdgeShape(0, 0, 0, bottomY)),
        right = love.physics.newFixture(body, love.physics.newEdgeShape(rightX, 0, rightX, bottomY)),
    }

    local propLayer = map.layers["depth-objects"]
    for _, prop in ipairs(propLayer.objects) do
        if prop.type == "trees" then
            local x = propLayer.x + prop.x
            local y = propLayer.y + prop.y

            table.insert(game.props, {
                x = x,
                y = y,
                tileX = math.floor(x / map.tilewidth) + 1,
                tileY = math.floor(y / map.tileheight) + 1,
            })
        else
            print("prop has no type")
        end
    end

    local markerLayer = map.layers["objective-markers"]
    for i, object in ipairs(markerLayer.objects) do
        if object.type == "shrine" then
            local x = markerLayer.x + object.x
            local y = markerLayer.y + object.y

            local body = love.physics.newBody(game.world, x, y, "static")
            body:setAwake(false)
            body:setActive(false)

            local shape = love.physics.newCircleShape(0, 0, 50)
            local fixture = love.physics.newFixture(body, shape, 0)

            table.insert(game.shrines, {
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

            table.insert(game.bases, {
                x = x,
                y = y,
                index = i,
                tileX = math.floor(x / map.tilewidth) + 1,
                tileY = math.floor(y / map.tileheight) + 1,
            })
        end
    end

    local function drawProp(layer, prop)
        for row = math.max(1, prop.tileY - 4),
                math.min(layer.height, prop.tileY + 2) do
            for column = math.max(1, prop.tileX - 2),
                        math.min(layer.width, prop.tileX + 2) do
                local tile = layer.data[row] and layer.data[row][column]

                if tile then
                    local x, y = game.map:getLayerTilePosition(layer, tile, column, row)
                    local image = game.map.tilesets[tile.tileset].image

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

    local depthLayer = map:addCustomLayer("depth-render")

    function depthLayer:draw()
        local items = {}

        for _, prop in ipairs(game.props) do
            local currentProp = prop
            items[#items + 1] = {
                sortY = currentProp.y + 20,
                draw = function()
                    love.graphics.setColor(1, 1, 1, 1)
                    drawProp(map.layers["trees"], currentProp)
                end,
            }
        end

        for _, s in ipairs(game.shrines) do
            local currentShrine = s
            local sortY = currentShrine.y + 30
            items[#items + 1] = {
                sortY = sortY,
                draw = function()
                    love.graphics.setColor(1, 1, 1, 1)
                    shrineRegistry.drawShrine(currentShrine, game)
                end,
            }
        end

        for _, b in ipairs(game.bases) do
            local currentBase = b
            local sortY = currentBase.y - 20
            items[#items + 1] = {
                sortY = sortY,
                draw = function()
                    love.graphics.setColor(1, 1, 1, 1)
                    shrineRegistry.drawBase(currentBase, game)
                end,
            }
        end

        for _, d in ipairs(game.doods) do
            local currentDood = d
            local _, spriteHeight =
                currentDood.animation[currentDood.dir]:getDimensions()

            items[#items + 1] = {
                sortY = currentDood.y + spriteHeight * currentDood.scale,
                draw = function()
                    love.graphics.setColor(1, 1, 1, 1)
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

        love.graphics.setColor(1, 1, 1, 1)
    end

    game.shrines[1].team = "blue"
    game.shrines[3].team = "red"
    game.shrines[7].team = "green"
    game.shrines[9].team = "yellow"

    game.keyStates = key_map.states
    game.mouseStates = mouse_map.states

    game.fonts = {
        debugWorld = love.graphics.newFont(10),
        debugHud = love.graphics.newFont(12),
        fun = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 12),
    }
    for i, v in pairs(game.fonts) do
        game.fontHeights[i] = v:getHeight()
    end
end

local function getLayouts()
    local screenW, screenH = love.graphics.getDimensions()
    local screenCenterX = screenW / 2

    local doodLayouts = {}

    for i, d in ipairs(game.doods) do
        local fw, fh = d.animation[d.dir]:getDimensions() -- get animation frame dimensions
        local sw =  fw * d.scale -- multiply by dood scale to get current sprite dimensions
        local sh = fh * d.scale
        local bw = sw * 0.4      -- multiply by shrink factor to get box dimensions
        local bh = sh * 0.5
        local bx = d.x + (sw - bw) / 2
        local by = d.y + (sh - bh) / 2

        doodLayouts[i] = {
            box = {
                x = bx,
                y = by,
                w = bw,
                h = bh,
                centerX = bx + bw / 2,
                centerY = by + bh / 2,
            },

            contextMenu = {
                x = bx + bw,
                y = by,
                w = 30,
                h = 20,
            }
        }
    end

    return {
        screen = {
            w = screenW,
            h = screenH,
        },

        doods = doodLayouts,
    }
end

function love.update(dt)
    game.layouts = getLayouts()
    game.mouseCameraX, game.mouseCameraY = love.mouse.getPosition()
    game.mouseWorldX, game.mouseWorldY = game.camera:mousePosition()

    game.world:update(dt)
    game.map:update(dt)
    dood.M.update(dt, game)
    keyRegistry.update(dt, game)
    mouseRegistry.update(dt, game)

    local doodLayouts = game.layouts.doods
    if game.cameraLocked and game.controlledDood then
        local controlledDoodIndex = game.controlledDood and game.controlledDood.index
        game.camera:lockPosition(doodLayouts[controlledDoodIndex].box.centerX, doodLayouts[controlledDoodIndex].box.centerY)
    end
end

function love.draw()
    local layouts = getLayouts()
    local map = game.map
    local doodLayouts = layouts.doods
    local screen = layouts.screen
    local camera = game.camera
    local altToggle = game.keyStates.altToggle
    local fonts = game.fonts
    local fontHeights = game.fontHeights

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
    end

    map:draw(tx, ty, camera.scale)

     if altToggle == 5 then
        map:box2d_draw(tx, ty, camera.scale)
     end

    game.camera:attach()

    -- shrines
    if altToggle > 1 then
        love.graphics.setFont(fonts.debugWorld)
        for i, s in ipairs(game.shrines) do
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
    for i, d in pairs(game.doods) do
        drawOrder[i] = d
        local box = doodLayouts[i].box
        local boxColor = {1, 1, 1,}

        -- set box color
        if d.playerControlled then boxColor = {0.3, 1, 0.3} -- green
        elseif d.selected then boxColor = {0.5, 0.5, 1}     -- blue
        elseif d.attackers then
            for _, attacker in pairs(d.attackers) do
                if attacker.selected then
                    boxColor = {1, 0.3, 0.3}                -- red
                end
            end
        end

        if mouseRegistry.mouseHover(game.mouseWorldX, game.mouseWorldY, box) or altToggle > 0 then
            local shape = d.fixture:getShape()
            local bodyX, bodyY = d.body:getWorldPoint(shape:getPoint())

            -- box
            local pr, pg, pb, pa = love.graphics.getColor()
            love.graphics.setColor(boxColor)
            love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
            love.graphics.setColor(pr, pg, pb, pa)

            -- debug info
            if altToggle == 3 or altToggle == 2 and d.selected then
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

                if d.moveTargetX and d.moveTargetY then
                    love.graphics.circle("fill", d.moveTargetX, d.moveTargetY, 10)
                end

                love.graphics.setFont(fonts.debugWorld)
                love.graphics.print("\nindex: "..d.index..
                                    "\nx: "..math.floor(bodyX)..
                                    "\ny: "..math.floor(bodyY)..
                                    "\nstate: "..d.state..
                                    -- "\ndir: "..d.dir..
                                    -- "\ncolor: "..d.color..
                                    -- "\nselected: "..tostring(d.selected)..
                                    "\nattackers: "..(attackerCount or "none")..
                                    "\nattack target: "..(attackTarget or "none")..
                                    "\npuller: "..(puller or "none")..
                                    "\nhas joint: "..tostring(hasJoint)..
                                    "\nrescue target: "..(rescueTarget or "none")..
                                    "\nwander timer: "..string.format("%.1f", tostring(d.wanderTimer))..
                                    "\nscan timer: "..string.format("%.1f", tostring(d.scanTimer))..
                                    "\nhurt timer: "..string.format("%.1f", tostring(d.hurtTimer))..
                                    "\nattack timer: "..string.format("%.1f", tostring(d.attackTimer))..
                                    "\nhealth: "..math.floor(d.hp)
                                    -- "\ncontrolled: "..tostring(d.playerControlled)..
                                    ,box.x + box.w, box.y + box.h)

            end

            if altToggle >= 4 then
                love.graphics.circle("line", bodyX, bodyY, shape:getRadius())
            end
        end
    end

    -- navmesh
    if altToggle >= 4 then
        local pr, pg, pb, pa = love.graphics.getColor()
        for _, polyMap in ipairs(navmesh) do
            for _, polygon in ipairs(polyMap) do
                local vertices = {}

                for _, point in ipairs(polygon) do
                    vertices[#vertices + 1] = point[1]
                    vertices[#vertices + 1] = point[2]
                end

                if #vertices >= 6 then
                    love.graphics.setColor(0.1, 0.9, 0.7, 0.18)
                    love.graphics.polygon("fill", vertices)

                    love.graphics.setColor(1, 0.8, 0.1, 0.9)
                    love.graphics.polygon("line", vertices)
                end
            end
        end
        love.graphics.setColor(pr, pg, pb, pa)
    end

   game.camera:detach()

    -- hud
    love.graphics.setFont(game.fonts.debugHud)
    local controlledDoodIndex = game.controlledDood and game.controlledDood.index or "none"
    love.graphics.print("\nmouseX: "..math.floor(game.mouseWorldX)..
                        "\nmouseY: "..math.floor(game.mouseWorldY)..
                        -- "\nzoom scale: "..game.camera.scale..
                        "\ncontrolling dood: "..(controlledDoodIndex or "none")..
                        "\nalt toggle: "..altToggle
                        ,10, 30)

end

-- input controls
function love.keypressed(key)
    keyRegistry.keypressed(key, game)
end

function love.keyreleased(key)
    keyRegistry.keyreleased(key, game)
end

function love.mousepressed(x, y, button)
    mouseRegistry.mousepressed(x, y, button, game)
end

function love.mousereleased(x, y, button)
    mouseRegistry.mousereleased(x, y, button, game)
end

function love.wheelmoved(x, y)
    if y > 0 then
        game.camera:zoom(1 + game.zoomSpeed)
    elseif y < 0 then
        game.camera:zoom(1 - game.zoomSpeed)
    end
end

return game