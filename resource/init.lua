local debug_getinfo = debug.getinfo

function noop() end

st = setmetatable({
    name = 'st_libs',
    context = IsDuplicityVersion() and 'server' or 'client',
}, {
    __newindex = function(self, key, fn)
        rawset(self, key, fn)

        if debug_getinfo(2, 'S').short_src:find('@st_libs/resource') then
            exports(key, fn)
        end
    end,

    __index = function(self, key)
        local dir = ('modules/%s'):format(key)
        local chunk = LoadResourceFile(self.name, ('%s/%s.lua'):format(dir, self.context))
        local shared = LoadResourceFile(self.name, ('%s/shared.lua'):format(dir))

        if shared then
            chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
        end

        if chunk then
            local fn, err = load(chunk, ('@@st_libs/%s/%s.lua'):format(key, self.context))

            if not fn or err then
                return error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
            end

            rawset(self, key, fn() or noop)

            return self[key]
        end
    end
})

cache = {
    libLoaded = false,
    resource = st.name,
    game = GetGameName(),
}

if not LoadResourceFile(st.name, 'web/build/index.html') then
    local err = '^1Unable to load UI. Build st_libs or download the latest release.\n	^3https://github.com/Stausi/st_libs/releases/latest/download/st_libs.zip^0'
    function st.hasLoaded() return err end

    error(err)
end

function st.waitLibLoading()
    while not cache.libLoaded do
        Wait(0)
    end
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
        if resource ~= resourceName then 
            return 
        end
        
        cb()
    end)
end

function st.hasLoaded() return true end

require = st.require
cache.libLoaded = true