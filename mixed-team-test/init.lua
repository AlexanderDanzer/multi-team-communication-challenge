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


local function sendPlan()
    local mixedTeamMessage = {}
    mixedTeamMessage[5] = { role = "Defense" }
    mixedTeamMessage[9] = { role = "Defense", shootPos = World.Geometry.OpponentGoal }
    mixedTeamMessage[11] = { role = "Defense" }

    mixedTeamMessage[10] = { role = "Goalie" }

    mixedTeamMessage[4] = { role = "Offense", targetPos = Vector(0,0) }
    mixedTeamMessage[3] = { role = "Offense" }

    MixedTeam.sendInfo(mixedTeamMessage)
end

Entrypoints.add("sendPlan", sendPlan)

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
