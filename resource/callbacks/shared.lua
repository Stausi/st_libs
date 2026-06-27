local registeredCallbacks = {}

local isServer = cache.game == 'fxserver'
local callbackRateState = {}

local callbackRateLimitWindow = GetConvarInt('st:callbackRateLimitWindow', 10000)
local callbackRateLimitLogThreshold = GetConvarInt('st:callbackRateLimitLogThreshold', 30)
local callbackRateLimitRejectThreshold = GetConvarInt('st:callbackRateLimitRejectThreshold', GetConvarInt('st:callbackRateLimitMax', 60))
local callbackRateLimitDropThreshold = GetConvarInt('st:callbackRateLimitDropThreshold', 100)
local callbackRateLimitDrop = GetConvarInt('st:callbackRateLimitDrop', 1) == 1

local callbackRateLimitLogEvent = GetConvar('st:callbackRateLimitLogEvent', 'callback_spam')
local callbackRateLimitLogType = GetConvar('st:callbackRateLimitLogType', 'st_libs')

---@param resources table<string, { count: number, callbacks: table<string, number> }>
---@return string
local function formatRateLimitResources(resources)
    local resourceNames = {}

    for resourceName in pairs(resources) do
        resourceNames[#resourceNames + 1] = resourceName
    end

    table.sort(resourceNames)

    local formattedResources = table.create(#resourceNames, 0)

    for i = 1, #resourceNames do
        local resourceName = resourceNames[i]
        local resourceState = resources[resourceName]
        local callbackNames = {}

        for callbackName in pairs(resourceState.callbacks) do
            callbackNames[#callbackNames + 1] = callbackName
        end

        table.sort(callbackNames)

        local formattedCallbacks = table.create(#callbackNames, 0)

        for j = 1, #callbackNames do
            local callbackName = callbackNames[j]
            formattedCallbacks[j] = ('%s=%s'):format(callbackName, resourceState.callbacks[callbackName])
        end

        formattedResources[i] = ('%s(total=%s callbacks={%s})'):format(resourceName, resourceState.count, table.concat(formattedCallbacks, ', '))
    end

    return table.concat(formattedResources, '; ')
end

---@param playerId number
---@param callbackName string
---@param invokeResource string?
---@param action string
---@param count number
---@param resources table<string, { count: number, callbacks: table<string, number> }>
local function sendRateLimitLog(playerId, callbackName, invokeResource, action, count, resources)
    local resourceName = invokeResource or 'unknown'
    local resourceSummary = formatRateLimitResources(resources)
    local callbackCount = resources[resourceName]?.callbacks[callbackName] or 0
    local resourceCount = resources[resourceName]?.count or 0
    local logMessage = ('Callback spam detected: action=%s callback=%s count=%s windowMs=%s resource=%s'):format(action, callbackName, count, callbackRateLimitWindow, resourceName)
    local codeBlockMessage = ('resource=%s\nresourceCount=%s\ncallback=%s\ncallbackCount=%s\nresources=[%s]'):format(resourceName, resourceCount, callbackName, callbackCount, resourceSummary)

    pcall(function()
        -- Send log to configured event
    end)
end

---@param playerId number
---@param callbackName string
---@param invokeResource string?
---@return boolean, 'cb_rate_limited' | nil
local function isCallbackRateLimited(playerId, callbackName, invokeResource)
    if not isServer then
        return false
    end

    local now = GetGameTimer()
    local state = callbackRateState[playerId]
    local resourceName = invokeResource or 'unknown'

    if not state then
        callbackRateState[playerId] = {
            windowStart = now,
            count = 1,
            hasLogged = false,
            hasRejected = false,
            hasDropped = false,
            resources = {
                [resourceName] = {
                    count = 1,
                    callbacks = {
                        [callbackName] = 1,
                    }
                }
            },
        }

        return false
    end

    if now - state.windowStart >= callbackRateLimitWindow then
        state.windowStart = now
        state.count = 1
        state.hasLogged = false
        state.hasRejected = false
        state.hasDropped = false
        state.resources = {
            [resourceName] = {
                count = 1,
                callbacks = {
                    [callbackName] = 1,
                }
            }
        }

        return false
    end

    state.count += 1

    local resourceState = state.resources[resourceName]

    if not resourceState then
        resourceState = {
            count = 0,
            callbacks = {}
        }
        state.resources[resourceName] = resourceState
    end

    resourceState.count += 1
    resourceState.callbacks[callbackName] = (resourceState.callbacks[callbackName] or 0) + 1

    if callbackRateLimitLogThreshold > 0 and state.count >= callbackRateLimitLogThreshold and not state.hasLogged then
        state.hasLogged = true
        sendRateLimitLog(playerId, callbackName, invokeResource, 'log', state.count, state.resources)
    end

    if callbackRateLimitDrop and callbackRateLimitDropThreshold > 0 and state.count >= callbackRateLimitDropThreshold then
        if not state.hasDropped then
            state.hasDropped = true
            sendRateLimitLog(playerId, callbackName, invokeResource, 'drop', state.count, state.resources)
        end

        if DoesPlayerExist(playerId --[[@as string]]) then
            DropPlayer(playerId --[[@as string]], 'Callback spam detected')
        end

        return true, 'cb_rate_limited'
    end

    if callbackRateLimitRejectThreshold > 0 and state.count >= callbackRateLimitRejectThreshold then
        if not state.hasRejected then
            state.hasRejected = true
            sendRateLimitLog(playerId, callbackName, invokeResource, 'reject', state.count, state.resources)
        end

        return true, 'cb_rate_limited'
    end

    return false
end

if isServer then
    AddEventHandler('playerDropped', function()
        callbackRateState[source] = nil
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource == resourceName then return end

    for callbackName, resource in pairs(registeredCallbacks) do
        if resource == resourceName then
            registeredCallbacks[callbackName] = nil
        end
    end
end)

---For internal use only.
---Sets a callback event as registered to a specific resource, preventing it from
---being overwritten. Any unknown callbacks will return an error to the caller.
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
    local isRateLimited, response = isCallbackRateLimited(source, callbackName, invokingResource)

    if isRateLimited then
        return TriggerClientEvent(cbEvent:format(invokingResource), source, key, response)
    end

    if registeredCallbacks[callbackName] then return end

    local event = cbEvent:format(invokingResource)

    if cache.game == 'fxserver' then
        return TriggerClientEvent(event, source, key, 'cb_invalid')
    end

    TriggerServerEvent(event, key, 'cb_invalid')
end)