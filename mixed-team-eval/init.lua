--[[***********************************************************************
*   Copyright 2017 Alexander Danzer                                       *
*   Robotics Erlangen e.V.                                                *
*   http://www.robotics-erlangen.de/                                      *
*   info@robotics-erlangen.de                                             *
*                                                                         *
*   This program is free software: you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation, either version 3 of the License, or     *
*   any later version.                                                    *
*                                                                         *
*   This program is distributed in the hope that it will be useful,       *
*   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
*   GNU General Public License for more details.                          *
*                                                                         *
*   You should have received a copy of the GNU General Public License     *
*   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
*************************************************************************]]

require("../base/globalschecker").enable()
require "../base/base"
-- luacheck: push globals Class
Class = require "../base/class"
-- luacheck: pop
local Entrypoints = require "../base/entrypoints"
local World = require "../base/world"

local Cache = require "../base/cache"
local debug = require "../base/debug"
local Referee = require "../base/referee"
local plot = require "../base/plot"
local MixedTeam = require "../base/mixedteam"
local Field = require "../base/field"
local vis = require "../base/vis"

local function getDefendersAndAttackers()
    local defenders = {}
    local attackers = {}
    local unassigned = {}
    if World.MixedTeam then
        for robotId, msg in pairs(World.MixedTeam) do
            if msg.role == "Defense" then
                table.insert(defenders, World.FriendlyRobotsById[robotId])
            elseif msg.role == "Offense" then
                table.insert(attackers, World.FriendlyRobotsById[robotId])
            end
        end
    end
    for _, robot in pairs(World.FriendlyRobotsById) do
        if not ((table.contains(defenders, robot))
            or (table.contains(attackers, robot))
            or robot == World.FriendlyKeeper)
        then
            table.insert(unassigned, robot)
        end
    end
    debug.set("attackers", attackers)
    debug.set("defenders", defenders)
    debug.set("unassigned", unassigned)
    return defenders, attackers, unassigned
end

local function illustratePositionsAndForwardMessages()
    if World.MixedTeam then
        for robotId, msg in pairs(World.MixedTeam) do
            local robot =  World.FriendlyRobotsById[robotId]
            if robot then
                if msg.role == "Defense" then
                    vis.addCircle("defenders", robot.pos, 0.15, vis.colors.greenHalf, true)
                elseif msg.role == "Offense" then
                    vis.addCircle("attackers", robot.pos, 0.15, vis.colors.redHalf, true)
                elseif msg.role == "Goalie" then
                    vis.addCircle("goalie", robot.pos, 0.15, vis.colors.blackHalf, true)
                else
                    vis.addCircle("unassigned", robot.pos, 0.15, vis.colors.whiteHalf, true)
                end
                if msg.targetPos then
                    vis.addPath("nav targets", {robot.pos, msg.targetPos}, vis.colors.blue)
                    vis.addCircle("nav targets", msg.targetPos, 0.05, vis.colors.blue, true)
                end
                if msg.shootPos then
                    vis.addPath("shoot pos", {robot.pos, msg.shootPos}, vis.colors.orangeHalf)
                    vis.addCircle("shoot pos", msg.shootPos, 0.05, vis.colors.orangeHalf, true)
                end
            end
        end
        MixedTeam.sendInfo(World.MixedTeam)
    end
end

local taskFulfilled = false

local function task1()
    illustratePositionsAndForwardMessages()
    local defenders, attackers, unassigned = getDefendersAndAttackers();

    local atLeastTwoOfEach = #attackers > 1 and #defenders > 1
    debug.set("2 attackers and defenders", atLeastTwoOfEach)
    local defenderDistOk = true
    for _, robot in ipairs(defenders) do
        local dist = (World.Geometry.FriendlyGoal - robot.pos):length()
        if dist > 2 or Field.isInFriendlyDefenseArea(robot.pos, -robot.radius) then
            defenderDistOk = false
            break
        end
    end
    debug.set("defender dist OK", defenderDistOk)

    local attackerDistOk = true
    for _, robot in ipairs(attackers) do
        local dist = (World.Geometry.OpponentGoal - robot.pos):length()
        if dist > 2 or Field.isInOpponentDefenseArea(robot.pos, -robot.radius) then
            attackerDistOk = false
            break
        end
    end
    debug.set("attacker dist OK", attackerDistOk)

    local goalie = World.FriendlyKeeper or false
    local goalieOk = goalie and Field.isInFriendlyDefenseArea(goalie.pos, -goalie.radius)
    debug.set("goalie OK", goalieOk)

    local allHaveRoles = #unassigned == 0
    debug.set("all robots have roles", allHaveRoles)

    if atLeastTwoOfEach and defenderDistOk and attackerDistOk and goalieOk
         and allHaveRoles and not taskFulfilled
    then
        taskFulfilled = true
        log("Task fulfilled")
    end
end



local function task2()
    illustratePositionsAndForwardMessages()
    local defenders, attackers, unassigned = getDefendersAndAttackers();

    local atLeast9 = #defenders >= 9
    debug.set("at least 9 defenders", atLeast9)

    local lessThan10cm = true
    for _, robot in ipairs(defenders) do
        if Field.distanceToFriendlyDefenseArea(robot.pos, robot.radius) > 0.1 then
            lessThan10cm = false
        end
    end
    debug.set("less than 10cm dist", lessThan10cm)

    local nooneInsideDefenseArea = true
    for _, robot in ipairs(defenders) do
        if Field.isInFriendlyDefenseArea(robot.pos, robot.radius) then
            nooneInsideDefenseArea = false
        end
    end
    debug.set("noone inside def area", nooneInsideDefenseArea)

    if atLeast9 and lessThan10cm and nooneInsideDefenseArea and not taskFulfilled then
        taskFulfilled = true
        log("Task fulfilled")
    end
end

local firstTouchingRobot
local touchingRobots = {}
local chosenRobot
local function task3()
    illustratePositionsAndForwardMessages()

    if World.MixedTeam then
        for robotId, msg in pairs(World.MixedTeam) do
            if msg.shootPos then
                 chosenRobot = World.FriendlyRobotsById[robotId]
            end
        end
    end
    debug.set("chosen robot", chosenRobot)

    local touchingRobot = Referee.robotAndPosOfLastBallTouch()
    if touchingRobot then
        if not table.contains(touchingRobots, touchingRobot) then
            table.insert(touchingRobots, touchingRobot)
        end
        if not firstTouchingRobot then
            firstTouchingRobot = touchingRobot
        end
    end
    debug.set("first touching robot", firstTouchingRobot)
    debug.set("touching robots", touchingRobots)

    local noOtherTouched = #touchingRobots < 3
    debug.set("no other touched", noOtherTouched)

    local chosenRobotTouched = table.contains(touchingRobots, chosenRobot)
    debug.set("chosen robot touched", chosenRobotTouched)

    local ballInsideGoal = World.Ball.pos.y > World.Geometry.FieldHeightHalf
        and math.abs(World.Ball.pos.x) < World.Geometry.GoalWidth/2
    debug.set("ball inside goal", ballInsideGoal)

    if chosenRobotTouched and noOtherTouched and ballInsideGoal and not taskFulfilled then
        taskFulfilled = true
        log("Task fulfilled")
    end
end

Entrypoints.add("Idle", illustratePositionsAndForwardMessages)
Entrypoints.add("Task 1", task1)
Entrypoints.add("Task 2", task2)
Entrypoints.add("Task 3", task3)

local frameCount = 0
local wrapper = function (func)
    return function()
        frameCount = frameCount + 1
        if not World.update() then
            if (frameCount % 100) == 0 then
                log("Waiting for vision data...")
            end
            return -- skip processing if no vision data is available yet
        end
        Referee.check()
        debug.set("frame", frameCount)
        if not func() then -- Entrypoint has to return true if robots shouldn't be stopped on halt
            if World.RefereeState == "Halt" then
                World.haltOwnRobots()
            end
        end
        World.setRobotCommands()
        debug.resetStack()
        Cache.resetFrame()
        plot._plotAggregated()
    end
end

return {name = "MixedTeamEvaluation", entrypoints = Entrypoints.get(wrapper)}
