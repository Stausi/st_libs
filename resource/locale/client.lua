local function loadLocaleFile(key)
    local file = LoadResourceFile(cache.resource, ('locales/%s.json'):format(key)) or LoadResourceFile(cache.resource, 'locales/en.json')
    return file and json.decode(file) or {}
end

function st.getLocaleKey() return "en" end

---@param key string
function st.setLocale(key)
    TriggerEvent('st_libs:setLocale', key)

    SendNUIMessage({
        action = 'setLocale',
        data = loadLocaleFile(key)
    })
end

RegisterNUICallback('init', function(_, cb)
    cb(1)

    SendNUIMessage({
        action = 'setLocale',
        data = loadLocaleFile("en")
    })
end)

st.locale("en")