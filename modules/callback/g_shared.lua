local currentRequestId = 0
local responseCallback = {}
local registeredCallback = {}

local isServerSide = IsDuplicityVersion()

st.require("promise")

st.callback = {}

local function executeCallback(name, ...)
    if not registeredCallback[name] then return eprint(('No callback for: %s'):format(name)) end
    return registeredCallback[name].cb(...)
end

local function executeResponse(requestId, fromRessource, ...)
    if not responseCallback[requestId] then 
        return eprint(('No callback response for: %d - Called from: %d'):format(name, fromRessource)) 
    end

    responseCallback[requestId](...)
    responseCallback[requestId] = nil
end

---@param name string the name of the event
---@param cb function
function st.callback.register(name, cb)
    if registeredCallback[name] then 
        return eprint('Callback already registered:', name) 
    end

    registeredCallback[name] = {
        cb = cb,
        resource = GetInvokingResource()
    }
end

AddEventHandler('onResourceStop', function(resource)
    for name, callback in pairs(registeredCallback) do
        if callback.resource == resource then
            registeredCallback[name] = nil
        end
    end
end)

if isServerSide then
    ---@param name string Name of the callback event
    ---@param cb function return of the event
    ---@param ...? any
    function st.callback.triggerClient(name, source, cb, ...)
        if not GetPlayerIdentifier(source) then
            return eprint('Callback Module: Player is not connected - source: ' .. source)
        end

        local args = table.pack(...)
        if not cb then
            return st.promise.new(function(resolver)
                responseCallback[currentRequestId] = resolver
                TriggerClientEvent('st_libs:triggerCallback', source, name, currentRequestId, GetInvokingResource() or "unknown", table.unpack(args))
                currentRequestId = (currentRequestId < 65535) and (currentRequestId + 1) or 0
            end)
        else
            responseCallback[currentRequestId] = cb
            TriggerClientEvent('st_libs:triggerCallback', source, name, currentRequestId, GetInvokingResource() or "unknown", table.unpack(args))
            currentRequestId = (currentRequestId < 65535) and (currentRequestId + 1) or 0
        end
    end

    function st.callback.triggerServer(name, cb, ...)
        if not registeredCallback[name] then 
            return eprint('No server callback for:', name) 
        end

        local args = table.pack(...)
        if not cb then
            return st.promise.new(function(resolver)
                resolver(executeCallback(name, table.unpack(args)))
            end)
        else
            cb(executeCallback(name, table.unpack(args)))
        end
    end

    RegisterServerEvent('st_libs:responseCallback', executeResponse)

    RegisterServerEvent('st_libs:triggerCallback', function(name, requestId, fromRessource, ...)
        local source = source
        TriggerClientEvent('st_libs:responseCallback', source, requestId, fromRessource, executeCallback(name, source, ...))
    end)
else
    ---@param name string Name of the callback event
    ---@param cb function return of the event
    ---@param ...? any
    function st.callback.triggerServer(name, cb, ...)
        local args = table.pack(...)
        if not cb then
            return st.promise.new(function(resolver)
                responseCallback[currentRequestId] = resolver
                TriggerServerEvent('st_libs:triggerCallback', name, currentRequestId, GetInvokingResource() or 'unknown', table.unpack(args))
                currentRequestId = (currentRequestId < 65535) and (currentRequestId + 1) or 0
            end)
        else
            responseCallback[currentRequestId] = cb
            TriggerServerEvent('st_libs:triggerCallback', name, currentRequestId, GetInvokingResource() or 'unknown', table.unpack(args))
            currentRequestId = (currentRequestId < 65535) and (currentRequestId + 1) or 0
        end
    end

    function st.callback.triggerClient(name, cb, ...)
        if not registeredCallback[name] then 
            return eprint('No client callback for:', name) 
        end

        local args = table.pack(...)
        if not cb then
            return st.promise.new(function(resolver)
                resolver(executeCallback(name, table.unpack(args)))
            end)
        else
            cb(executeCallback(name, table.unpack(args)))
        end
    end

    RegisterNetEvent('st_libs:responseCallback', executeResponse)

    RegisterNetEvent('st_libs:triggerCallback', function(name, requestId, fromRessource, ...)
        TriggerServerEvent('st_libs:responseCallback', requestId, fromRessource, executeCallback(name, ...))
    end)
end

exports('getCallbackAPI', function()
    return st.callback
end)
