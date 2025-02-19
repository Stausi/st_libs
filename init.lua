if not _VERSION:find("5.4") then
    error("^1Lua 5.4 must be enabled in the resource manifest!^0", 2)
end

local resourceName = GetCurrentResourceName()
local st_libs = "st_libs"
local modules = { "table", "print", "file", "trigger-event" }
local function noFunction() end
local LoadResourceFile = LoadResourceFile
local context = IsDuplicityVersion() and "server" or "client"
local moduleInLoading = {}
local moduleLocal = {}
local globalModuleLoaded = {}

local alias = {
    framework = "framework-bridge",
    versionChecker = "version-checker",
    triggerEvent = "trigger-event"
}

local function getAlias(module)
    if module == "meCoords" or module == "mePlayerId" or module == "meServerId" then 
        return "me" 
    end

    if alias[module] then 
        return module 
    end

    for alia, name in pairs(alias) do
        if name == module then
            return alia
        end
    end
    
    return module
end

--list modules required
for i = 1, GetNumResourceMetadata(resourceName, "st_lib") do
    modules[#modules + 1] = getAlias(GetResourceMetadata(resourceName, "st_lib", i - 1))
end

if st and st.name == st_libs then
    error(("st_libs is already loaded.\n\tRemove any duplicate entries from '@%s/fxmanifest.lua'"):format(resourceName))
end

function GetHashFromString(value)
    if type(value) == "string" then
        local number = tonumber(value)
        if number then return number end
        return staat(value)
    end
    return value
end

function UnJson(value)
    if not value then return {} end
    if value == "null" then return {} end
    if type(value) == "string" then
        return json.decode(value)
    end
    return value
end

local function isModuleLoaded(name, needLocal)
    if needLocal and not moduleLocal[name] then return false end
    if moduleInLoading[name] then return true end
    if rawget(st, name) then return true end
    return false
end

local function loadGlobalModule(module)
    if resourceName == "st_libs" then return end
    while GetResourceState("st_libs") ~= "started" do Wait(0) end
    exports.st_libs:loadGlobalModule(module)
end

local function doesScopedFilesRequired(name)
    if name == "table" then return true end
    return resourceName ~= "st_libs" or table.find(modules, function(_name) return _name == name end)
end

local function loadModule(self, name, needLocal)
    if needLocal == nil then 
        needLocal = true 
    end

    local folder = alias[name] or name
    local dir = ("modules/%s"):format(folder)
    local file = ""

    moduleInLoading[folder] = true
    moduleInLoading[name] = true

    if needLocal then
        moduleLocal[folder] = true
        moduleLocal[name] = true
    end

    loadGlobalModule(name)
    self[name] = noFunction

    for _, fileName in ipairs({ "shared", "context" }) do
        fileName = fileName == "context" and context or fileName
        local link = ("%s/%s.lua"):format(dir, fileName)
        
        if needLocal or doesScopedFilesRequired(name) then
            local tempFile = LoadResourceFile("st_libs", link)
            if tempFile then
                file = file .. tempFile
            end
        end
        
        local globalLink = ("%s/%s.lua"):format(dir, "g_" .. fileName)
        if resourceName == "st_libs" and not globalModuleLoaded[globalLink] then
            globalModuleLoaded[globalLink] = true
            local tempFile = LoadResourceFile("st_libs", globalLink)
            if tempFile then
                file = file .. tempFile
            end
        end
    end

    if file then
        local fn, err = load(file, ("@@st_libs/%s/%s.lua"):format(dir, context))
        if not fn or err then
            return error(("\n^1Error importing module (%s): %s^0"):format(dir, err), 3)
        end

        local result = fn()
        self[name] = result or self[name] or noFunction
    end

    moduleInLoading[name] = nil
    moduleInLoading[folder] = nil

    return self[name]
end

local function call(self, name, ...)
    if not name then 
        return noFunction 
    end

    if type(name) ~= "string" then 
        return noFunction() 
    end

    name = getAlias(name)
    local module = rawget(st, name)

    if not module then
        module = loadModule(self, name)
    end

    while moduleInLoading[name] do Wait(0) end

    return module
end

local st = setmetatable({
    libLoaded = false,
    debug = false,
    name = st_libs,
    resourceName = resourceName,
    context = context,
    cache = {}
}, {
    __index = call,
    __call = noFunction
})

function st.waitLibLoading()
    while not st.libLoaded do
        Wait(0)
    end
end

function st.isModuleLoaded(name, needLocal)
    local name = getAlias(name)
    return isModuleLoaded(name, needLocal)
end

local function onReady(cb)
    st.waitLibLoading()
    Wait(1000)

    return cb and cb() or true
end

function st.ready(cb)
    Citizen.CreateThreadNow(function() onReady(cb) end)
end

function st.stopped(cb)
    AddEventHandler("onResourceStop", function(resource)
        if resource ~= resourceName then return end
        cb()
    end)
end

_ENV.st = st


if GetResourceState(st_libs) ~= "started" and resourceName ~= "st_libs" then
    error("^1st_libs must be started before this resource.^0", 0)
end

-------------
-- DEFAULT MODULES
-------------

function st.require(name, needLocal)
    if needLocal == nil then 
        needLocal = true 
    end

    name = getAlias(name)

    if isModuleLoaded(name, needLocal) then 
        return 
    end

    local module = loadModule(st, name, needLocal)
    if type(module) == "function" then 
        pcall(module) 
    end
end

if resourceName == "st_libs" then
    exports("loadGlobalModule", function(name)
        st.require(name, false)
        return true
    end)
    AddEventHandler("st_libs:loadGlobalModule", function(name, cb)
        st.require(name, false)
        cb()
        return true
    end)
end

st.require("print")

if GetConvar(resourceName .. ":debug", "off") == "on" then
    oprint(("/!\\ %s is in debug mode /!\\"):format(resourceName))
    oprint("Don't use this in production!")
    st.debug = true
end

AddConvarChangeListener(resourceName .. ":debug", function()
    st.debug = GetConvar(resourceName .. ":debug", "off") == "on"

    if st.debug then
        oprint(("/!\\ %s is in debug mode /!\\"):format(resourceName))
        oprint("Don't use this in production!")
    else
        oprint(("/!\\ %s debug mode turned OFF /!\\"):format(resourceName))
    end
end)


-------------
-- EXPORTS (prevent call before initializes)
-------------
local function CreateExport(name, cb)
    exports(name, function(...)
        st.waitLibLoading()
        return cb(...)
    end)
end

--Sort module by priority
local priorityModules = { 
    table = 1, 
    print = 2,
    file = 3, 
    hook = 4, 
    framework = 5 
}

table.sort(modules, function(a, b)
    local prioA = priorityModules[a]
    local prioB = priorityModules[b]
    if prioA and prioB then
        return prioA < prioB
    end
    if prioA then return true end
    if prioB then return false end
    return a < b
end)

-------------
-- LOAD REQUIRED MODULES
-------------

for _, name in ipairs(modules) do
    st.require(name)

    if name == "hook" then
        CreateExport("registerAction", st.hook.registerAction)
        CreateExport("RegisterAction", st.hook.RegisterAction)
        CreateExport("registerFilter", st.hook.registerFilter)
        CreateExport("RegisterFilter", st.hook.RegisterFilter)
    elseif name == "versionChecker" and context == "server" then
        CreateExport("GetScriptVersion", st.versionChecker.GetScriptVersion)
        CreateExport("StopAddon", st.versionChecker.stopAddon)
    end
end
st.libLoaded = true