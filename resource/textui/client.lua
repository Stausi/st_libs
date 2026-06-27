local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118, ["RMB"] = 25, ["LMB"] = 24
}

local textUIEntries = {}

local function getResourceKey()
    return GetInvokingResource() or GetCurrentResourceName()
end

local function anyActiveEntriesForResource(resource)
    local resData = textUIEntries[resource]
    if not resData or not resData.entries then return false end

    for _, entry in pairs(resData.entries) do
        if entry.enabled then
            return true
        end
    end

    return false
end

local function rebuildAndSendNUI()
    local entries = {}
    local globalPosition = "bottom-center"

    for resource, resData in pairs(textUIEntries) do
        if resData.entries then
            for keyText, entry in pairs(resData.entries) do
                if entry.enabled then
                    table.insert(entries, {
                        id = resource .. ":" .. keyText,
                        keyText = entry.keyText,
                        displayText = entry.displayText,
                        hideKey = entry.hideKey or false,
                        position = entry.position or "bottom-center",
                    })

                    if globalPosition == "bottom-center" and entry.position then
                        globalPosition = entry.position
                    end
                end
            end
        end
    end

    SendNUIMessage({
        action = 'textUI',
        data = {
            entries = entries,
            position = globalPosition
        }
    })
end

local function startControlThreadFor(resource)
    local resData = textUIEntries[resource]
    if not resData or resData.threadStarted then return end

    resData.threadStarted = true

    Citizen.CreateThread(function()
        while anyActiveEntriesForResource(resource) do
            Citizen.Wait(0)

            resData = textUIEntries[resource]
            if not resData or not resData.entries then break end

            for keyText, entry in pairs(resData.entries) do
                if entry.enabled then
                    local keyCode = Keys[keyText]
                    if keyCode and IsControlJustReleased(0, keyCode) then
                        if entry.onPress then
                            entry.onPress()
                        end

                        if entry.callback then
                            entry.callback()
                        end
                    end
                end
            end
        end

        if textUIEntries[resource] then
            textUIEntries[resource].threadStarted = false
        end
    end)
end

function st.showTextUI(data, cb)
    if not data.keyText then
        print("Key text is required")
        return
    end

    if not Keys[data.keyText] then
        print("Invalid keyText provided: " .. tostring(data.keyText))
        return
    end

    if not data.displayText then
        print("Display text is required")
        return
    end

    local resource = getResourceKey()

    local resData = textUIEntries[resource]
    if not resData then
        resData = { entries = {}, threadStarted = false }
        textUIEntries[resource] = resData
    end

    local entry = resData.entries[data.keyText] or {}
    resData.entries[data.keyText] = entry

    entry.keyText = data.keyText
    entry.displayText = data.displayText
    entry.position = data.position or entry.position or "bottom-center"
    entry.hideKey = data.hideKey or false
    entry.onPress = data.press
    entry.callback = cb
    entry.enabled = true

    startControlThreadFor(resource)
    rebuildAndSendNUI()
end

function st.hideTextUI()
    local resource = getResourceKey()
    local resData = textUIEntries[resource]
    if not resData then return end

    textUIEntries[resource] = nil
    rebuildAndSendNUI()
end

AddEventHandler('onResourceStop', function(resName)
    if textUIEntries[resName] then
        textUIEntries[resName] = nil
        rebuildAndSendNUI()
    end
end)