local Peds = {}

local NPC_GRID_BITSHIFT  = 13
local NPC_GRID_SIZE = 64.0

local NPC_deltas = {
    vector2(-1, -1), vector2(-1, 0), vector2(-1, 1),
    vector2(0, -1), vector2(0, 1),
    vector2(1, -1), vector2(1, 0), vector2(1, 1),
}

local function NPC_GetGridChunk(x) return math.floor((x + 8192.0) / NPC_GRID_SIZE) end
local function NPC_GetChunkId(v)   return (v.x << NPC_GRID_BITSHIFT) | v.y end
local function NPC_ChunkFromVec3(pos)
    return NPC_GetChunkId(vector2(NPC_GetGridChunk(pos.x), NPC_GetGridChunk(pos.y)))
end

local function NPC_GetNearbyChunkIds(pos)
    local list, seen = {}, {}
    local base = vector2(NPC_GetGridChunk(pos.x), NPC_GetGridChunk(pos.y))
    local function add(v)
        local id = NPC_GetChunkId(v)
        if not seen[id] then seen[id] = true; list[#list+1] = id end
    end
    add(base)
    for i=1,#NPC_deltas do add(base + NPC_deltas[i]) end
    return list
end

local NPC_Grid = {}
local function NPC_grid_add(chunkId, name)
    local b = NPC_Grid[chunkId]; if not b then b = {}; NPC_Grid[chunkId] = b end
    b[name] = true
end

local function NPC_grid_remove(chunkId, name)
    local b = NPC_Grid[chunkId]; if not b then return end
    b[name] = nil
    if not next(b) then NPC_Grid[chunkId] = nil end
end

local function NPC_IsSpawnAllowed(entry, playerCoords, dist)
    local canSpawn = entry.data and entry.data.canSpawn
    if canSpawn == nil then return true end

    local ok, result = pcall(canSpawn, entry, playerCoords, dist)
    if not ok then
        print(("[NPC] canSpawn errored for '%s': %s"):format(tostring(entry.data and entry.data.name or "unknown"), tostring(result)))
        return false
    end

    return result and true or false
end

local function SpawnPed(selectedPed)
    if not selectedPed then return end
    if DoesEntityExist(selectedPed.spawnedPed) then return end

    if type(selectedPed.model) ~= 'number' then
        selectedPed.model = joaat(selectedPed.model)
    end

    if not IsModelValid(selectedPed.model) and not IsModelInCdimage(selectedPed.model) then
        print(("Attempted to load invalid model '%s'"):format(selectedPed.model))
        return
    end
    
    if not HasModelLoaded(selectedPed.model) then
        RequestModel(selectedPed.model)
        while not HasModelLoaded(selectedPed.model) do Wait(5) end
    end

    local ped = CreatePed(4, selectedPed.model, selectedPed.spawnCoords, selectedPed.spawnHeading, false, true)
    SetEntityHeading(ped, selectedPed.spawnHeading)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedHearingRange(ped, 0.0)
    SetPedSeeingRange(ped, 0.0)
    SetPedAlertness(ped, 0.0)
    SetPedFleeAttributes(ped, 0, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedFleeAttributes(ped, 0, 0)
    TriggerEvent('blockdrugs', ped)
    SetModelAsNoLongerNeeded(selectedPed.model)

    selectedPed.spawnedPed = ped
    if selectedPed.data and selectedPed.data.onSpawn then
        pcall(selectedPed.data.onSpawn, ped)
    end
end

local function DespawnPed(pedEntry)
    if pedEntry.data and pedEntry.data.onDespawn then
        pcall(pedEntry.data.onDespawn, pedEntry.spawnedPed)
    end
    if DoesEntityExist(pedEntry.spawnedPed) then
        DeleteEntity(pedEntry.spawnedPed)
    end
    pedEntry.spawnedPed = nil
end

local function AddNPCPed(name, npcModel, spawnCoords, options)
    local invokingResource = GetInvokingResource()
    local entry = {
        model = npcModel,
        spawnCoords = spawnCoords,
        spawnHeading = (options and options.spawnHeading) or 0.0,
        distance = (options and options.distance) or 20.0,
        resource = invokingResource,
        data = options,
        _chunkId = NPC_ChunkFromVec3(spawnCoords),
    }

    if entry.data then entry.data.name = name end

    Peds[name] = entry
    NPC_grid_add(entry._chunkId, name)
end
exports('AddNPCPed', AddNPCPed)

local function RemoveNPCPed(name)
    local e = Peds[name]
    if e then
        DespawnPed(e)
        if e._chunkId then NPC_grid_remove(e._chunkId, name) end
    end
    Peds[name] = nil
end
exports('RemoveNPCPed', RemoveNPCPed)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local chunks = NPC_GetNearbyChunkIds(playerCoords)

        local candidate = {}
        for i=1,#chunks do
            local bucket = NPC_Grid[chunks[i]]
            if bucket then
                for name in pairs(bucket) do candidate[name] = true end
            end
        end

        for name in pairs(candidate) do
            local e = Peds[name]
            if e then
                local dist = #(e.spawnCoords - playerCoords)
                local withinDistance = dist <= e.distance
                local allowed = withinDistance and NPC_IsSpawnAllowed(e, playerCoords, dist)

                if allowed then
                    SpawnPed(e)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, e in pairs(Peds) do if DoesEntityExist(e.spawnedPed) then DeleteEntity(e.spawnedPed) end end
        NPC_Grid = {}
        return
    end
    for name, e in pairs(Peds) do
        if e.resource == resourceName then
            DespawnPed(e)
            if e._chunkId then NPC_grid_remove(e._chunkId, name) end
            Peds[name] = nil
        end
    end
end)
