st.require("framework-bridge")

local blips_cache = {}
local lastJob = ""

local function WipeBlips()
    for _, data in pairs(blips_cache) do
        local entity = NetworkGetEntityFromNetworkId(data.netID)
        if DoesEntityExist(entity) and not DoesBlipExist(data.blip) then
            data.blip = GetBlipFromEntity(entity)
        end
        
        if data.blip and DoesBlipExist(data.blip) then
            RemoveBlip(data.blip)
        end
    end

    blips_cache = {}
end

local function setBlipProperties(blip, props)
    if props.sprite then 
        SetBlipSprite(blip, props.sprite) 
    end

    if props.colour then 
        SetBlipColour(blip, props.colour) 
    end

    if props.scale then 
        SetBlipScale(blip, props.scale) 
    end

    if props.position then 
        SetBlipCoords(blip, props.position.x, props.position.y, props.position.z) 
    end

    if props.hasCreated then
        SetBlipRoute(blip, props.route)

        if props.routeColour then 
            SetBlipRouteColour(blip, props.routeColour) 
        end
    end

    SetBlipAlpha(blip, 255)
    SetBlipAsShortRange(blip, true)

    if props.name then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(props.name)
        EndTextCommandSetBlipName(blip)
    end
end

local function RefreshBlips(blipData)
    for key, data in pairs(blipData) do
        local previous_data = blips_cache[key] or {}
        data.blip = previous_data.blip

        if not data.isActive and (DoesBlipExist(data.blip) or data.attachOnEntity) then
            if NetworkDoesEntityExistWithNetworkId(data.netID) then
                local entity = NetworkGetEntityFromNetworkId(data.netID)
                if DoesEntityExist(entity) and not DoesBlipExist(data.blip) then
                    data.blip = GetBlipFromEntity(entity)
                end
            end
            
            RemoveBlip(data.blip)
        end

        if data.isActive then
            if not data.attachOnEntity then
                if DoesBlipExist(data.blip) then
                    SetBlipCoords(data.blip, data.position.x, data.position.y, data.position.z)
                end

                if not DoesBlipExist(data.blip) then
                    data.blip = AddBlipForCoord(data.position.x, data.position.y, data.position.z)
                    data.hasCreated = true
                end
            end

            if data.attachOnEntity then
                if NetworkDoesEntityExistWithNetworkId(data.netID) then
                    local entity = NetworkGetEntityFromNetworkId(data.netID)
                    if DoesEntityExist(entity) then
                        local entityBlip = GetBlipFromEntity(entity)
                        if not DoesBlipExist(entityBlip) then 
                            RemoveBlip(data.blip)
                            data.blip = AddBlipForEntity(entity)
                            data.hasCreated = true
                        end
                    end
                end

                if not NetworkDoesEntityExistWithNetworkId(data.netID) then
                    if DoesBlipExist(data.blip) then
                        SetBlipCoords(data.blip, data.position.x, data.position.y, data.position.z)
                    end

                    if not DoesBlipExist(data.blip) then
                        data.blip = AddBlipForCoord(data.position.x, data.position.y, data.position.z)
                        data.hasCreated = true
                    end
                end
            end
        end

        if DoesBlipExist(data.blip) then
            setBlipProperties(data.blip, data)
        end

        blips_cache[key] = data
    end
end

if st.framework:is("ESX") then
    RegisterNetEvent('esx:setJob', function(job)
        if job.name ~= lastJob then
            WipeBlips()
        end
        lastJob = job.name
    end)

    RegisterNetEvent("esx:playerLoaded", function(xPlayer)
        lastJob = xPlayer.job.name
    end)
end

RegisterNetEvent("st_libs:UpdateData", function(data)
    RefreshBlips(data)
end)
