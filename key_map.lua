local dood = require("dood")

local states = {
    shiftDown = false,
    altToggle = 0,
}


local keyMap = {
--==================================================--
    t = {
        pressed = function (g)
            if g.controlledDood then
                local closestShrines = dood.M.shrineScan(g.controlledDood, g)
                for i, s in ipairs(closestShrines) do
                    print(i..": "..s.team)
                end
            end
        end
    },
--==================================================--
    lalt = {
        pressed = function ()
            states.altToggle = states.altToggle + 1
            if states.altToggle > 5 then
                states.altToggle = 0
            end
        end
    },
--==================================================--
    space = {
        pressed = function (g)
            local c
            if love.keyboard.isDown("b") then c = "blue"
            elseif love.keyboard.isDown("r") then c = "red"
            elseif love.keyboard.isDown("g") then c = "green"
            elseif love.keyboard.isDown("y") then c = "yellow"
            -- elseif love.keyboard.isDown("n") then c = "neutral"
            end
            if c then dood.M.newDood(g.mouseWorldX, g.mouseWorldY, c, g) end
        end,
    },
--==================================================--
    tab = {
        pressed = function (g)
            g.cameraLocked = not g.cameraLocked
        end,
    },
--==================================================--
    lshift = {
        down = function (dt, g)
            states.shiftDown = true
            g.keyPanSpeed = 800
        end,

        released = function (g)
            states.shiftDown = false
            g.keyPanSpeed = 150
        end,
    },
--==================================================--
    escape = {
        pressed = function (g)
            g.paused = not g.paused
            
            -- love.event.quit()
        end
    },
--==================================================--
    f11 = {
        pressed = function ()
            local fullscreen = love.window.getFullscreen()
            fullscreen = not fullscreen
            love.window.setFullscreen(fullscreen)
        end
    },
--==================================================--
}


local M = {}

-- update
function M.update(dt, g)
    for key, action in pairs(keyMap) do
        if love.keyboard.isDown(key) and action.down then
            action.down(dt, g)
        end
    end

    -- WASD
    local moveX = (love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0)
    local moveY = (love.keyboard.isDown("s") and 1 or 0) - (love.keyboard.isDown("w") and 1 or 0)

    local d = g.controlledDood

    if d and d.state ~= "downed" and d.hurtTimer <= 0 then
        local length = math.sqrt(moveX * moveX + moveY * moveY)

        if length > 0 then
            moveX = moveX / length
            moveY = moveY / length

            d.body:setLinearVelocity(moveX * dood.DEFAULTS.MOVE_SPEED, moveY * dood.DEFAULTS.MOVE_SPEED)
            d.state = "walk"
            d.animation = d.animations.walk

            if math.abs(moveX) > math.abs(moveY) then
                d.dir = moveX > 0 and "right" or "left"
            else
                d.dir = moveY > 0 and "down" or "up"
            end
        else
            d.state = "idle"
            d.animation = d.animations.idle
            if not d.moveTargetX then
                d.body:setLinearVelocity(0, 0)
            end
        end
    else
        g.camera:move(
            moveX * dt * g.keyPanSpeed,
            moveY * dt * g.keyPanSpeed
        )
    end
end


-- key pressed
function M.keypressed(key, g)
    local action = keyMap[key]
    if action and action.pressed then
        action.pressed(g)
    end
end

-- key released
function M.keyreleased(key, g)
    local action = keyMap[key]
    if action and action.released then
        action.released(g)
    end
end

return {
    M = M,
    states = states,
    keyMap = keyMap,
}