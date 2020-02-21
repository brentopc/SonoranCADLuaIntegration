--[[
        SonoranCAD FiveM - A SonoranCAD integration for FiveM servers
         Copyright (C) 2020  Sonoran Software

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program in the file "LICENSE".  If not, see <http://www.gnu.org/licenses/>.
]]

---------------------------------------------------------------------------
-- Reading Config options from config.json
---------------------------------------------------------------------------
local loadFile = LoadResourceFile(GetCurrentResourceName(), "./config.json")
local config = {}
config = json.decode(loadFile)

local communityID = config.communityId
local apiKey = config.apiKey
local apiURL = config.apiUrl
local postTime = config.locationPostTime  -- Lowering this value will result in rate limiting, must be > 5000
---------------------------------------------------------------------------
-- Server Event Handling **DO NOT EDIT UNLESS YOU KNOW WHAT YOU ARE DOING**
---------------------------------------------------------------------------

-- Return client SteamHex request
RegisterServerEvent("sonorancad:GetSteamHex")
AddEventHandler("sonorancad:GetSteamHex", function(srscsd)
    local steamHex = GetPlayerIdentifier(srscsd, 0)
    TriggerClientEvent('sonorancad:ReturnSteamHex', srscsd, steamHex)
end)

        ---------------------------------
        -- Unit Panic
        ---------------------------------
 
-- Client Panic request
RegisterServerEvent('sonorancad:cadSendPanicApi')
AddEventHandler('sonorancad:cadSendPanicApi', function(steamHex, currentLocation)
    PerformHttpRequest(apiURL, function(statusCode, res, headers) 
    end, "POST", json.encode({['id'] = communityID, ['key'] = apiKey, ['type'] = 'UNIT_PANIC', ['data'] = {{ ['isPanic'] = true, ['apiId'] = steamHex}}}), {["Content-Type"]="application/json"})
end)

        ---------------------------------
        -- Unit Location Update
        ---------------------------------

-- Pending location updates array
LocationCache = {}

-- Main api POST function
local function SendLocations()
    PerformHttpRequest(apiURL, function(statusCode, res, headers) 
    end, "POST", json.encode({['id'] = communityID,['key'] = apiKey,['type'] = 'UNIT_LOCATION',['data'] = LocationCache}), {["Content-Type"]="application/json"})
end

-- Main update thread sending api location update POST requests per the postTime interval
Citizen.CreateThread(function()
    while true do
        if #LocationCache > 0 then
            -- Make API request if 1 or more updates exist
            SendLocations()
            -- Clear pending location calls
            LocationCache = {}
        end
        -- Wait the (5000ms) delay to check for pending location calls
        Citizen.Wait(postTime)
    end
end)

-- Helper function to determine index of given steamHex
local function findIndex(steamHex)
    for i,loc in ipairs(LocationCache) do
        if loc.apiId == steamHex then
            return i
        end
    end
end

-- Event from client when location changes occur
RegisterServerEvent('sonorancad:cadSendLocation')
AddEventHandler('sonorancad:cadSendLocation', function(steamHex, currentLocation)
    -- Does this client location already exist in the pending location array?
    local index = findIndex(steamHex)
    if index then
        -- Location already in pending array -> Update
        LocationCache[index].location = currentLocation
    else
        -- Location does not exist in pending array -> Insert new location object
        table.insert(LocationCache, {['apiId'] = steamHex, ['location'] = currentLocation})
    end
end)

---------------------------------------------------------------------------
-- Do stuff with data from listener :)
---------------------------------------------------------------------------
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function getPlayerSource(identifier)
    local activePlayers = GetActivePlayers();
    for i,player in pairs(activePlayers) do
        if GetPlayerIdentifier(player) == identifier then
            print("found player " .. tostring(i) .. " by identifier " .. identifier)
            return i
        end
    end
    print("ERROR: Could not find player with identifier " .. identifier)
end

RegisterServerEvent('recieveListenerData')
AddEventHandler('recieveListenerData', function(call)
    print('TRIGGERED LUA EVENT! :)')
    print(dump(call))
    if call.type == "UNIT_UPDATE" then
        targetPlayer = getPlayerSource(call.data.apiId)
        TriggerClientEvent('sonorancad:livemap:unitUpdate', targetPlayer, call.data)
    end
end)