local syncedEntities = {}

RegisterNetEvent("st-interaction:server:syncEntities", function(netIds)
    for netId in pairs(netIds) do
        syncedEntities[netId] = true
    end
end)

AddEventHandler('entityRemoved', function(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    if syncedEntities[netId] then
        syncedEntities[netId] = nil
        TriggerClientEvent("st-interaction:client:entityRemoved", -1, netId)
    end
end)