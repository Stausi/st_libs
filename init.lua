if not _VERSION:find('5.4') then
    error('Lua 5.4 must be enabled in the resource manifest!', 2)
end

local resourceName = GetCurrentResourceName()
local st_libs = 'st_libs'

if resourceName == st_libs then 
    return 
end

if st and st.name == st_libs then
    error(("Cannot load st_libs more than once.\n\tRemove any duplicate entries from '@%s/fxmanifest.lua'"):format(resourceName))
end

local export = exports[st_libs]
if GetResourceState(st_libs) ~= 'started' then
    error('^st_libs must be started before this resource.^0', 0)
end

local status = export.hasLoaded()

if status ~= true then error(status, 2) end

-- Ignore invalid types during msgpack.pack (e.g. userdata)
msgpack.setoption('ignore_invalid', true)

-----------------------------------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------------------------------

local LoadResourceFile = LoadResourceFile
local context = IsDuplicityVersion() and 'server' or 'client'

function noop() end

local function loadModule(self, module)
    local dir = ('modules/%s'):format(module)
    local chunk = LoadResourceFile(st_libs, ('%s/%s.lua'):format(dir, context))
    local shared = LoadResourceFile(st_libs, ('%s/shared.lua'):format(dir))

    if shared then
        chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
    end

    if chunk then
        local fn, err = load(chunk, ('@@st_libs/modules/%s/%s.lua'):format(module, context))
        if not fn or err then
            return error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
        end

        local result = fn()
        self[module] = result or noop
        return self[module]
    end
end

-----------------------------------------------------------------------------------------------
-- API
-----------------------------------------------------------------------------------------------

local function call(self, index, ...)
    local module = rawget(self, index)

    if not module then
        self[index] = noop
        module = loadModule(self, index)

        if not module then
            local function method(...)
                return export[index](nil, ...)
            end

            if not ... then
                self[index] = method
            end

            return method
        end
    end

    return module
end

local st = setmetatable({
    name = st_libs,
    context = context,
}, {
    __index = call,
    __call = call,
})

local intervals = {}
--- Dream of a world where this PR gets accepted.
---@param callback function | number
---@param interval? number
---@param ... any
function SetInterval(callback, interval, ...)
    interval = interval or 0

    if type(interval) ~= 'number' then
        return error(('Interval must be a number. Received %s'):format(json.encode(interval --[[@as unknown]])))
    end

    local cbType = type(callback)

    if cbType == 'number' and intervals[callback] then
        intervals[callback] = interval or 0
        return
    end

    if cbType ~= 'function' then
        return error(('Callback must be a function. Received %s'):format(cbType))
    end

    local args, id = { ... }

    Citizen.CreateThreadNow(function(ref)
        id = ref
        intervals[id] = interval or 0
        repeat
            interval = intervals[id]
            Wait(interval)
            callback(table.unpack(args))
        until interval < 0
        intervals[id] = nil
    end)

    return id
end

---@param id number
function ClearInterval(id)
    if type(id) ~= 'number' then
        return error(('Interval id must be a number. Received %s'):format(json.encode(id --[[@as unknown]])))
    end

    if not intervals[id] then
        return error(('No interval exists with id %s'):format(id))
    end

    intervals[id] = -1
end

---@generic T
---@param key string
---@param func fun(...: any): T
---@param timeout? number
---@return T
function cache(key, func, timeout) end

local cacheEvents = {}
local cache = setmetatable({ game = GetGameName(), resource = resourceName }, {
    __index = function(self, key)
        cacheEvents[key] = {}

        AddEventHandler(('st_libs:cache:%s'):format(key), function(value)
            local oldValue = self[key]
            local events = cacheEvents[key]

            for i = 1, #events do
                Citizen.CreateThreadNow(function()
                    events[i](value, oldValue)
                end)
            end

            self[key] = value
        end)

        return rawset(self, key, export.cache(nil, key) or false)[key]
    end,

    __call = function(self, key, func, timeout)
        local value = rawget(self, key)

        if value == nil then
            value = func()

            rawset(self, key, value)

            if timeout then SetTimeout(timeout, function() self[key] = nil end) end
        end

        return value
    end,
})

function st.onCache(key, cb)
    if not cacheEvents[key] then
        getmetatable(cache).__index(cache, key)
    end

    table.insert(cacheEvents[key], cb)
end

_ENV.st = st
_ENV.cache = cache
_ENV.require = st.require

local notifyEvent = ('__st_notify_%s'):format(cache.resource)

if context == 'client' then
    RegisterNetEvent(notifyEvent, function(data)
        if locale then
            if data.title then
                data.title = locale(data.title) or data.title
            end

            if data.description then
                data.description = locale(data.description) or data.description
            end
        end

        return export:notify(data)
    end)

    cache.playerId = PlayerId()
    cache.serverId = GetPlayerServerId(cache.playerId)
else
    ---`server`\
    ---Trigger a notification on the target playerId from the server.\
    ---If locales are loaded, the title and description will be formatted automatically.\
    ---Note: No support for locale placeholders when using this function.
    ---@param playerId number
    ---@param data NotifyProps
    ---@deprecated
    ---@diagnostic disable-next-line: duplicate-set-field
    function st.notify(playerId, data)
        TriggerClientEvent(notifyEvent, playerId, data)
    end

    local poolNatives = {
        CPed = GetAllPeds,
        CObject = GetAllObjects,
        CVehicle = GetAllVehicles,
    }

    ---@param poolName 'CPed' | 'CObject' | 'CVehicle'
    ---@return number[]
    ---Server-side parity for the `GetGamePool` client native.
    function GetGamePool(poolName)
        local fn = poolNatives[poolName]
        return fn and fn() --[[@as number[] ]]
    end

    ---@return number[]
    ---Server-side parity for the `GetPlayers` client native.
    function GetActivePlayers()
        local playerNum = GetNumPlayerIndices()
        local players = table.create(playerNum, 0)

        for i = 1, playerNum do
            players[i] = tonumber(GetPlayerFromIndex(i - 1))
        end

        return players
    end
end

for i = 1, GetNumResourceMetadata(cache.resource, 'st_lib') do
    local name = GetResourceMetadata(cache.resource, 'st_lib', i - 1)

    if not rawget(st, name) then
        local module = loadModule(st, name)

        if type(module) == 'function' then 
            pcall(module) 
        end
    end
end
