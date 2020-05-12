--[[
    Sonaran CAD Plugins

    Plugin Name: apicheck
    Creator: SonoranCAD
    Description: Implements checking if a particular API ID exists

]]

local pluginConfig = Config.plugins["apicheck"]

registerApiType("CHECK_APIID", "general")

function cadApiIdExists(apiId, callback)
    performApiRequest({["apiId"] = apiId}, "CHECK_APIID", function(res, exists)
        callback(exists)
    end)
end

RegisterServerEvent("SonoranCAD::apicheck:CheckPlayerLinked")
AddEventHandler("SonoranCAD::apicheck:CheckPlayerLinked", function(player)
    local identifier = GetIdentifiers(player)[Config.primaryIdentifier]
    cadApiIdExists(identifier, function(exists)
        TriggerEvent("SonoranCAD::apicheck:CheckPlayerLinkedResponse", player, identifier, exists)
    end)
end)

exports('CadIsPlayerLinked', cadApiIdExists)