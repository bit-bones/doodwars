local dood = require("dood")

local M = {}

function M.mouseHover(x, y, rectangle)
    if rectangle == nil then
        return false
    end
    return x > rectangle.x and x < rectangle.x + rectangle.w and y > rectangle.y and y < rectangle.y + rectangle.h
end

local states = {}

local mouseMap = {
--==================================================--
    [1] = { -- left click
        released = function (x, y, g)

            local clickedDood
            for i, d in ipairs(g.doods) do
                local box =  g.layouts.doods[i].box
                local wx, wy = g.mouseWorldX, g.mouseWorldY

                if M.mouseHover(wx, wy, box) then
                    clickedDood = d
                    d.wanderTimer = 10
                    break
                end
            end

            if love.keyboard.isDown("lctrl") then
                if clickedDood and clickedDood.hp > 0 then
                    clickedDood.moveTargetX = nil
                    clickedDood.moveTargetY = nil

                    if clickedDood == g.controlledDood then
                        g.controlledDood = nil
                    else
                        g.controlledDood = clickedDood
                        clickedDood.selected = false
                    end
                end

            elseif love.keyboard.isDown("lshift") then
                if clickedDood and clickedDood ~= g.controlledDood then
                    clickedDood.selected = not clickedDood.selected
                end

            elseif love.keyboard.isDown("x") then
                if clickedDood then
                    if clickedDood.state ~= "downed" and clickedDood.hp > 0 then
                        clickedDood.animation = clickedDood.animations.hurt
                        clickedDood.hurtTimer = dood.DEFAULTS.HURT_TIME
                        clickedDood.hp = clickedDood.hp - 50
                    end
                end

            else
                for _, d in ipairs(g.doods) do
                    d.selected = (clickedDood ~= g.controlledDood and d == clickedDood)
                end
            end

            for _, d in ipairs(g.doods) do
                d.playerControlled = (d == g.controlledDood)
            end
        end,
    },
--==================================================--
    [2] = { -- right click
        released = function (x, y, g)
            local wx, wy = g.mouseWorldX, g.mouseWorldY
            local clickedDood

            for i, d in ipairs(g.doods) do
                local box =  g.layouts.doods[i].box
                if M.mouseHover(wx, wy, box) then
                    clickedDood = d
                    break
                end
            end

            for i, d in ipairs(g.doods) do
                if d.selected and d.state ~= "downed" then
                    if clickedDood then
                        if clickedDood.color ~= d.color then
                            dood.M.setAttackTarget(d, g, clickedDood.index)
                        elseif clickedDood ~= d and clickedDood.color == d.color and clickedDood.state == "downed" then
                            d.rescueTarget = clickedDood
                        end
                    else
                        dood.M.clearTargets(d)
                        d.moveTargetX = wx
                        d.moveTargetY = wy
                    end
                end
            end
        end,
    },
--==================================================--
    [3] = { -- middle mouse button
        pressed = function (x, y, g)
            g.previousMouseCameraX = g.mouseCameraX
            g.previousMouseCameraY = g.mouseCameraY
        end,

        down = function (dt, g)
            local dx = g.mouseCameraX - g.previousMouseCameraX
            local dy = g.mouseCameraY - g.previousMouseCameraY
            -- g.camera:move(-dx * dt, -dy * dt)
            g.camera:lockPosition(g.camera.x - dx * g.middleMousePanSpeed, g.camera.y - dy * g.middleMousePanSpeed)
        end,

        released = function (x, y, g)

        end,
    },
--==================================================--
}



-- update
function M.update(dt, game)
    for button, action in pairs(mouseMap) do
        if love.mouse.isDown(button) and action.down then
            action.down(dt, game)
        end
    end
end

-- button pressed
function M.mousepressed(cx, cy, button, game)
    local action = mouseMap[button]
    if action and action.pressed then
        action.pressed(cx, cy, game)
    end
end

-- button released
function M.mousereleased(cx, cy, button, game)
    local action = mouseMap[button]
    if action and action.released then
        action.released(cx, cy, game)
    end
end

return {
    M = M,
    states = states,
    mouseMap = mouseMap,
}