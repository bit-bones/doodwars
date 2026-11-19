local Gamestate = require "libs/hump/gamestate"
local pause = require "states.pause"
local dood = require "dood"
local graphics = require "graphics"

local M = {}

M.keymap = {
--==================================================--
    t = {
        pressed = function (g)

        end
    },
--==================================================--
    lalt = {
        pressed = function (g)
            g.input.altToggle = g.input.altToggle + 1
            if g.input.altToggle > 5 then
                g.input.altToggle = 0
            end
        end
    },
--==================================================--
    space = {
        pressed = function (g)
            local color
            local colorId
            if love.keyboard.isDown("b") then
                color = "Blue"
                colorId = 1
            elseif love.keyboard.isDown("r") then
                color = "Red"
                colorId = 2
            elseif love.keyboard.isDown("g") then
                color = "Green"
                colorId = 3
            elseif love.keyboard.isDown("y") then
                color = "Yellow"
                colorId = 4
            -- elseif love.keyboard.isDown("n") then c = "neutral"
            end
            if color then
                if g.gamemode == "Sandbox" then
                    dood.newDood(g.input.mouseWorldX, g.input.mouseWorldY, color, g, 1, colorId)
                    -- table.insert(g.localPlayer.squads[colorId].doodIds, doodId)
                else
                    for playerId, player in ipairs(g.players) do
                        if player.team == color and player.type ~= "Empty" then
                            dood.newDood(g.input.mouseWorldX, g.input.mouseWorldY, color, g, colorId, 1)
                            -- table.insert(player.squads[1].doodIds, doodId)
                        end
                    end
                end
                graphics.getinfoBarLayout(g)
            end
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
        pressed = function (g)
            g.input.keyPanSpeed = 800
        end,

        released = function (g)
            g.input.keyPanSpeed = 150
        end,
    },
--==================================================--
    escape = {
        pressed = function (g)
            Gamestate.push(pause)
        end
    },
--==================================================--
}

-- update
function M.update(dt, g)
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
            d.body:setLinearVelocity(0, 0)
        end
    else
        g.camera:move(
            moveX * dt * g.input.keyPanSpeed,
            moveY * dt * g.input.keyPanSpeed
        )
    end
end


-- key pressed
function M.keypressed(key, g)
    local action = M.keymap[key]
    if action and action.pressed then
        action.pressed(g)
    end
end

-- key released
function M.keyreleased(key, g)
    local action = M.keymap[key]
    if action and action.released then
        action.released(g)
    end
end

return M