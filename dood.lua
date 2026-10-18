local anim8 = require("libs/anim8")
local pathfun = require("libs/pathfun")
local navmesh = require("maps/map1shrinetest-navmesh")
local navigation = pathfun.Navigation(navmesh)

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
    SCAN_RADIUS = 400,
    SCAN_TIME = 2.0,
    DAMAGE = 10,
    HP = 100,
    MOVE_SPEED = 75,
    RESCUE_RATE = 5,
    SAFE_RESCUE_DISTANCE = 500,
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

function M.moveTo(d)
    d.state = "walk"
    d.animation = d.animations.walk

    if not d.route or #d.route == 0 then
        local bodyX, bodyY = d.body:getPosition()
        d.route = navigation:shortest_path(bodyX, bodyY, d.moveTargetX, d.moveTargetY)
        if not d.route or #d.route == 0 then
            d.body:setLinearVelocity(0, 0)
            return
        end
        d.routeIndex = 1
    end

    local waypoint = d.route[d.routeIndex]
    if not waypoint then
        d.body:setLinearVelocity(0, 0)
        d.route = nil
        return
    end

    local bodyX, bodyY = d.body:getPosition()
    local difX = waypoint[1] - bodyX
    local difY = waypoint[2] - bodyY
    local distance = math.sqrt(difX * difX + difY * difY)

    if distance < 8 then
        d.routeIndex = d.routeIndex + 1
        if d.routeIndex > #d.route then
            d.body:setLinearVelocity(0, 0)
            d.route = nil
            d.moveTargetX = nil
            d.moveTargetY = nil
            d.state = "idle"
            d.animation = d.animations.idle
            return
        end
        return
    end
    d.body:setLinearVelocity(difX / distance * DEFAULTS.MOVE_SPEED,difY / distance * DEFAULTS.MOVE_SPEED)

    if difY > 0 then
        d.dir = "down"
    elseif difY < 0 then
        d.dir = "up"
    end
    if difX > 0 then
        d.dir = "right"
    elseif difX < 0 then
        d.dir = "left"
    end
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
    d.moveTargetX = nil
    d.moveTargetY = nil

    if d.attackTarget then
        if d.attackTarget.attackers then
            d.attackTarget.attackers[d.index] = nil
        end
        d.attackTarget = nil
    end

    if d.rescueTarget then
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
    local rescueRate = d.rescueRate or DEFAULTS.RESCUE_RATE

    if target.joint then
        target.joint:destroy()
        target.joint = nil
    end

    target.hp = target.hp + rescueRate * dt

    if target.hp >= target.maxHp then
        target.hp = target.maxHp
        target.state = "idle"
        target.animation = target.animations.idle
        target.scanTimer = 0
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
            y = closestFriendlyShrineY + 50,
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
        if dd ~= d and dd.color ~= d.color and dd.hp > 0 and dd.state ~= "downed" then
            local dis = love.physics.getDistance(d.fixture, dd.fixture)
            if dis <= DEFAULTS.SCAN_RADIUS then
                enemyDistances[ii] = dis
            end
        end

        if dd ~= d and dd.color == d.color and dd.state == "downed" and not dd.joint then
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
                            attacker.attackTarget = nil
                            attacker.moveTargetX, attacker.moveTargetY = nil, nil
                            attacker.route, attacker.routeIndex = nil, nil
                            attacker.body:setLinearVelocity(0, 0)

                            if attacker.state ~= "downed" then
                                attacker.state = "idle"
                                attacker.animation = attacker.animations.idle
                                attacker.scanTimer = 0
                            end
                        end
                        d.attackers = {}
                    end
                    d.moveTargetX = nil
                    d.moveTargetY = nil
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
                    d.attackTarget = nil
                    return
                end
                local distance = love.physics.getDistance(d.fixture, d.attackTarget.fixture)

                if distance <= d.collisionRadius * 2 then
                    d.state = "attack"
                    d.animation = d.animations.idle
                    d.body:setLinearVelocity(0, 0)
                    d.moveTargetX, d.moveTargetY = nil, nil
                    d.route, d.routeIndex = nil, nil

                    if d.attackTimer <= 0 then
                        local bodyX, bodyY = d.body:getPosition()
                        local targetX, targetY = d.attackTarget.body:getPosition()

                        if targetY > bodyY then
                            d.dir = "down"
                        elseif targetY < bodyY then
                            d.dir = "up"
                        end
                        if targetX > bodyX then
                            d.dir = "right"
                        elseif targetX < bodyX then
                            d.dir = "left"
                        end

                        d.attackTarget.hp = d.attackTarget.hp - d.damage
                        d.attackTimer = DEFAULTS.ATTACK_TIME

                        d.attackTarget.animation = d.attackTarget.animations.hurt
                        d.attackTarget.hurtTimer = DEFAULTS.HURT_TIME
                        d.attackTarget.attackTarget = d.attackTarget.attackTarget or d
                    end
                    d.attackTimer = d.attackTimer - dt
                else
                    d.moveTargetX, d.moveTargetY = d.attackTarget.body:getPosition()
                end

            -- rescue
            elseif d.rescueTarget then
                local distance = love.physics.getDistance(d.fixture, d.rescueTarget.fixture)

                if distance <= d.collisionRadius * 2 then
                    d.state = "rescue"
                    d.animation = d.animations.idle
                    d.body:setLinearVelocity(0, 0)
                    if d.state == "rescue" then
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
                            if not closestEnemy.index or closestEnemy.dis > DEFAULTS.SAFE_RESCUE_DISTANCE or d.targetRescueShrine and d.rescueTarget.joint then
                                M.healTarget(d, dt, d.rescueTarget)

                            elseif not d.rescueTarget.joint then
                                local bodyX, bodyY = d.body:getPosition()
                                local targetBodyX, targetbodyY = d.rescueTarget.body:getPosition()
                                d.rescueTarget.joint = love.physics.newDistanceJoint(d.body, d.rescueTarget.body, bodyX, bodyY, targetBodyX, targetbodyY, false)

                                if d.rescueTarget.joint then
                                    local shrineScan = M.shrineScan(d, g)
                                    local closestFriendlyShrine = shrineScan.closestFriendlyShrine
                                    if closestFriendlyShrine then
                                        d.rescueTarget.body:setLinearDamping(2)
                                        d.moveTargetX, d.moveTargetY = closestFriendlyShrine.x, closestFriendlyShrine.y
                                        d.targetRescueShrine = g.shrines[closestFriendlyShrine.index]
                                    end
                                end
                            end

                        elseif d.priority == "Nearest" then
                            M.healTarget(d, dt, d.rescueTarget)
                        end
                    end
                else
                    d.moveTargetX, d.moveTargetY = d.rescueTarget.body:getPosition()
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
            if d.state == "idle" then
                d.body:setLinearDamping(2)
                if d.rescueTarget and d.rescueTarget.joint then
                    d.rescueTarget.joint:destroy()
                    d.rescueTarget.joint = nil
                end

                d.scanTimer = d.scanTimer - dt
                if d.scanTimer <= 0 then
                    d.scanTimer = DEFAULTS.SCAN_TIME
                    local scan = M.doodScan(d, g)
                    local closestEnemy = scan.closestEnemy
                    local closestDownFriendly = scan.closestDownFriendly

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
                        local bodyX, bodyY = d.body:getPosition()
                        local rx = love.math.random(bodyX - 30, bodyX + 30)
                        local ry = love.math.random(bodyY - 30, bodyY + 30)
                        d.moveTargetX = rx
                        d.moveTargetY = ry
                        d.wanderTimer = love.math.random(4,8)
                    end
                end
            end
        end

        -- animations
        local animateSpeed = 0.2
        d.animation[d.dir]:update(animateSpeed * dt)

        local bodyX, bodyY = d.body:getPosition()
        d.x = bodyX - d.spriteW * d.scale / 2
        d.y = bodyY - d.spriteH * d.scale / 2 - d.collisionOffsetY
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

    local body = love.physics.newBody(
        g.world,
        spriteX + spriteW * scale / 2,
        spriteY + spriteH * scale / 2 + collisionOffsetY,
        "dynamic"
    )

    local shape = love.physics.newCircleShape(0, 0, collisionRadius)
    local fixture = love.physics.newFixture(body, shape, 1)

    body:setFixedRotation(true)
    fixture:setFriction(0)

    local dood = {
        hp = DEFAULTS.HP,
        maxHp = DEFAULTS.HP,
        damage = DEFAULTS.DAMAGE,
        moveSpeed = DEFAULTS.MOVE_SPEED,
        priority = "Medic",
        state = "idle",
        dir = "down",
        x = x,
        y = y,
        playerControlled = false,
        selected = false,
        pulling = false,
        animations = animations,
        animation = animations.idle,
        stopCheckTimer = 0,
        wanderTimer = love.math.random(3,6),
        attackTimer = 0,
        hurtTimer = 0,
        scanTimer = 0,
        color = color,
        index = #g.doods + 1,
        body = body,
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