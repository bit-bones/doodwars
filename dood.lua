local anim8 = require("libs/anim8")
local pathfun = require("libs/pathfun")
local navmesh = require("maps/map1shrinetest-navmesh")
local navigation = pathfun.Navigation(navmesh)

local function insideRectangle(x, y, rectangle)
    if rectangle == nil then
        return false
    end
    return x > rectangle.x and x < rectangle.x + rectangle.w and y > rectangle.y and y < rectangle.y + rectangle.h
end

love.graphics.setDefaultFilter("nearest", "nearest")

--animations
local animationConfigs = {
    colors = {"blue", "red", "green", "yellow"},

    states = {
        idle = {
            columns = 2,
            rows = 3,
            duration = 0.1,
        },
        walk = {
            columns = 4,
            rows = 3,
            duration = 0.05,
        },
        hurt = {
            columns = 2,
            rows = 3,
            duration = 0.03,
        },
        death = {
            columns = 3,
            rows = 3,
            duration = 0.04,
        },
    },
}

local doodAnimations = {blue = {}, red = {}, green = {}, yellow = {}}

local COLLISION_RADIUS_RATIO = 0.1
local NAVIGATION_MARGIN = 2

local DEFAULTS = {
    SCALE = 2,
    ATTACK_TIME = 2.0,
    HURT_TIME = 0.3,
    SCAN_RADIUS = 800,
    SCAN_TIME = 2.0,
    DAMAGE = 10,
    HP = 100,
    MOVE_SPEED = 75,
    RESCUE_RATE = 5,
    SAFE_RESCUE_DISTANCE = 800, -- temporary
}

local function pauseDeathAtEnd(animation)
    animation:pauseAtEnd()
end

local function buildAnimationSet(color, state)
    local columns, rows = animationConfigs.states[state].columns, animationConfigs.states[state].rows
    local imageString = "assets/doods/"..color.."/"..state..".png"
    local image = love.graphics.newImage(imageString)
    local pw, ph = image:getPixelDimensions()
    local tpw = pw / columns
    local tph = ph / rows
    local iw, ih = image:getDimensions()
    local g = anim8.newGrid(tpw, tph, iw, ih)
    local onLoop = state == "death" and pauseDeathAtEnd or nil
    doodAnimations[color][state] = {}
    doodAnimations[color][state].image = image
    doodAnimations[color][state].down = anim8.newAnimation(g("1-"..animationConfigs.states[state].columns, "1-1"), animationConfigs.states[state].duration, onLoop) -- ("1-columns", "1-rows")
    doodAnimations[color][state].right = anim8.newAnimation(g("1-"..animationConfigs.states[state].columns, "2-2"), animationConfigs.states[state].duration, onLoop)
    doodAnimations[color][state].left = anim8.newAnimation(g("1-"..animationConfigs.states[state].columns, "2-2"), animationConfigs.states[state].duration, onLoop):flipH()
    doodAnimations[color][state].up = anim8.newAnimation(g("1-"..animationConfigs.states[state].columns, "3-3"), animationConfigs.states[state].duration, onLoop)
end

for _, color in pairs(animationConfigs.colors) do
    for state, _ in pairs(animationConfigs.states) do
        buildAnimationSet(color, state)
    end
end

local function cloneAnimationSet(source)
    local copy = {image = source.image}
    for dir, animation in pairs(source) do
        if dir ~= "image" then
            copy[dir] = animation:clone()
        end
    end
    return copy
end

local M = {}

function M.getNavigationClearance(color, scale)
    local spriteW = doodAnimations[color].idle.down:getDimensions()
    return spriteW * (scale or DEFAULTS.SCALE) * COLLISION_RADIUS_RATIO + NAVIGATION_MARGIN
end

local function setDirection(difX, difY, d)
    if difY > 0 and difY > difX then
        d.dir = "down"
    elseif difY < 0 and difY < difX then
        d.dir = "up"
    end
    if difX > 0 and difX > difY then
        d.dir = "right"
    elseif difX < 0 and difX < difY then
        d.dir = "left"
    end
end

local function stopMove(d)
    d.body:setLinearVelocity(0, 0)
    d.route = nil
    d.moveTargetX = nil
    d.moveTargetY = nil
    d.animation = d.animations.idle
    d.scanTimer = 0
    d.state = "idle"
end

function M.moveTo(d)
    if d.state ~= "pulling" then
        d.state = "walk"
    end

    d.animation = d.animations.walk

    if not d.route or #d.route == 0 then
        d.route = navigation:shortest_path(d.bodyX, d.bodyY, d.moveTargetX, d.moveTargetY)
        if not d.route or #d.route == 0 then
            d.body:setLinearVelocity(0, 0)
            return
        end
        d.routeIndex = 1
        d.routeTargetX, d.routeTargetY = d.moveTargetX, d.moveTargetY
    end

    local waypoint = d.route[d.routeIndex]
    if not waypoint then
        d.body:setLinearVelocity(0, 0)
        d.route = nil
        return
    end

    if d.targetRescueShrine and d.state == "pulling" then
        local shrineRadius = d.targetRescueShrine.shape:getRadius()
        local rescueShrineDis = love.physics.getDistance(d.fixture, d.targetRescueShrine.fixture)

        if rescueShrineDis <= shrineRadius then
            if d.rescueTarget.joint and d.rescueTarget.puller == d then
                d.rescueTarget.joint:destroy()
                d.rescueTarget.joint = nil
                d.rescueTarget.puller = nil
            end
            stopMove(d)
            return
        end
    end

    local difX = waypoint[1] - d.bodyX
    local difY = waypoint[2] - d.bodyY
    local distance = math.sqrt(difX * difX + difY * difY)

    if distance < 8 then
        d.routeIndex = d.routeIndex + 1
        if d.routeIndex > #d.route then
            stopMove(d)
            if d.command == "move" then
              d.command = nil
            end
        end
        return
    end

    d.body:setLinearVelocity(difX / distance * DEFAULTS.MOVE_SPEED,difY / distance * DEFAULTS.MOVE_SPEED)

    setDirection(difX, difY, d)
end

function M.getSmallestValueIndex(distances)
    local minDistance, minIndex
    for i, dis in pairs(distances) do
        if minDistance == nil or dis < minDistance then
            minDistance = dis
            minIndex = i
        end
    end
    return minIndex, minDistance
end

function M.clearTargets(d)
    d.command = nil
    d.moveTargetX, d.moveTargetY = nil, nil
    d.route, d.routeIndex = nil, nil

    if d.attackTarget then
        if d.attackTarget.attackers then
            d.attackTarget.attackers[d.index] = nil
        end
        d.attackTarget = nil
    end

    if d.rescueTarget then
        if d.rescueTarget.puller == d then
            d.rescueTarget.puller = nil
            if d.rescueTarget.joint then
                d.rescueTarget.joint:destroy()
                d.rescueTarget.joint = nil
            end
        end
        d.rescueTarget = nil
    end
end

function M.setAttackTarget(d, g, targetIndex)
    M.clearTargets(d)
    d.attackTarget = g.doods[targetIndex]
    if d.attackTarget then
        d.attackTarget.attackers = d.attackTarget.attackers or {}
        d.attackTarget.attackers[d.index] = d
    end
end

function M.healTarget(d, dt, target)
    d.state = "heal"
    local rescueRate = d.rescueRate or DEFAULTS.RESCUE_RATE
    target.hp = target.hp + rescueRate * dt

    if target.hp >= target.maxHp then
        target.hp = target.maxHp
        target.state = "idle"
        target.animation = target.animations.idle
        target.scanTimer = 0

        if target.puller == d then
            target.joint:destroy()
            target.joint = nil
            target.puller = nil
        end
        if d.targetRescueShrine then
            d.targetRescueShrine = nil
        end

        d.rescueTarget = nil
        d.state = "idle"
        d.animation = d.animations.idle
        d.scanTimer = 0
    end
end

function M.shrineScan(d, g)
    local friendlyShrineDistances = {}
    local neutralShrineDistances = {}
    local enemyShrineDistances = {}

    for i, s in ipairs(g.shrines) do
        local dis = love.physics.getDistance(d.fixture, s.fixture)

        if s.team == d.color then
            friendlyShrineDistances[i] = dis
        elseif s.team == "neutral" then
            neutralShrineDistances[i] = dis
        else
            enemyShrineDistances[i] = dis
        end
    end

    local closestFriendlyShrineIndex, closestFriendlyShrineDis = M.getSmallestValueIndex(friendlyShrineDistances)
    local closestFriendlyShrineX, closestFriendlyShrineY
    local closestNeutralShrineIndex, closestNeutralShrineDis = M.getSmallestValueIndex(neutralShrineDistances)
    local closestNeutralShrineX, closestNeutralShrineY
    local closestEnemyShrineIndex, closestEnemyShrineDis = M.getSmallestValueIndex(enemyShrineDistances)
    local closestEnemyShrineX, closestEnemyShrineY

    if closestFriendlyShrineIndex then
        closestFriendlyShrineX, closestFriendlyShrineY = g.shrines[closestFriendlyShrineIndex].body:getPosition()
    end
    if closestNeutralShrineIndex then
        closestNeutralShrineX, closestNeutralShrineY = g.shrines[closestNeutralShrineIndex].body:getPosition()
    end
    if closestEnemyShrineIndex then
        closestEnemyShrineX, closestEnemyShrineY = g.shrines[closestEnemyShrineIndex].body:getPosition()
    end

    return {
        closestFriendlyShrine = {
            index = closestFriendlyShrineIndex,
            dis = closestFriendlyShrineDis,
            x = closestFriendlyShrineX,
            y = closestFriendlyShrineY,
        },

        closestNeutralShrine = {
            index = closestNeutralShrineIndex,
            dis = closestNeutralShrineDis,
            x = closestNeutralShrineX,
            y = closestNeutralShrineY,
        },

        closestEnemyShrine = {
            index = closestEnemyShrineIndex,
            dis = closestEnemyShrineDis,
            x = closestEnemyShrineX,
            y = closestEnemyShrineY,
        },
    }
end

function M.doodScan(d, g)
    local closestEnemyX, closestEnemyY
    local enemyDistances = {}
    local downFriendlyDistances = {}

    for ii, dd in ipairs(g.doods) do
        -- local attackerCount = 0
        -- if dd.attackers then
        --     for _, _ in pairs(dd.attackers) do
        --         attackerCount = attackerCount + 1
        --     end
        -- end

        if dd ~= d and dd.color ~= d.color and dd.hp > 0 and dd.state ~= "downed" then
            local dis = love.physics.getDistance(d.fixture, dd.fixture)
            if dis <= DEFAULTS.SCAN_RADIUS then
                enemyDistances[ii] = dis
            end
        end

        if dd ~= d and dd.color == d.color and dd.state == "downed" and dd.puller == nil then
            local dis = love.physics.getDistance(d.fixture, dd.fixture)
            if dis <= DEFAULTS.SCAN_RADIUS then
                downFriendlyDistances[ii] = dis
            end
        end
    end

    local closestEnemyIndex, closestEnemyDis = M.getSmallestValueIndex(enemyDistances)
    if closestEnemyIndex then
        closestEnemyX, closestEnemyY = g.doods[closestEnemyIndex].body:getPosition()
    end
    local closestDownFriendlyIndex, closestDownFriendlyDis = M.getSmallestValueIndex(downFriendlyDistances)

    return {
        closestEnemy = {
            dis = closestEnemyDis,
            index = closestEnemyIndex,
            x = closestEnemyX,
            y = closestEnemyY,
        },

        closestDownFriendly = {
            dis = closestDownFriendlyDis,
            index = closestDownFriendlyIndex,
        },
    }
end

function M.update(dt, g)
    for i, d in ipairs(g.doods) do
        -- hurt timer
        if d.hurtTimer and d.hurtTimer > 0 and d.state ~= "downed"  then
            d.body:setLinearVelocity(0, 0)
            d.hurtTimer = d.hurtTimer - dt

            if d.hurtTimer <= 0 then
                d.hurtTimer = 0

                if d.hp > 0 then
                    d.animation = d.animations.idle
                elseif d.hp <= 0 then
                    d.hp = 0
                    if d.attackers then
                        for _, attacker in pairs(d.attackers) do
                            M.clearTargets(attacker)
                            attacker.body:setLinearVelocity(0, 0)

                            if attacker.state ~= "downed" then
                                attacker.state = "idle"
                                attacker.animation = attacker.animations.idle
                                attacker.scanTimer = 0
                            end
                        end
                        d.attackers = {}
                    end
                    M.clearTargets(d)
                    d.body:setLinearDamping(30)
                    d.state = "downed"
                    d.animation = d.animations.death
                end
            end
        end

        if not d.playerControlled and d.hurtTimer <= 0 and d.state ~= "downed" then
            -- attack
            if d.attackTarget then
                if d.attackTarget.state == "downed" or d.attackTarget.hp <= 0 then
                    M.clearTargets(d)
                    d.state = "idle"
                    d.animation = d.animations.idle
                    d.scanTimer = 0
                    return
                end

                local distance = love.physics.getDistance(d.fixture, d.attackTarget.fixture)

                if distance <= d.collisionRadius * 2 then
                    d.state = "fight"
                    d.animation = d.animations.idle
                    d.body:setLinearVelocity(0, 0)
                    d.moveTargetX, d.moveTargetY = nil, nil
                    d.route, d.routeIndex = nil, nil

                    if d.attackTimer <= 0 and d.state == "fight" then
                        local difX = d.attackTarget.bodyX - d.bodyX
                        local difY = d.attackTarget.bodyY - d.bodyY

                        setDirection(difX, difY, d)
                        d.attackTimer = DEFAULTS.ATTACK_TIME
                        d.attackTarget.hp = d.attackTarget.hp - d.damage
                        d.attackTarget.animation = d.attackTarget.animations.hurt
                        d.attackTarget.hurtTimer = DEFAULTS.HURT_TIME
                        if d.command == nil then
                            d.attackTarget.attackTarget = d
                        end
                    end
                    d.attackTimer = d.attackTimer - dt
                else
                    d.moveTargetX, d.moveTargetY = d.attackTarget.bodyX, d.attackTarget.bodyY

                    -- reset route if the target has moved from their original location
                    if d.route and d.routeTargetX and d.routeTargetY then
                        local difX = d.attackTarget.bodyX - d.routeTargetX
                        local difY = d.attackTarget.bodyY - d.routeTargetY

                        local repathTolerance = 12
                        if difX * difX + difY * difY >= repathTolerance * repathTolerance then
                            d.route, d.routeIndex = nil, nil
                        end
                    end
                end

            -- rescue
            elseif d.rescueTarget and d.state ~= "pulling" then
                local distance = love.physics.getDistance(d.fixture, d.rescueTarget.fixture)

                -- arrived at rescue target
                if distance <= d.collisionRadius * 2 then
                    d.animation = d.animations.idle
                    d.body:setLinearVelocity(0, 0)

                    -- scan for nearby enemies and nearest friendly shrine
                    local shrineScan = M.shrineScan(d, g)
                    local closestFriendlyShrine = shrineScan.closestFriendlyShrine
                    local scan = M.doodScan(d.rescueTarget, g)
                    local closestEnemy = scan.closestEnemy

                    if d.priority == "Default" then
                        if closestEnemy.index then
                            M.setAttackTarget(d, g, closestEnemy.index)
                            if d.rescueTarget then d.rescueTarget = nil end
                        else
                            M.healTarget(d, dt, d.rescueTarget)
                        end
                    elseif d.priority == "Medic" then
                        local closestFriendlyShrineDis = closestFriendlyShrine.dis
                        local closestFriendlyShrineRadius = g.shrines[closestFriendlyShrine.index].shape:getRadius()

                        if not closestEnemy.index or closestEnemy.dis > DEFAULTS.SAFE_RESCUE_DISTANCE or closestFriendlyShrineDis <= closestFriendlyShrineRadius then
                            M.healTarget(d, dt, d.rescueTarget)

                        elseif not d.rescueTarget.joint and not d.rescueTarget.puller then
                            d.rescueTarget.joint = love.physics.newDistanceJoint(d.body, d.rescueTarget.body, d.bodyX, d.bodyY, d.rescueTarget.bodyX, d.rescueTarget.bodyY, false)
                            d.rescueTarget.puller = d

                            if d.rescueTarget.joint and d.rescueTarget.puller == d then
                                d.state = "pulling"
                                if closestFriendlyShrine then
                                    d.moveTargetX, d.moveTargetY = closestFriendlyShrine.x, closestFriendlyShrine.y
                                    d.targetRescueShrine = g.shrines[closestFriendlyShrine.index]
                                end
                            end
                        end

                    elseif d.priority == "Nearest" then
                        M.healTarget(d, dt, d.rescueTarget)
                    end
                else
                    d.moveTargetX, d.moveTargetY = d.rescueTarget.bodyX, d.rescueTarget.bodyY
                end
            end

            -- move
            if d.moveTargetX and d.moveTargetY then
                -- clamp move target inside map boundaries
                if d.moveTargetX < 0 or d.moveTargetX > g.boundary.rightX or d.moveTargetY < 0 or d.moveTargetY > g.boundary.bottomY then
                    if d.moveTargetX > g.boundary.rightX then
                        d.moveTargetX = g.boundary.rightX - d.collisionRadius * 2
                    elseif d.moveTargetX < 0 then
                        d.moveTargetX = 0 + d.collisionRadius * 2
                    end
                    if d.moveTargetY > g.boundary.bottomY then
                        d.moveTargetY = g.boundary.bottomY - d.collisionRadius * 2
                    elseif d.moveTargetY < 0 then
                        d.moveTargetY = 0 + d.collisionRadius * 2
                    end
                end
                M.moveTo(d)
            end

            -- idle scanning
            if d.command == nil and (d.state == "idle" or d.state == "walk") then
                if d.state == "idle" then
                    M.clearTargets(d)
                end

                d.scanTimer = d.scanTimer - dt
                if d.scanTimer <= 0 then
                    d.scanTimer = DEFAULTS.SCAN_TIME

                    local scan = M.doodScan(d, g)
                    local closestEnemy = {
                        dis = scan.closestEnemy and scan.closestEnemy.dis,
                        index = scan.closestEnemy and scan.closestEnemy.index,
                        dood = g.doods[scan.closestEnemy.index],
                    }

                    local closestDownFriendly = {
                        dis = scan.closestDownFriendly and scan.closestDownFriendly.dis,
                        index = scan.closestDownFriendly and scan.closestDownFriendly.index,
                        dood = g.doods[scan.closestDownFriendly.index],
                    }

                    local shrineScan = M.shrineScan(d, g)
                    local closestNeutralShrineDis = shrineScan and shrineScan.closestNeutralShrine.dis
                    local closestNeutralShrineIndex = shrineScan and shrineScan.closestNeutralShrine.index
                    local closestNeutralShrine = g.shrines[closestNeutralShrineIndex]

                    local closestEnemyShrineDis = shrineScan and shrineScan.closestEnemyShrine.dis
                    local closestEnemyShrineIndex = shrineScan and shrineScan.closestEnemyShrine.index
                    local closestEnemyShrine = g.shrines[closestEnemyShrineIndex]

                    if d.priority == "Default" then
                        if closestEnemy.index then
                            M.setAttackTarget(d, g, closestEnemy.index)
                        elseif closestDownFriendly.index then
                            d.rescueTarget = g.doods[closestDownFriendly.index]
                        end
                    elseif d.priority == "Medic" then
                        if closestDownFriendly.index then
                            d.rescueTarget = g.doods[closestDownFriendly.index]
                        elseif closestEnemy.index then
                            M.setAttackTarget(d, g, closestEnemy.index)
                        end
                    elseif d.priority == "Nearest" then
                        if closestEnemy.index and closestDownFriendly.index then
                            if closestEnemy.dis <= closestDownFriendly.dis then
                                M.setAttackTarget(d, g, closestEnemy.index)
                            else
                                d.rescueTarget = g.doods[closestDownFriendly.index]
                            end
                        elseif closestEnemy.index then
                            M.setAttackTarget(d, g, closestEnemy.index)
                        elseif closestDownFriendly.index then
                            d.rescueTarget = g.doods[closestDownFriendly.index]
                        end
                    end
                end

                -- wander
                if d.wanderTimer > 0 and d.state ~= "downed" then
                    d.wanderTimer = d.wanderTimer - dt
                    if d.wanderTimer <= 0 then
                        local rx = love.math.random(d.bodyX - 30, d.bodyX + 30)
                        local ry = love.math.random(d.bodyY - 30, d.bodyY + 30)
                        d.moveTargetX = rx
                        d.moveTargetY = ry
                        d.wanderTimer = love.math.random(4,8)
                    end
                end
            end
        end

        -- check if inside selection box
        if g.mouseStates.leftClickDown and g.selectionBox.w ~= nil or g.selectionBox.h ~= nil then
            if insideRectangle(d.bodyX, d.bodyY, g.selectionBox) then
                d.insideSelectionBox = true
            else
                d.insideSelectionBox = false
            end
        end

        -- animations
        local animateSpeed = 0.2
        d.animation[d.dir]:update(animateSpeed * dt)

        d.bodyX, d.bodyY = d.body:getPosition()
        d.x = d.bodyX - d.spriteW * d.scale / 2
        d.y = d.bodyY - d.spriteH * d.scale / 2 - d.collisionOffsetY
    end
end

function M.newDood(x, y, color, g)
    local animations = {
        idle = cloneAnimationSet(doodAnimations[color].idle),
        walk = cloneAnimationSet(doodAnimations[color].walk),
        hurt = cloneAnimationSet(doodAnimations[color].hurt),
        death = cloneAnimationSet(doodAnimations[color].death),
    }

    local scale = DEFAULTS.SCALE
    local spriteW, spriteH = animations.idle.down:getDimensions()
    local spriteX, spriteY = x - spriteW / 2 * scale, y - spriteH / 2 * scale

    local collisionRadius = spriteW * scale * COLLISION_RADIUS_RATIO
    local collisionW = collisionRadius * 2
    local collisionH = spriteH * scale * 0.2
    local collisionPadding = 18
    local collisionOffsetY = (spriteH * scale / 2 - collisionRadius) - collisionPadding

    local bodyX, bodyY = spriteX + spriteW * scale / 2, spriteY + spriteH * scale / 2 + collisionOffsetY
    local body = love.physics.newBody(g.world, bodyX, bodyY, "dynamic")
    local shape = love.physics.newCircleShape(0, 0, collisionRadius)
    local fixture = love.physics.newFixture(body, shape, 1)

    body:setFixedRotation(true)
    body:setLinearDamping(2)
    fixture:setFriction(0)

    local dood = {
        hp = DEFAULTS.HP,
        maxHp = DEFAULTS.HP,
        damage = DEFAULTS.DAMAGE,
        moveSpeed = DEFAULTS.MOVE_SPEED,
        priority = "Medic",
        state = "idle",
        dir = "down",
        x = bodyX - spriteW * scale / 2,
        y = bodyY - spriteH * scale / 2 - collisionOffsetY,
        playerControlled = false,
        selected = false,
        command = nil,
        puller = nil,
        animations = animations,
        animation = animations.idle,
        stopCheckTimer = 0,
        wanderTimer = love.math.random(4,8),
        attackTimer = 0,
        hurtTimer = 0,
        scanTimer = 0,
        color = color,
        index = #g.doods + 1,
        body = body,
        bodyX = bodyX,
        bodyY = bodyY,
        scale = scale,
        spriteW = spriteW,
        spriteH = spriteH,
        collisionW = collisionW,
        collisionH = collisionH,
        collisionRadius = collisionRadius,
        collisionOffsetY = collisionOffsetY,
        shape = shape,
        fixture = fixture,
    }

    table.insert(g.doods, dood)
end

return {
    M = M,
    DEFAULTS = DEFAULTS,
}