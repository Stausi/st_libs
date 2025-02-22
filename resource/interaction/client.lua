local interaction = {}
local table = require "modules/table/shared"

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

local createdTextUis = {
    players = {},
    entities = {},
    coords = {},
    models = {},
}

local cachedModels = {}
local validCfxPools = {
    ["CVehicle"] = true,
    ["CPed"] = true,
    ["CObject"] = true,
}

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
        assert(false, "Data is required")
        return false
    end

    if not data.id then
        assert(false, "Id is required")
        return false
    end

    if not data.text then
        assert(false, "Text is required")
        return false
    end

    if not data.displayDist then
        assert(false, "Display distance is required")
        return false
    end

    if not data.interactDist then
        assert(false, "Interact distance is required")
        return false
    end

    if not data.key then
        assert(false, "Key is required")
        return false
    end

    if not data.keyNum then
        assert(false, "Key number is required")
        return false
    end

    if textType == "player" then
        if not data.player then
            assert(false, "Player is required")
            return false
        end
    end

    if textType == "coords" then
        if not data.coords then
            assert(false, "Coords is required")
            return false
        end

        if type(data.coords) == "vector2" then
            assert(false, "Coords must be a vector3 or vector4")
            return false
        end

        if type(data.coords) == "vector4" then
            data.coords = vector3(data.coords.x, data.coords.y, data.coords.z)
        end
    end

    if textType == "entity" then
        if not data.entity then
            assert(false, "Entity is required")
            return false
        end

        if NetworkGetEntityIsNetworked(data.entity) then
            data.netId = NetworkGetNetworkIdFromEntity(data.entity)
        end

        local entityType = nil
        if IsEntityAVehicle(data.entity) then
            entityType = "vehicle"
        elseif IsEntityAPed(data.entity) then
            entityType = "ped"
        elseif IsEntityAnObject(data.entity) then
            entityType = "object"
        end

        if not entityType then
            assert(false, "Could not determine entity type")
            return false
        end

        data.entityType = entityType
    end

    if textType == "model" then
        if not data.model then
            assert(false, "Model is required")
            return false
        end

        if not IsModelValid(data.model) then
            assert(false, "Model is not valid")
            return false
        end

        local modelPool = "CObject"
        if IsModelAVehicle(data.model) then
            modelPool = "CVehicle"
        elseif IsModelAPed(data.model) then
            modelPool = "CPed"
        end

        if not validCfxPools[modelPool] then
            assert(false, "Model pool is not valid")
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

local create3DTextUIOnPlayer = function(id, options)
    createdTextUis.players[id] = createdTextUis.players[id] or {}

    for _, data in pairs(options) do
        local returnData = validate3DData(data, "player")
        if not returnData then return end

        createdTextUis.players[id][data.id] = returnData
    end
end
exports('create3DTextUIOnPlayer', create3DTextUIOnPlayer)

local update3DTextUIOnPlayer = function(id, optionId, data)
    if not createdTextUis.players[id] then
        assert(false, "Player Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.players[id][optionId] then
        assert(false, "Player Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    local returnData = validate3DData(data, "player")
    if not returnData then return end

    createdTextUis.players[id][optionId] = returnData
end
exports('update3DTextUIOnPlayer', update3DTextUIOnPlayer)

local remove3DTextUIFromPlayer = function(id)
    if not createdTextUis.players[id] then
        assert(false, "Player Interaction with id " .. id .. " does not exist")
        return
    end

    createdTextUis.players[id] = nil
end
exports('remove3DTextUIFromPlayer', remove3DTextUIFromPlayer)

local remove3DTextUIFromPlayerOption = function(id, optionId)
    if not createdTextUis.players[id] then
        assert(false, "Player Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.players[id][optionId] then
        assert(false, "Player Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    createdTextUis.players[id][optionId] = nil
end
exports('remove3DTextUIFromPlayerOption', remove3DTextUIFromPlayerOption)

local create3DTextUIOnCoords = function(id, options)
    createdTextUis.coords[id] = createdTextUis.coords[id] or {}

    for _, data in pairs(options) do
        local returnData = validate3DData(data, "coords")
        if not returnData then return end

        createdTextUis.coords[id][data.id] = returnData
    end
end
exports('create3DTextUIOnCoords', create3DTextUIOnCoords)

local update3DTextUIOnCoords = function(id, optionId, data)
    if not createdTextUis.coords[id] then
        assert(false, "Coords Interaction with id " .. id .. " does not exist")
        return
    end
    
    if not createdTextUis.coords[id][optionId] then
        assert(false, "Coords Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    local returnData = validate3DData(data, "coords")
    if not returnData then return end

    createdTextUis.coords[id][optionId] = returnData
end
exports('update3DTextUIOnCoords', update3DTextUIOnCoords)

local remove3DTextUIFromCoords = function(id)
    if not createdTextUis.coords[id] then
        assert(false, "Coords Interaction with id " .. id .. " does not exist")
        return
    end

    createdTextUis.coords[id] = nil
end
exports('remove3DTextUIFromCoords', remove3DTextUIFromCoords)

local remove3DTextUIFromCoordsOption = function(id, optionId)
    if not createdTextUis.coords[id] then
        assert(false, "Coords Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.coords[id][optionId] then
        assert(false, "Coords Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    createdTextUis.coords[id][optionId] = nil
end
exports('remove3DTextUIFromCoordsOption', remove3DTextUIFromCoordsOption)

local create3DTextUIOnEntity = function(id, options)
    createdTextUis.entities[id] = createdTextUis.entities[id] or {}

    for _, data in pairs(options) do
        local returnData = validate3DData(data, "entity")
        if not returnData then return end

        createdTextUis.entities[id][data.id] = returnData
    end
end
exports('create3DTextUIOnEntity', create3DTextUIOnEntity)

local update3DTextUIOnEntity = function(id, optionId, data)
    if not createdTextUis.entities[id] then
        assert(false, "Entity Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.entities[id][optionId] then
        assert(false, "Entity Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    local returnData = validate3DData(data, "entity")
    if not returnData then return end

    createdTextUis.entities[id][optionId] = returnData
end
exports('update3DTextUIOnEntity', update3DTextUIOnEntity)

local remove3DTextUIFromEntity = function(id)
    if not createdTextUis.entities[id] then
        assert(false, "Entity Interaction with id " .. id .. " does not exist")
        return
    end

    createdTextUis.entities[id] = nil
end
exports('remove3DTextUIFromEntity', remove3DTextUIFromEntity)

local remove3DTextUIFromEntityOption = function(id, optionId)
    if not createdTextUis.entities[id] then
        assert(false, "Entity Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.entities[id][optionId] then
        assert(false, "Entity Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    createdTextUis.entities[id][optionId] = nil
end
exports('remove3DTextUIFromEntityOption', remove3DTextUIFromEntityOption)

local create3DTextUIOnModel = function(id, options)
    createdTextUis.models[id] = createdTextUis.models[id] or {}

    for _, data in pairs(options) do
        local returnData = validate3DData(data, "model")
        if not returnData then return end

        createdTextUis.models[id][data.id] = returnData

        cachedModels[returnData.model] = cachedModels[returnData.model] or {}
        cachedModels[returnData.model].ids = cachedModels[returnData.model].ids or {}

        cachedModels[returnData.model].pool = data.modelPool
        cachedModels[returnData.model].entities = cachedModels[returnData.model].entities or {}

        cachedModels[returnData.model].ids[id] = true
        cachedModels[returnData.model].ids[data.id] = true
    end
end
exports('create3DTextUIOnModel', create3DTextUIOnModel)

local update3DTextUIOnModel = function(id, optionId, data)
    if not createdTextUis.models[id] then
        assert(false, "Model Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.models[id][optionId] then
        assert(false, "Model Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    local returnData = validate3DData(data, "model")
    if not returnData then return end

    createdTextUis.models[id][optionId] = returnData
end
exports('update3DTextUIOnModel', update3DTextUIOnModel)

local remove3DTextUIFromModel = function(id)
    if not createdTextUis.models[id] then
        assert(false, "Model Interaction with id " .. id .. " does not exist")
        return
    end

    for model, data in pairs(cachedModels) do
        for cacheId in pairs(data.ids) do
            if cacheId == id then
                cachedModels[model][id] = nil
            end
        end

        if not next(cachedModels[model].ids) then
            cachedModels[model] = nil
        end
    end

    createdTextUis.models[id] = nil
end
exports('remove3DTextUIFromModel', remove3DTextUIFromModel)

local remove3DTextUIFromModelOption = function(id, optionId)
    if not createdTextUis.models[id] then
        assert(false, "Model Interaction with id " .. id .. " does not exist")
        return
    end

    if not createdTextUis.models[id][optionId] then
        assert(false, "Model Interaction with id " .. id .. " and optionId " .. optionId .. " does not exist")
        return
    end

    for model, data in pairs(cachedModels) do
        for cacheId in pairs(data.ids) do
            if cacheId == optionId then
                cachedModels[model][optionId] = nil
            end
        end

        if not next(cachedModels[model].ids) then
            cachedModels[model] = nil
        end
    end

    createdTextUis.models[id][optionId] = nil
end
exports('remove3DTextUIFromModelOption', remove3DTextUIFromModelOption)

local function getValidEntities(coords)
    local entities = {}
    for id, options in pairs(createdTextUis.entities) do
        for optionId, data in pairs(options) do
            if data.netId then
                data.entity = NetworkGetEntityFromNetworkId(data.netId)
            end

            if DoesEntityExist(data.entity) then
                local newCoords = GetEntityCoords(data.entity)

                local distance = #(coords - newCoords)
                if distance < data.displayDist then
                    local isInteractable = false

                    if distance < data.interactDist then
                        if data.canInteract then
                            isInteractable = pcall(data.canInteract, data.entity)
                        else
                            isInteractable = true
                        end
                    end

                    local newData = {}
                    for k, v in pairs(data) do
                        newData[k] = v
                    end

                    newData.coords = newCoords
                    newData.isInteractable = isInteractable

                    local textUiId = string.format("%s_%s_entity_%d", id, optionId, data.entity)
                    entities[textUiId] = entities[textUiId] or {}

                    table.insert(entities[textUiId], newData)
                end
            else
                createdTextUis.entities[data.id] = nil
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
                local isInteractable = false

                if distance < data.interactDist then
                    if data.canInteract then
                        isInteractable = pcall(data.canInteract, data.coords)
                    else
                        isInteractable = true
                    end
                end

                local newData = {}
                for k, v in pairs(data) do
                    newData[k] = v
                end

                newData.isInteractable = isInteractable

                local textUiId = string.format("%s_%s_coords_%s", id, optionId, tostring(data.coords))
                validCoords[textUiId] = validCoords[textUiId] or {}

                table.insert(validCoords[textUiId], newData)
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
            if GetPlayerFromServerId(data.player) then
                local playerPed = GetPlayerPed(data.player)
                local newCoords = GetEntityCoords(playerPed)

                local distance = #(coords - newCoords)
                if distance < data.displayDist then
                    local isInteractable = false

                    if distance < data.interactDist then
                        if data.canInteract then
                            isInteractable = pcall(data.canInteract, data.playerPed)
                        else
                            isInteractable = true
                        end
                    end

                    local newData = {}
                    for k, v in pairs(data) do
                        newData[k] = v
                    end

                    newData.coords = newCoords
                    newData.isInteractable = isInteractable

                    local textUiId = string.format("%s_%s_player_%d", id, optionId, data.player)
                    players[textUiId] = players[textUiId] or {}

                    table.insert(players[textUiId], newData)
                end
            else
                createdTextUis.players[data.id] = nil
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
                            local isInteractable = false

                            if distance < data.interactDist then
                                if data.canInteract then
                                    isInteractable = pcall(data.canInteract, entity)
                                else
                                    isInteractable = true
                                end
                            end

                            local newData = {}
                            for k, v in pairs(data) do
                                newData[k] = v
                            end

                            newData.entity = newEntity
                            newData.coords = newCoords
                            newData.isInteractable = isInteractable

                            local textUiId = string.format("%s_%s_model_%d", id, optionId, entity)
                            entities[textUiId] = entities[textUiId] or {}

                            table.insert(entities[textUiId], newData)
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
        local factor = (string.len(data.text)) / 370
        local newWidth = 0.03 + factor

        if newWidth > width then
            width = newWidth
        end

        local factor2 = (string.len(data.key)) / 370
        local newKeyWidth = 0.01 + factor2

        if newKeyWidth > keyWidth then
            keyWidth = newKeyWidth
        end
    end

    return width, keyWidth
end

local function drawOption(coords, text, key, spriteDict, spriteName, spriteKey, row, width, keyWidth, showDot, showPOI)
    if not showPOI then
        SetScriptGfxAlignParams(0.0, row * 0.03 + 0.0, 0.0, 0.0)
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

        SetScriptGfxAlignParams(0.0, row * 0.03 - 0.015, 0.0, 0.0)
        DrawSprite(spriteDict, spriteKey, 0.0, 0.014, keyWidth, 0.025, 0.0, 255, 255, 255, 255)
        ResetScriptGfxAlign()

        SetScriptGfxAlignParams((showDot == true and 0.022 or 0.018) + (width / 2), row * 0.03 - 0.0125, 0.0, 0.0)
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

        SetScriptGfxAlignParams((showDot == true and 0.022 or 0.018) + (width / 2), row * 0.03 - 0.015, 0.0, 0.0)
        DrawSprite(spriteDict, spriteName, 0.0, 0.014, width, 0.025, 0.0, 255, 255, 255, 255)
        ResetScriptGfxAlign()

        if showDot then
            local newSpritename = currentSelected == row and Textures.circleSelected or Textures.circle
            SetScriptGfxAlignParams(0.014, row * 0.03 - 0.015, 0.0, 0.0)
            DrawSprite(spriteDict, newSpritename, 0.0, 0.014, 0.01, 0.02, 0.0, 255, 255, 255, 255)
            ResetScriptGfxAlign()
        end
    else
        SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
        SetDrawOrigin(coords.x, coords.y, coords.z)
        DrawSprite(spriteDict, spriteName, 0, 0, 0.0125, 0.02333333333333333, 0, 255, 255, 255, 255)
        ResetScriptGfxAlign()
    end

    ClearDrawOrigin()
end

local function Display3DTextUI(options)
    local hasInteractionBox = false
    local width, keyWidth = getOptionsWidth(options)

    local optionsSize = st.table.count(options)
    local firstOptionKey, firstOption = next(options)

    local onScreen, _x, _y = World3dToScreen2d(firstOption.coords.x, firstOption.coords.y, firstOption.coords.z)
    if not onScreen then return end

    if optionsSize == 1 then
        if firstOption.isInteractable then
            drawOption(firstOption.coords, firstOption.text, firstOption.key, 'interactions_txd', "bg", "interact", 1, width, keyWidth, false)
            hasInteractionBox = true

            if firstOption.onSelect then
                if IsControlJustReleased(0, firstOption.keyNum) then
                    pcall(firstOption.onSelect, firstOption)
                end
            end
        end
    else
        local rowCount = 0
        for key, option in pairs(options) do
            rowCount = rowCount + 1

            if option.isInteractable then
                drawOption(option.coords, option.text, option.key, 'interactions_txd', "bg", "interact", rowCount, width, keyWidth, true)
                hasInteractionBox = true
            end

            if option.onSelect and currentSelected == rowCount then
                if IsControlJustReleased(0, option.keyNum) then
                    pcall(option.onSelect, option)
                end
            end
        end
    end

    if hasInteractionBox then
        if currentSelected ~= 1 and (IsControlJustPressed(0, 172) or IsControlJustPressed(0, 15)) then
            currentSelected = currentSelected - 1
        elseif currentSelected ~= optionsSize and (IsControlJustPressed(0, 173) or IsControlJustPressed(0, 14)) then
            currentSelected = currentSelected + 1
        end
    end

    if not hasInteractionBox and firstOption then
        drawOption(firstOption.coords, false, false, 'interactions_txd', "pin", false, 0, false, false, false, true)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local letSleep = true
        local playerCoords = GetEntityCoords(PlayerPedId())

        if next(createdTextUis.players) then
            local validPlayers = getValidPlayers(playerCoords)
            if next(validPlayers) then
                letSleep = false

                if not hasLoadedInteraction then
                    hasLoadedInteraction = true
                    currentSelected = 1
                end

                for _, options in pairs(validPlayers) do
                    Display3DTextUI(options)
                end
            end
        end

        if next(createdTextUis.entities) then
            local validEntities = getValidEntities(playerCoords)
            if next(validEntities) then
                letSleep = false

                if not hasLoadedInteraction then
                    hasLoadedInteraction = true
                    currentSelected = 1
                end

                for _, options in pairs(validEntities) do
                    Display3DTextUI(options)
                end
            end
        end

        if next(createdTextUis.coords) then
            local validCoords = getValidCoords(playerCoords)
            if next(validCoords) then
                letSleep = false

                if not hasLoadedInteraction then
                    hasLoadedInteraction = true
                    currentSelected = 1
                end

                for _, options in pairs(validCoords) do
                    Display3DTextUI(options)
                end
            end
        end

        if next(createdTextUis.models) then
            local validModels = getValidModels(playerCoords)
            if next(validModels) then
                letSleep = false

                if not hasLoadedInteraction then
                    hasLoadedInteraction = true
                    currentSelected = 1
                end

                for _, options in pairs(validModels) do
                    Display3DTextUI(options)
                end
            end
        end

        if letSleep then
            Citizen.Wait(1000)
        end
    end
end)

st.ready(function()
    loadTxd()
end)

AddEventHandler('onResourceStop', function(resourceName)
    for id, options in pairs(createdTextUis.players) do
        for optionId, data in pairs(options) do
            if data.resource == resourceName then
                createdTextUis.players[id][optionId] = nil
                print("Removed player interaction with id " .. id .. " and optionId " .. optionId)
            end
        end

        if not next(options) then
            createdTextUis.players[id] = nil
            print("Removed player interaction with id " .. id)
        end
    end

    for id, options in pairs(createdTextUis.entities) do
        for optionId, data in pairs(options) do
            if data.resource == resourceName then
                createdTextUis.entities[id][optionId] = nil
                print("Removed entity interaction with id " .. id .. " and optionId " .. optionId)
            end
        end

        if not next(options) then
            createdTextUis.entities[id] = nil
            print("Removed entity interaction with id " .. id)
        end
    end

    for id, options in pairs(createdTextUis.coords) do
        for optionId, data in pairs(options) do
            if data.resource == resourceName then
                createdTextUis.coords[id][optionId] = nil
                print("Removed coords interaction with id " .. id .. " and optionId " .. optionId)
            end
        end

        if not next(options) then
            createdTextUis.coords[id] = nil
            print("Removed coords interaction with id " .. id)
        end
    end

    for id, options in pairs(createdTextUis.models) do
        for optionId, data in pairs(options) do
            if data.resource == resourceName then
                createdTextUis.models[id][optionId] = nil
                print("Removed model interaction with id " .. id .. " and optionId " .. optionId)
            end
        end

        if not next(options) then
            createdTextUis.models[id] = nil
            print("Removed model interaction with id " .. id)
        end
    end
end)
