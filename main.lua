require("debug_helpers")

local game = require("game")
local dood = require("dood")

local key_map = require("key_map")
local keyRegistry = key_map.M

local mouse_map = require("mouse_map")
local mouseRegistry = mouse_map.M

local sti = require("libs/sti")
local pathfun = require("libs/pathfun")
local navmesh = require("maps/map1-navmesh")

local map
local drawOrder

function love.load()
    drawOrder = {}

    love.physics.setMeter(32)
    game.world = love.physics.newWorld(0,0,true)
    love.graphics.setDefaultFilter("nearest", "nearest")

    map = sti("maps/map1.lua", {"box2d"})
    map:box2d_init(game.world)

    game.keyStates = key_map.states
    game.mouseStates = mouse_map.states

    game.fonts = {
        debugWorld = love.graphics.newFont(10),
        debugHud = love.graphics.newFont(12),
        fun = love.graphics.newFont("assets/fonts/ManlineSlabs-xRWVj.ttf", 12),
    }
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
    map:update(dt)
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
    local doodLayouts = layouts.doods
    local screen = layouts.screen
    local camera = game.camera
    local altToggle = game.keyStates.altToggle

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

    table.sort(drawOrder, function (a, b)
        return a.y < b.y
    end)
    for _, d in ipairs(drawOrder) do
        d.animation[d.dir]:draw(d.animation.image, d.x, d.y, 0, d.scale, d.scale)
    end

    -- doods
    for i, d in pairs(game.doods) do
        drawOrder[i] = d
        local box = doodLayouts[i].box
        local boxColor = {1, 1, 1,}

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
            local centerX, centerY = d.body:getWorldPoint(shape:getPoint())

            -- selection box
            local pr, pg, pb, pa = love.graphics.getColor()
            love.graphics.setColor(boxColor)
            love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
            love.graphics.setColor(pr, pg, pb, pa)

            -- debug info
            if altToggle == 3 or altToggle == 2 and d.selected then
                local rescueTarget = d.rescueTarget and d.rescueTarget.index
                local attackTarget = d.attackTarget and d.attackTarget.index
                local attackers = 0

                if d .attackers then
                    for _, _ in pairs(d.attackers) do
                        attackers = attackers + 1
                    end
                end

                love.graphics.setFont(game.fonts.debugWorld)
                love.graphics.print("\nindex: "..d.index..
                                    -- "\nx: "..math.floor(centerX)..
                                    -- "\ny: "..math.floor(centerY)..
                                    "\nstate: "..d.state..
                                    -- "\ndir: "..d.dir..
                                    -- "\ncolor: "..d.color..
                                    -- "\nselected: "..tostring(d.selected)..
                                    -- "\nattackers: "..(attackers or "none")..
                                    "\nattack target: "..(attackTarget or "none")..
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
                love.graphics.circle("line", centerX, centerY, shape:getRadius())
            end
        end
    end

    -- navmesh
    if altToggle >= 4 then
        local oldR, oldG, oldB, oldA = love.graphics.getColor()
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
        love.graphics.setColor(oldR, oldG, oldB, oldA)
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