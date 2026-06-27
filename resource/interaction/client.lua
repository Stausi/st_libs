local Textures = {
    pin = 'pin',
    interact = 'interact',
    interactRed = 'interactRed',
    bg = 'bg',
    bgRed = 'bgRed',
    circleSelected = 'circle_selected',
    circle = 'circle',
}

local key = "E"
local hasLoadedInteraction = false
local currentSelected = 1

local runningSelects = {}
local cancelledResources = {}

local createdTextUis = {
    players = {},
    entities = {},
    coords = {},
    models = {},
}

local cachedOptions = {}
local cachedModels = {}
local validCfxPools = {
    ["CVehicle"] = true,
    ["CPed"] = true,
    ["CObject"] = true,
}

local DEFAULT_UPDATE_INTERVAL = 250 -- ms
local currentUpdateInterval = DEFAULT_UPDATE_INTERVAL

local function computeNextInterval(options)
    local nextInterval = DEFAULT_UPDATE_INTERVAL

    for _, d in ipairs(options) do
        if d.isInInteractRange and d.isInteractable then
            local uiInterval = d.updateInterval
            if type(uiInterval) == "number" and uiInterval > 0 and uiInterval < nextInterval then
                nextInterval = uiInterval
            end
        end
    end

    return nextInterval
end

local function vecKey(v)
    return string.format("%.6f,%.6f,%.6f", v.x, v.y, v.z)
end

local function getOptionSignature(opt)
    return (opt.id or "nil") .. ":" .. tostring(opt.entity or vecKey(opt.coords or vector3(0,0,0)))
end

local function cancelSelectsByResource(resourceName)
    cancelledResources[resourceName] = true

    for sig, token in pairs(runningSelects) do
        if token.resource == resourceName then
            token.cancelled = true
            runningSelects[sig] = nil
        end
    end
end

local lastFire = {}

local function safeFire(opt)
    local now = GetGameTimer()
    local sig = getOptionSignature(opt)
    local last = lastFire[sig] or 0

    if now - last <= 500 then
        print(("^1[st-interaction] Ignoring fire of %s due to cooldown^7"):format(sig))
        return
    end

    lastFire[sig] = now

    local token = {
        cancelled = false,
        resource = opt.resource,
        sig = sig
    }

    runningSelects[sig] = token

    CreateThread(function()
        local ok, err = pcall(function()
            opt.onSelect(opt, token)
        end)

        if not ok then
            print(("^1[st-interaction] onSelect failed for %s: %s^7"):format(sig, tostring(err)))
        end

        if runningSelects[sig] == token then
            runningSelects[sig] = nil
        end
    end)
end

local function cacheEntityModels()
    if not next(cachedModels) then 
        return 
    end

    local modelPoolsMapping = {}
    for model, data in pairs(cachedModels) do
        if validCfxPools[data.pool] then
            modelPoolsMapping[data.pool] = modelPoolsMapping[data.pool] or {}
            modelPoolsMapping[data.pool][model] = true
        end
    end

    for pool, models in pairs(modelPoolsMapping) do
        local gamePool = GetGamePool(pool)
        for i = 1, #gamePool do
            local entity = gamePool[i]
            local model = GetEntityModel(entity)

            if cachedModels[model] and not cachedModels[model].entities[entity] then
                cachedModels[model].entities[entity] = true
            end
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10 * 1000)
        cacheEntityModels()
    end
end)

local loadTxd = function()
    local txd = CreateRuntimeTxd("interactions_txd")
    for _, v in pairs(Textures) do
        CreateRuntimeTextureFromImage(txd, tostring(v), "assets/" .. v .. ".png")
    end
end

local function displayTextUI(text, key, hide)
    local displayKey = key
    if key ~= nil then
        displayKey = key
    end

    SendNUIMessage({
        action = "textUI", 
        show = true, 
        key = key, 
        text = text, 
        hide = hide
    })
end

local function changeText(text, key)
    local displayKey = key
    if key ~= nil then
        displayKey = key
    end

    SendNUIMessage({
        action = "textUIUpdate", 
        key = key, 
        text = text
    })
end

local function hideTextUI()
    SendNUIMessage({
        action = "textUI", 
        show = false
    })
end

local function validate3DData(data, textType)
    if not data then
        st.print.error(false, "Data is required")
        return false
    end

    if not data.id then
        st.print.error(false, "Id is required")
        return false
    end

    if data.text ~= nil and type(data.text) ~= "string" then
        st.print.error(false, "Text must be a string if provided")
        return false
    end

    if not data.displayDist then
        st.print.error(false, "Display distance is required")
        return false
    end

    if not data.interactDist then
        st.print.error(false, "Interact distance is required")
        return false
    end

    if not data.key then
        st.print.error(false, "Key is required")
        return false
    end

    if not data.keyNum then
        st.print.error(false, "Key number is required")
        return false
    end

    if textType == "player" then
        if not data.player then
            st.print.error(false, "Player is required")
            return false
        end
    end

    if textType == "coords" then
        if not data.coords then
            st.print.error(false, "Coords is required")
            return false
        end

        if type(data.coords) == "vector2" then
            st.print.error(false, "Coords must be a vector3 or vector4")
            return false
        end

        if type(data.coords) == "vector4" then
            data.coords = vector3(data.coords.x, data.coords.y, data.coords.z)
        end
    end

    if textType == "entity" then
        if not data.entity then
            st.print.error(false, "Entity is required")
            return false
        end

        if NetworkGetEntityIsNetworked(data.entity) then
            data.netId = NetworkGetNetworkIdFromEntity(data.entity)
        end
    end

    if textType == "model" then
        if not data.model then
            st.print.error(false, "Model is required")
            return false
        end

        -- if not IsModelValid(data.model) then
        --     st.print.error(false, "Model is not valid")
        --     return false
        -- end

        local modelPool = "CObject"
        if IsModelAVehicle(data.model) then
            modelPool = "CVehicle"
        elseif IsModelAPed(data.model) then
            modelPool = "CPed"
        end

        if not validCfxPools[modelPool] then
            st.print.error(false, "Model pool is not valid")
            return false
        end

        data.model = GetHashKey(data.model)
        data.modelPool = modelPool
    end

    if not data.theme then
        data.theme = "green"
    end

    data.resource = GetInvokingResource()

    return data
end

st.create3DTextUIOnPlayer = function(id, options)
    createdTextUis.players[id] = createdTextUis.players[id] or {}

    for _, data in pairs(options) do
        local returnData = validate3DData(data, "player")
        if not returnData then return end

        createdTextUis.players[id][data.id] = returnData
    end
end

st.update3DTextUIOnPlayer = function(id, optionId, data)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not optionId then
        st.print.error(false, "OptionId is required")
        return
    end
    
    if not createdTextUis.players[id] then
        st.print.error(false, "Player Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.players[id][optionId] then
        st.print.error(false, "Player Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    local returnData = validate3DData(data, "player")
    if not returnData then return end

    createdTextUis.players[id][optionId] = returnData
end

st.remove3DTextUIFromPlayer = function(id)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not createdTextUis.players[id] then
        st.print.error(false, "Player Interaction with id " .. id .. " does not exist")
        return
    end

    createdTextUis.players[id] = nil
end

st.remove3DTextUIFromPlayerOption = function(id, optionId)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not optionId then
        st.print.error(false, "OptionId is required")
        return
    end

    if not createdTextUis.players[id] then
        st.print.error(false, "Player Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.players[id][optionId] then
        st.print.error(false, "Player Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    createdTextUis.players[id][optionId] = nil
end

st.create3DTextUIOnCoords = function(id, options)
    createdTextUis.coords[id] = createdTextUis.coords[id] or {}

    for _, data in pairs(options) do
        local returnData = validate3DData(data, "coords")
        if not returnData then return end

        createdTextUis.coords[id][data.id] = returnData
    end
end

st.update3DTextUIOnCoords = function(id, optionId, data)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not optionId then
        st.print.error(false, "OptionId is required")
        return
    end

    if not createdTextUis.coords[id] then
        st.print.error(false, "Coords Interaction with id " .. id .. " does not exist")
        return
    end
    
    if not createdTextUis.coords[id][optionId] then
        st.print.error(false, "Coords Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    local returnData = validate3DData(data, "coords")
    if not returnData then return end

    createdTextUis.coords[id][optionId] = returnData
end

st.remove3DTextUIFromCoords = function(id)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not createdTextUis.coords[id] then
        st.print.error(false, "Coords Interaction with id " .. id .. " does not exist")
        return
    end

    createdTextUis.coords[id] = nil
end

st.remove3DTextUIFromCoordsOption = function(id, optionId)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not optionId then
        st.print.error(false, "OptionId is required")
        return
    end

    if not createdTextUis.coords[id] then
        st.print.error(false, "Coords Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.coords[id][optionId] then
        st.print.error(false, "Coords Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    createdTextUis.coords[id][optionId] = nil
end

st.create3DTextUIOnEntity = function(id, options)
    createdTextUis.entities[id] = createdTextUis.entities[id] or {}

    local syncedNetIds = {}
    for _, data in pairs(options) do
        local returnData = validate3DData(data, "entity")
        if not returnData then return end

        createdTextUis.entities[id][data.id] = returnData

        if returnData.netId then
            syncedNetIds[returnData.netId] = true
        end
    end

    if next(syncedNetIds) == nil then
        return
    end

    TriggerServerEvent("st-interaction:server:syncEntities", syncedNetIds)
end

st.update3DTextUIOnEntity = function(id, optionId, data)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not optionId then
        st.print.error(false, "OptionId is required")
        return
    end

    if not createdTextUis.entities[id] then
        st.print.error(false, "Entity Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.entities[id][optionId] then
        st.print.error(false, "Entity Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    local returnData = validate3DData(data, "entity")
    if not returnData then return end

    createdTextUis.entities[id][optionId] = returnData
end

st.remove3DTextUIFromEntity = function(id)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not createdTextUis.entities[id] then
        st.print.error(false, "Entity Interaction with id " .. id .. " does not exist")
        return
    end

    createdTextUis.entities[id] = nil
end

st.remove3DTextUIFromEntityOption = function(id, optionId)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not optionId then
        st.print.error(false, "OptionId is required")
        return
    end

    if not createdTextUis.entities[id] then
        st.print.error(false, "Entity Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.entities[id][optionId] then
        st.print.error(false, "Entity Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    createdTextUis.entities[id][optionId] = nil
end

st.create3DTextUIOnModel = function(id, options)
    createdTextUis.models[id] = createdTextUis.models[id] or {}

    for _, data in pairs(options) do
        local returnData = validate3DData(data, "model")
        if not returnData then return end

        createdTextUis.models[id][data.id] = returnData

        cachedModels[returnData.model] = cachedModels[returnData.model] or {}
        cachedModels[returnData.model].ids = cachedModels[returnData.model].ids or {}

        cachedModels[returnData.model].pool = returnData.modelPool
        cachedModels[returnData.model].entities = cachedModels[returnData.model].entities or {}

        cachedModels[returnData.model].ids[id] = true
        cachedModels[returnData.model].ids[data.id] = true
    end
end

st.update3DTextUIOnModel = function(id, optionId, data)
    if not id then
        st.print.error(false, "Id is required")
        return
    end

    if not optionId then
        st.print.error(false, "OptionId is required")
        return
    end

    if not createdTextUis.models[id] then
        st.print.error(false, "Model Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.models[id][optionId] then
        st.print.error(false, "Model Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    local returnData = validate3DData(data, "model")
    if not returnData then return end

    createdTextUis.models[id][optionId] = returnData
end

st.remove3DTextUIFromModel = function(id)
    if not id then
        st.print.error(false, "Id is required")
        return
    end
    if not createdTextUis.models[id] then
        st.print.error(false, "Model Interaction with id " .. id .. " does not exist")
        return
    end

    for model, data in pairs(cachedModels) do
        for cacheId in pairs(data.ids) do
            if cacheId == id then
                cachedModels[model].ids[id] = nil
            end
        end

        if not next(cachedModels[model].ids) then
            cachedModels[model] = nil
        end
    end

    createdTextUis.models[id] = nil
end

st.remove3DTextUIFromModelOption = function(id, optionId)
    if not id then
        st.print.error(false, "Id is required")
        return
    end
    if not optionId then
        st.print.error(false, "OptionId is required")
        return
    end
    if not createdTextUis.models[id] then
        st.print.error(false, "Model Interaction with id " .. id .. " does not exist")
        return
    end
    if not createdTextUis.models[id][optionId] then
        st.print.error(false, "Model Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    for model, data in pairs(cachedModels) do
        for cacheId in pairs(data.ids) do
            if cacheId == optionId then
                cachedModels[model].ids[optionId] = nil
            end
        end

        if not next(cachedModels[model].ids) then
            cachedModels[model] = nil
        end
    end

    createdTextUis.models[id][optionId] = nil
end

local function getScreenDistanceSquared(coords)
    local success, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not success then return math.huge end

    local dx = screenX - 0.5
    local dy = screenY - 0.5
    return dx * dx + dy * dy
end

local function getValidEntities(coords)
    local entities = {}
    for id, options in pairs(createdTextUis.entities) do
        for optionId, data in pairs(options) do
            if data.netId and NetworkDoesNetworkIdExist(data.netId) then
                local entity = NetworkGetEntityFromNetworkId(data.netId)
                if entity and DoesEntityExist(entity) then
                    data.entity = entity
                end
            end

            if DoesEntityExist(data.entity) then
                local newCoords = GetEntityCoords(data.entity)
                local boneActive = false

                if data.bone then
                    local boneId = GetEntityBoneIndexByName(data.entity, data.bone)
                    if boneId ~= -1 then
                        newCoords = GetEntityBonePosition_2(data.entity, boneId)
                        boneActive = true
                    end
                elseif data.entityOffset then
                    newCoords = GetOffsetFromEntityInWorldCoords(data.entity, data.entityOffset.x, data.entityOffset.y, data.entityOffset.z)
                end

                local distance = #(coords - newCoords)
                if distance < data.displayDist then
                    local currentScreenDist = getScreenDistanceSquared(newCoords)
                    if currentScreenDist < math.huge then
                        local newData = {}
                        for k, v in pairs(data) do
                            newData[k] = v
                        end

                        newData._boneActive = boneActive
                        newData.isInInteractRange = distance < data.interactDist
                        newData.isInteractable = true

                        if data.canInteract ~= nil then
                            local canInteractData = {
                                coords = newCoords,
                                entity = data.entity
                            }

                            local success, resp = pcall(data.canInteract, canInteractData)
                            newData.isInteractable = success and resp
                        end

                        newData.coords = newCoords

                        if newData.isInteractable then
                            local textUiId = string.format("%s_%s_entity_%d", id, optionId, data.entity)
                            entities[textUiId] = entities[textUiId] or {}

                            table.insert(entities[textUiId], newData)
                        end

                        newData._onlyShowPin = false

                        if data.onlyShowPin ~= nil then
                            local ctx = { coords = newCoords, entity = data.entity }
                            local ok, resp = pcall(data.onlyShowPin, ctx)
                            newData._onlyShowPin = ok and resp == true
                        end

                        newData._useRed = false

                        if data.useRed ~= nil then
                            local ctx = { coords = newCoords, entity = data.entity }

                            if type(data.useRed) == "boolean" then
                                newData._useRed = data.useRed
                            else
                                local ok, resp = pcall(data.useRed, ctx)
                                newData._useRed = ok and resp == true
                            end
                        end
                    end
                end
            else
                if data.netId then
                    data.entity = nil
                else
                    createdTextUis.entities[id][optionId] = nil
                end
            end
        end

        if not next(options) then
            createdTextUis.entities[id] = nil
        end
    end

    return entities
end

local function getValidCoords(coords)
    local validCoords = {}
    for id, options in pairs(createdTextUis.coords) do
        for optionId, data in pairs(options) do
            local distance = #(coords - data.coords)
            if distance < data.displayDist then
                local currentScreenDist = getScreenDistanceSquared(data.coords)
                if currentScreenDist < math.huge then
                    local newData = {}
                    for k, v in pairs(data) do
                        newData[k] = v
                    end

                    newData.isInInteractRange = distance < data.interactDist
                    newData.isInteractable = true

                    if data.canInteract ~= nil then
                        local canInteractData = {
                            coords = data.coords
                        }

                        local success, resp = pcall(data.canInteract, canInteractData)
                        newData.isInteractable = success and resp
                    end

                    if newData.isInteractable then
                        local textUiId = string.format("%s_%s_coords_%s", id, optionId, tostring(data.coords))
                        validCoords[textUiId] = validCoords[textUiId] or {}

                        table.insert(validCoords[textUiId], newData)
                    end

                    newData._onlyShowPin = false

                    if data.onlyShowPin ~= nil then
                        local ctx = { coords = data.coords }
                        local ok, resp = pcall(data.onlyShowPin, ctx)
                        newData._onlyShowPin = ok and resp == true
                    end

                    newData._useRed = false

                    if data.useRed ~= nil then
                        local ctx = { coords = data.coords }

                        if type(data.useRed) == "boolean" then
                            newData._useRed = data.useRed
                        else
                            local ok, resp = pcall(data.useRed, ctx)
                            newData._useRed = ok and resp == true
                        end
                    end
                end
            end
        end

        if not next(options) then
            createdTextUis.coords[id] = nil
        end
    end

    return validCoords
end

local function getValidPlayers(coords)
    local players = {}
    for id, options in pairs(createdTextUis.players) do
        for optionId, data in pairs(options) do
            local clientId = GetPlayerFromServerId(data.player)
            if clientId ~= -1 then
                local playerPed = GetPlayerPed(clientId)
                local newCoords = GetEntityCoords(playerPed)
                local boneActive = false

                if data.bone then
                    local boneId = GetEntityBoneIndexByName(playerPed, data.bone)
                    if boneId ~= -1 then
                        newCoords = GetEntityBonePosition_2(playerPed, boneId)
                        boneActive = true
                    end
                elseif data.entityOffset then
                    newCoords = GetOffsetFromEntityInWorldCoords(playerPed, data.entityOffset.x, data.entityOffset.y, data.entityOffset.z)
                end

                local distance = #(coords - newCoords)
                if distance < data.displayDist then
                    local currentScreenDist = getScreenDistanceSquared(newCoords)
                    if currentScreenDist < math.huge then
                        local newData = {}
                        for k, v in pairs(data) do
                            newData[k] = v
                        end

                        newData._boneActive = boneActive
                        newData.isInInteractRange = distance < data.interactDist
                        newData.isInteractable = true
        
                        if data.canInteract ~= nil then
                            local canInteractData = {
                                coords = newCoords,
                                player = data.player
                            }

                            local success, resp = pcall(data.canInteract, canInteractData)
                            newData.isInteractable = success and resp
                        end

                        newData.coords = newCoords

                        if newData.isInteractable then
                            local textUiId = string.format("%s_%s_player_%d", id, optionId, data.player)
                            players[textUiId] = players[textUiId] or {}

                            table.insert(players[textUiId], newData)
                        end

                        newData._onlyShowPin = false

                        if data.onlyShowPin ~= nil then
                            local ctx = { coords = newCoords, player = data.player }
                            local ok, resp = pcall(data.onlyShowPin, ctx)
                            newData._onlyShowPin = ok and resp == true
                        end

                        newData._useRed = false

                        if data.useRed ~= nil then
                            local ctx = { coords = newCoords, player = data.player }

                            if type(data.useRed) == "boolean" then
                                newData._useRed = data.useRed
                            else
                                local ok, resp = pcall(data.useRed, ctx)
                                newData._useRed = ok and resp == true
                            end
                        end
                    end
                end
            else
                createdTextUis.players[id] = nil
            end
        end

        if not next(options) then
            createdTextUis.players[id] = nil
        end
    end

    return players
end

local function getValidModels(coords)
    local entities = {}
    for id, options in pairs(createdTextUis.models) do
        for optionId, data in pairs(options) do
            if cachedModels[data.model] and next(cachedModels[data.model].entities) then
                for entity in pairs(cachedModels[data.model].entities) do
                    if DoesEntityExist(entity) then
                        local newCoords = GetEntityCoords(entity)
                        local newEntity = entity

                        local distance = #(coords - newCoords)
                        if distance < data.displayDist then
                            local currentScreenDist = getScreenDistanceSquared(newCoords)
                            if currentScreenDist < math.huge then
                                local newData = {}
                                for k, v in pairs(data) do
                                    newData[k] = v
                                end

                                newData.entity = newEntity
                                newData.coords = newCoords

                                if NetworkGetEntityIsNetworked(newEntity) then
                                    newData.netId = NetworkGetNetworkIdFromEntity(newEntity)
                                end

                                local boneActive = false
                                if data.bone then
                                    local boneId = GetEntityBoneIndexByName(newEntity, data.bone)
                                    if boneId ~= -1 then
                                        newData.coords = GetEntityBonePosition_2(newEntity, boneId)
                                        boneActive = true
                                    end
                                elseif data.entityOffset then
                                    newData.coords = GetOffsetFromEntityInWorldCoords(newEntity, data.entityOffset.x, data.entityOffset.y, data.entityOffset.z)
                                end

                                newData._boneActive = boneActive
                                newData.isInInteractRange = distance < data.interactDist
                                newData.isInteractable = true
                                
                                if data.canInteract ~= nil then
                                    local canInteractData = {
                                        coords = newData.coords,
                                        entity = newEntity
                                    }

                                    local success, resp = pcall(data.canInteract, canInteractData)
                                    newData.isInteractable = success and resp
                                end

                                if newData.isInteractable then
                                    local textUiId = string.format("%s_%s_model_%d", id, optionId, entity)
                                    entities[textUiId] = entities[textUiId] or {}

                                    table.insert(entities[textUiId], newData)
                                end

                                newData._onlyShowPin = false

                                if data.onlyShowPin ~= nil then
                                    local ctx = { coords = newData.coords, entity = newEntity }
                                    local ok, resp = pcall(data.onlyShowPin, ctx)
                                    newData._onlyShowPin = ok and resp == true
                                end

                                newData._useRed = false

                                if data.useRed ~= nil then
                                    local ctx = { coords = newData.coords, entity = newEntity }

                                    if type(data.useRed) == "boolean" then
                                        newData._useRed = data.useRed
                                    else
                                        local ok, resp = pcall(data.useRed, ctx)
                                        newData._useRed = ok and resp == true
                                    end
                                end
                            end
                        end
                    else
                        cachedModels[data.model].entities[entity] = nil
                    end
                end
            end
        end

        if not next(options) then
            createdTextUis.models[id] = nil
        end
    end

    return entities
end

local function getOptionsWidth(options)
    local width, keyWidth = 0.0, 0.0
    for _, data in pairs(options) do
        local text = data.text or ""
        local keyStr = data.key or ""

        if text ~= "" then
            local factor = (#text) / 370
            local newWidth = 0.03 + factor
            if newWidth > width then
                width = newWidth
            end
        end

        if keyStr ~= "" then
            local factor2 = (#keyStr) / 370
            local newKeyWidth = 0.01 + factor2
            if newKeyWidth > keyWidth then
                keyWidth = newKeyWidth
            end
        end
    end

    return width, keyWidth
end

local function drawOption(coords, text, key, spriteDict, spriteName, spriteKey, row, width, keyWidth, showDot, showPOI)
    local isKeyOnly = (text == nil or text == "")
    if not showPOI then
        local rowNumber = (row or 1) - 1

        if isKeyOnly then
            SetScriptGfxAlignParams(0.0, rowNumber * 0.03 + 0.0, 0.0, 0.0)
            SetDrawOrigin(coords.x, coords.y, coords.z)
            DrawSprite(
                spriteDict,
                spriteKey or "interact",
                0.0, 0.0,
                (keyWidth > 0 and keyWidth or 0.02),
                0.03,
                0.0,
                255, 255, 255, 255
            )

            SetTextScale(0, 0.3)
            SetTextFont(2)
            SetTextColour(255, 255, 255, 255)
            BeginTextCommandDisplayText("STRING")
            SetTextCentre(true)
            SetTextJustification(0)
            AddTextComponentSubstringPlayerName(key or "")
            EndTextCommandDisplayText(0.0, -0.0115)

            ResetScriptGfxAlign()
        else
            local rowNumber = row - 1
            SetScriptGfxAlignParams(0.0, rowNumber * 0.03 + 0.0, 0.0, 0.0)
            SetTextScale(0, 0.3)
            SetTextFont(2)
            SetTextColour(255, 255, 255, 255)
            BeginTextCommandDisplayText("STRING")
            SetTextCentre(true)
            SetTextJustification(0)
            AddTextComponentSubstringPlayerName(key)
            SetDrawOrigin(coords.x, coords.y, coords.z)
            EndTextCommandDisplayText(0.0, -0.0115)
            ResetScriptGfxAlign()

            SetScriptGfxAlignParams(0.0, rowNumber * 0.03 - 0.015, 0.0, 0.0)
            DrawSprite(spriteDict, spriteKey, 0.0, 0.014, keyWidth, 0.025, 0.0, 255, 255, 255, 255)
            ResetScriptGfxAlign()

            SetScriptGfxAlignParams((showDot == true and 0.022 or 0.018) + (width / 2), rowNumber * 0.03 - 0.0125, 0.0, 0.0)
            SetTextScale(0, 0.3)
            SetTextFont(4)
            SetTextColour(255, 255, 255, 255)
            BeginTextCommandDisplayText("STRING")
            SetTextCentre(true)
            AddTextComponentSubstringPlayerName(text)
            SetDrawOrigin(coords.x, coords.y, coords.z, 0)
            SetTextJustification(0)
            EndTextCommandDisplayText(0.0, 0.0)
            ResetScriptGfxAlign()

            SetScriptGfxAlignParams((showDot == true and 0.022 or 0.018) + (width / 2), rowNumber * 0.03 - 0.015, 0.0, 0.0)
            DrawSprite(spriteDict, spriteName, 0.0, 0.014, width, 0.025, 0.0, 255, 255, 255, 255)
            ResetScriptGfxAlign()

            if showDot then
                local newSpritename = currentSelected == row and Textures.circleSelected or Textures.circle
                SetScriptGfxAlignParams(0.014, rowNumber * 0.03 - 0.015, 0.0, 0.0)
                DrawSprite(spriteDict, newSpritename, 0.0, 0.014, 0.01, 0.02, 0.0, 255, 255, 255, 255)
                ResetScriptGfxAlign()
            end
        end
    else
        SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
        SetDrawOrigin(coords.x, coords.y, coords.z)
        DrawSprite(spriteDict, spriteName, 0, 0, 0.0125, 0.02333333333333333, 0, 255, 255, 255, 255)
        ResetScriptGfxAlign()
    end

    ClearDrawOrigin()
end

local function hasCameraLineOfSightToPin(opt)
    if opt.ignorePinLineOfSight == true then
        return true
    end

    local targetCoords = opt.coords
    if not targetCoords then
        return false
    end

    local camCoords = GetFinalRenderedCamCoord()
    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        targetCoords.x, targetCoords.y, targetCoords.z,
        1 | 2 | 4 | 8 | 16,
        cache.ped,
        7
    )

    local _, hit, endCoords, _, entityHit = GetShapeTestResult(ray)
    if hit == 0 then
        return true
    end

    if opt.entity and entityHit and entityHit == opt.entity then
        return true
    end

    if endCoords and #(vector3(endCoords.x, endCoords.y, endCoords.z) - targetCoords) <= 0.2 then
        return true
    end

    return false
end

local function shouldDrawPin(opt)
    if opt.allowFallbackPin == false then
        return false
    end

    if type(opt.canShowFallbackPin) == "function" then
        local ok, resp = pcall(opt.canShowFallbackPin, opt)
        if not ok or resp ~= true then
            return false
        end
    end

    return hasCameraLineOfSightToPin(opt)
end

local function Display3DTextUI(options)
    local hasInteractionBox = false
    local width, keyWidth = getOptionsWidth(options)

    local pinOnly, boxOpts = {}, {}
    for _, opt in ipairs(options) do
        if opt._onlyShowPin then
            table.insert(pinOnly, opt)
        else
            table.insert(boxOpts, opt)
        end
    end

    for _, opt in ipairs(pinOnly) do
        if shouldDrawPin(opt) then
            drawOption(opt.coords, false, false, 'interactions_txd', "pin", false, 0, false, false, false, true)
        end
    end

    if #boxOpts == 0 then
        return
    end

    local visible, firstVisible = {}, nil
    for _, opt in ipairs(boxOpts) do
        if opt.isInInteractRange then
            table.insert(visible, opt)
            if not firstVisible then firstVisible = opt end
        end
    end

    if #visible == 1 then
        local opt = firstVisible
        local bgSprite = opt._useRed and "bgRed" or "bg"
        local keySprite = opt._useRed and "interactRed" or "interact"
        
        drawOption(opt.coords, opt.text, opt.key, 'interactions_txd', bgSprite, keySprite, 1, width, keyWidth, false)
        hasInteractionBox = true

        if opt.onSelect and IsControlJustReleased(0, opt.keyNum) then
            safeFire(opt)
        end
    elseif #visible > 1 then
        if not currentSelected or currentSelected < 1 then currentSelected = 1 end
        if currentSelected > #visible then currentSelected = #visible end

        for row, opt in ipairs(visible) do
            local bgSprite = opt._useRed and "bgRed" or "bg"
            local keySprite = opt._useRed and "interactRed" or "interact"
            drawOption(opt.coords, opt.text, opt.key, 'interactions_txd', bgSprite, keySprite, row, width, keyWidth, true)
            hasInteractionBox = true
            
            if opt.onSelect and currentSelected == row and IsControlJustReleased(0, opt.keyNum) then
                safeFire(opt)
            end
        end

        if hasInteractionBox then
            if IsControlJustPressed(0, 172) or IsControlJustPressed(0, 15) then
                currentSelected = math.max(1, currentSelected - 1)
            elseif IsControlJustPressed(0, 173) or IsControlJustPressed(0, 14) then
                currentSelected = math.min(#visible, currentSelected + 1)
            end
        end
    end

    if not hasInteractionBox then
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearest, bestDist = nil, math.huge
        for _, opt in ipairs(boxOpts) do
            if not shouldDrawPin(opt) then
                goto skip_fallback_pin
            end

            local d = #(playerCoords - opt.coords)
            if d < bestDist then
                bestDist = d
                nearest = opt
            end

            ::skip_fallback_pin::
        end
        if nearest then
            drawOption(nearest.coords, false, false, 'interactions_txd', "pin", false, 0, false, false, false, true)
        end
    end
end

local function groupNearbyOptions(allOptions, boneRadius)
    boneRadius = boneRadius or 1.0

    local groupsByKey = {}
    local boneGroups = {}

    for _, opt in ipairs(allOptions) do
        local isBone = (opt.bone ~= nil)
        local boneActive = (opt._boneActive == true)

        if isBone and boneActive then
            local added = false
            for _, grp in ipairs(boneGroups) do
                local center = grp[1].coords
                if #(opt.coords - center) <= boneRadius then
                    table.insert(grp, opt)
                    added = true
                    break
                end
            end
            if not added then
                table.insert(boneGroups, { opt })
            end
        else
            local key
            if opt.player then
                key = ("player:%s"):format(opt.player)
            elseif opt.netId or opt.entity then
                local stable
                if opt.netId and opt.netId ~= 0 then
                    stable = ("net:%d"):format(opt.netId)
                else
                    stable = ("ent:%d"):format(opt.entity or 0)
                end
                key = ("entity:%s"):format(stable)
            elseif opt.coords then
                key = ("coords:%s"):format(vecKey(opt.coords))
            else
                key = ("misc:%s"):format(tostring(opt.id or "unknown"))
            end

            groupsByKey[key] = groupsByKey[key] or {}
            table.insert(groupsByKey[key], opt)
        end
    end

    local out = {}
    for _, g in pairs(groupsByKey) do 
        table.insert(out, g) 
    end

    for _, g in ipairs(boneGroups) do 
        table.insert(out, g) 
    end

    return out
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(currentUpdateInterval)

        local allOptions = {}
        local playerCoords = GetEntityCoords(cache.ped)
        if next(createdTextUis.players) then
            local validPlayers = getValidPlayers(playerCoords)
            if next(validPlayers) then
                for _, options in pairs(validPlayers) do
                    for _, data in pairs(options) do
                        table.insert(allOptions, data)
                    end
                end
            end
        end

        if next(createdTextUis.entities) then
            local validEntities = getValidEntities(playerCoords)
            if next(validEntities) then
                for _, options in pairs(validEntities) do
                    for _, data in pairs(options) do
                        table.insert(allOptions, data)
                    end
                end
            end
        end

        if next(createdTextUis.coords) then
            local validCoords = getValidCoords(playerCoords)
            if next(validCoords) then
                for _, options in pairs(validCoords) do
                    for _, data in pairs(options) do
                        table.insert(allOptions, data)
                    end
                end
            end
        end

        if next(createdTextUis.models) then
            local validModels = getValidModels(playerCoords)
            if next(validModels) then
                for _, options in pairs(validModels) do
                    for _, data in pairs(options) do
                        table.insert(allOptions, data)
                    end
                end
            end
        end

        local seen = {}
        local deduped = {}
        for _, d in ipairs(allOptions) do
            local sig = (d.id or "nil") .. ":" .. tostring(d.entity or vecKey(d.coords or vector3(0,0,0)))
            if not seen[sig] then
                seen[sig] = true
                table.insert(deduped, d)
            end
        end

        cachedOptions = deduped
        currentUpdateInterval = computeNextInterval(deduped)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local letSleep = true
        if next(cachedOptions) then
            if not hasLoadedInteraction then
                hasLoadedInteraction = true
                currentSelected = 1
            end

            local groups = groupNearbyOptions(cachedOptions, 1.0)
            for _, group in ipairs(groups) do
                Display3DTextUI(group)
            end

            letSleep = false
        elseif hasLoadedInteraction then
            hasLoadedInteraction = false
        end

        if letSleep then
            Citizen.Wait(1000)
        end
    end
end)

RegisterNetEvent("st-interaction:client:entityRemoved", function(netId)
    if not createdTextUis.entities then return end
    for id, options in pairs(createdTextUis.entities) do
        for optionId, data in pairs(options) do
            if data.netId and data.netId == netId then
                createdTextUis.entities[id][optionId] = nil
            end
        end

        if not next(options) then
            createdTextUis.entities[id] = nil
        end
    end
end)

st.ready(function()
    loadTxd()
end)

AddEventHandler('onResourceStop', function(resourceName)
    cancelSelectsByResource(resourceName)

    for id, options in pairs(createdTextUis.players) do
        for optionId, data in pairs(options) do
            if data.resource == resourceName then
                createdTextUis.players[id][optionId] = nil
            end
        end

        if not next(options) then
            createdTextUis.players[id] = nil
        end
    end

    for id, options in pairs(createdTextUis.entities) do
        for optionId, data in pairs(options) do
            if data.resource == resourceName then
                createdTextUis.entities[id][optionId] = nil
            end
        end

        if not next(options) then
            createdTextUis.entities[id] = nil
        end
    end

    for id, options in pairs(createdTextUis.coords) do
        for optionId, data in pairs(options) do
            if data.resource == resourceName then
                createdTextUis.coords[id][optionId] = nil
            end
        end

        if not next(options) then
            createdTextUis.coords[id] = nil
        end
    end

    for id, options in pairs(createdTextUis.models) do
        for optionId, data in pairs(options) do
            if data.resource == resourceName then
                createdTextUis.models[id][optionId] = nil
            end
        end

        if not next(options) then
            createdTextUis.models[id] = nil
        end
    end
end)
