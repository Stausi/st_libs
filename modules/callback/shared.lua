local registeredCallbacks = {}

AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource == resourceName then return end

    for callbackName, resource in pairs(registeredCallbacks) do
        if resource == resourceName then
            registeredCallbacks[callbackName] = nil
        end
    end
end)

---@param callbackName string
---@param isValid boolean
function st.setValidCallback(callbackName, isValid)
    local resourceName = GetInvokingResource() or cache.resource
    local callbackResource = registeredCallbacks[callbackName]

    if callbackResource then
        if not isValid then
            callbackResource[callbackName] = nil
            return
        end

        if callbackResource == resourceName then return end

        error(("cannot overwrite callback '%s' owned by resource '%s'"):format(callbackName, callbackResource))
    end

    registeredCallbacks[callbackName] = resourceName
end

function st.isCallbackValid(callbackName)
    return registeredCallbacks[callbackName] == GetInvokingResource() or cache.resource
end

local cbEvent = '__st_cb_%s'
RegisterNetEvent('st_libs:validateCallback', function(callbackName, invokingResource, key)
    if registeredCallbacks[callbackName] then return end

    local event = cbEvent:format(invokingResource)
    if cache.game == 'fxserver' then
        return TriggerClientEvent(event, source, key, 'cb_invalid')
    end

    TriggerServerEvent(event, key, 'cb_invalid')
end)