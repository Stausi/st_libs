st.require("framework-bridge")

local group_members = {}
local server_blips = {}
local distanceTimeoutTimer = 10 * 1000

local function uuid()
    local template = 'xxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function IsEntityRegistered(netID)
    for blipKey, blip in pairs(server_blips) do
        if blip.netID == netID then
            return true, blipKey
        end
    end

    return false
end

local function GenerateUUID()
    local isUUIDGenerated = false
    local randomKey = nil

    repeat
        randomKey = uuid()
        if not server_blips[randomKey] then 
            isUUIDGenerated = true 
        end
    until isUUIDGenerated

    return randomKey
end

if st.framework:is("ESX") then
    AddEventHandler('esx:setJob', function(target, job, lastJob)
        local _target = target
        if job.name == lastJob.name then 
            return 
        end

        local identifier = st.framework:getUserIdentifier(_target)
        for group, identifiers in pairs(group_members) do
            for playerIdentifier in pairs(identifiers) do
                if playerIdentifier == identifier then
                    group_members[group][identifier] = nil
                end
            end
        end
    end)
elseif st.framework:is("QB") then
end

AddEventHandler('playerDropped', function()
    local _source = source

    local identifier = st.framework:getUserIdentifier(source)
    for group, identifiers in pairs(group_members) do
        for playerIdentifier in pairs(identifiers) do
            if playerIdentifier == identifier then
                group_members[group][identifier] = nil
            end
        end
    end

    for key, blip in pairs(server_blips) do
        if not blip.groups and blip.user then
            if blip.user == _source then
                server_blips[key] = nil
            end
        end

        if blip.users then
            for player, playerIdentifier in pairs(blip.users) do
                if identifier == playerIdentifier then
                    blip.users[player] = nil
                end
            end
        end
    end 
end)

function st.registerBlipMember(source, groups)
    local identifier = st.framework:getUserIdentifier(source)
    if type(groups) ~= "table" then
        groups = { groups }
    end

    for _, group in pairs(groups) do
        if not group_members[group] then
            group_members[group] = {}
        end

        group_members[group][identifier] = source
    end
end

function st.removeBlipMember(source, groups)
    local identifier = st.framework:getUserIdentifier(source)
    if type(groups) ~= "table" then
        groups = { groups }
    end

    for _, group in pairs(groups) do
        if group_members[group] then
            group_members[group][identifier] = nil
        end        
    end
end

function st.registerBlipEntity(source, data)
    if not data or not data.netID then 
        return 
    end

    if IsEntityRegistered(data.netID) then
        return
    end

    local userTarget = data.user
    if not data.groups and not userTarget then
        userTarget = source
    end

    local generatedKey = GenerateUUID()
    server_blips[generatedKey] = {
        netID = data.netID,
        groups = data.groups,
        users = data.users,
        user = userTarget,
        refreshRate = data.refreshRate or 2000,
        refreshTimer = 0,
        blipData = {
            name = data.name or generatedKey,
            sprite = data.sprite or 1,
            colour = data.colour or 1,
            route = data.route or false,
            routColour = data.routColour or data.colour,
            scale = data.scale or 1.0,
            attachOnEntity = data.attachOnEntity or false,
        }
    }
end

function st.removeBlipEntity(netID)
    if not netID then 
        return 
    end

    local isRegistered, key = IsEntityRegistered(netID)
    if not isRegistered then 
        return 
    end

    server_blips[key] = nil
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        local time = GetGameTimer()
        local updates = {}

        for key, blip in pairs(server_blips) do
            if (time - blip.refreshTimer) <= blip.refreshRate then
                goto continue
            end

            local blipData = table.clone(blip.blipData)
            local targetEntity = NetworkGetEntityFromNetworkId(blip.netID)
            
            blipData.isActive = DoesEntityExist(targetEntity)
            blipData.netID = blip.netID

            if blipData.isActive and (time - blip.refreshTimer) <= distanceTimeoutTimer then
                local lastPosition = blip.lastPosition or GetEntityCoords(targetEntity)
                local currentPosition = GetEntityCoords(targetEntity)
                if #(currentPosition - lastPosition) < 5.0 then 
                    goto continue 
                end
            end

            if blip.groups then
                for _, group in pairs(blip.groups) do
                    if not group_members[group] then
                        group_members[group] = {}
                    end

                    for _, user in pairs(group_members[group]) do
                        if not updates[user] then
                            updates[user] = {}
                        end
                        
                        updates[user][key] = blipData
                    end
                end
            end

            if blip.users then
                for user in pairs(blip.users) do
                    if not updates[user] then
                        updates[user] = {}
                    end

                    updates[user][key] = blipData
                end
            end

            if blip.user then
                if not updates[blip.user] then
                    updates[blip.user] = {}
                end

                updates[blip.user][key] = blipData
            end

            if blipData.isActive then
                blipData.position = GetEntityCoords(targetEntity)
                blip.lastPosition = blipData.position
            end

            blip.refreshTimer = time

            if not blipData.isActive then
                server_blips[key] = nil
            end

            ::continue::
        end

        if next(updates) then
            for user, data in pairs(updates) do
                TriggerClientEvent("st_libs:UpdateData", user, data)
            end
        end
    end
end)
