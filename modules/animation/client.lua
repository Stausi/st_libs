local PlayerProps = {}
local PlayerHasProp = false
local IsInAnimation = false

local RequestWalking = function(set)
    RequestAnimSet(set)
    while not HasAnimSetLoaded(set) do
      Citizen.Wait(1)
    end 
end

local LoadAnim = function(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

local LoadPropDict = function(model)
    while not HasModelLoaded(GetHashKey(model)) do
      RequestModel(GetHashKey(model))
      Wait(10)
    end
end

local OnWalkPlay = function(data)
    local playerPed = PlayerPedId()
    RequestWalking(data.name)
    SetPedMovementClipset(playerPed, data.name, 0.2)
    RemoveAnimSet(data.name)
end

local OnExpressionPlay = function(data)
    local playerPed = PlayerPedId()
    SetFacialIdleAnimOverride(playerPed, data.name, data.dict)
end

local getGender = function()
    local hashSkinMale = GetHashKey("mp_m_freemode_01")
    local hashSkinFemale = GetHashKey("mp_f_freemode_01")
    
    local gender = ""
    if GetEntityModel(PlayerPedId()) == hashSkinMale then
        gender = "male"
    elseif GetEntityModel(PlayerPedId()) == hashSkinFemale then
        gender = "female"
    end

    return gender
end

local AddPropToPlayer = function(prop1, bone, off1, off2, off3, rot1, rot2, rot3)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
  
    if not HasModelLoaded(prop1) then
        LoadPropDict(prop1)
    end
  
    local prop = CreateObject(GetHashKey(prop1), playerCoords.x, playerCoords.y, playerCoords.z + 0.2, true, true, true)
    AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, bone), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
    table.insert(PlayerProps, prop)

    PlayerHasProp = true
    SetModelAsNoLongerNeeded(prop1)
end

local DestroyAllProps = function()
    for _,v in pairs(PlayerProps) do
        DeleteEntity(v)
    end
    PlayerHasProp = false
end

local OnEmotePlay = function(data, ignoreNui)
    local ped = PlayerPedId()
  
    if not DoesEntityExist(ped) then
        return false
    end

    if IsNuiFocused() and not ignoreNui then
        return
    end

    local duration = -1
    local movementType = 0
    local attachWait = 0
  
    if PlayerHasProp then
        DestroyAllProps()
    end
  
    if data.dict == "MaleScenario" or data.dict == "Scenario" then 
        if data.dict == "MaleScenario" and getGender() == "male" then
            ClearPedTasks(ped)
            TaskStartScenarioInPlace(ped, data.anim, 0, true)
        elseif data.dict == "ScenarioObject" then
            local behindPlayer = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0 - 0.5, -0.5);
            ClearPedTasks(ped)
            TaskStartScenarioAtPosition(ped, data.anim, behindPlayer['x'], behindPlayer['y'], behindPlayer['z'], GetEntityHeading(ped), 0, 1, false)
        elseif data.dict == "Scenario" then
            ClearPedTasks(ped)
            TaskStartScenarioInPlace(ped, data.anim, 0, true)
        end

        IsInAnimation = true
        return
    end
  
    LoadAnim(data.dict)
  
    if data.options then
        if data.options.loop then
            movementType = 1

            if data.options.moving then
                movementType = 51
            end
        elseif data.options.moving then
            movementType = 51
        elseif data.options.moving == false then
            movementType = 0
        elseif data.options.stuck then
            movementType = 50
        end
    else
        movementType = 0
    end
  
    if data.options then
        if data.options.duration == nil then 
            data.options.duration = -1
            attachWait = 0
        else
            duration = data.options.duration
            attachWait = data.options.duration
        end
    end
  
    TaskPlayAnim(ped, data.dict, data.anim, 2.0, 2.0, duration, movementType, 0, false, false, false)
    RemoveAnimDict(data.dict)

    IsInAnimation = true
  
    if data.options then
        if data.options.prop then
            local PropName = data.options.prop
            local PropBone = data.options.bone
            local PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6 = table.unpack(data.options.placement)

            local secondPropEmote = false
            if data.options.secondProp then
                local SecondPropName = data.options.secondProp
                local SecondPropBone = data.options.secondBone
                local SecondPropPl1, SecondPropPl2, SecondPropPl3, SecondPropPl4, SecondPropPl5, SecondPropPl6 = table.unpack(data.options.secondPlacement)
                secondPropEmote = true
            end

            Wait(attachWait)
            AddPropToPlayer(PropName, PropBone, PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6)

            if SecondPropEmote then
                AddPropToPlayer(SecondPropName, SecondPropBone, SecondPropPl1, SecondPropPl2, SecondPropPl3, SecondPropPl4, SecondPropPl5, SecondPropPl6)
            end

            Citizen.CreateThread(function()
                local ped = PlayerPedId()
                local animDict = data.dict
                local animName = data.anim
        
                while IsInAnimation do
                    Citizen.Wait(1000)
        
                    if not IsEntityPlayingAnim(ped, animDict, animName, 3) then
                        DestroyAllProps()
                        IsInAnimation = false
                    end
                end
            end)
        end
    end

    return true
end

st.emoteHandler = function(type, data, ignoreNui)
    if Type == "walks" then
        OnWalkPlay(data)
    elseif Type == "expressions" then
        OnExpressionPlay(data)
    else
        OnEmotePlay(data, ignoreNui)
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if PlayerHasProp then
            DestroyAllProps()
        end

        if IsInAnimation then
            local ped = PlayerPedId()
            ClearPedTasks(ped)
            IsInAnimation = false
        end
    end
end)
