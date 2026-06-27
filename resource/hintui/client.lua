local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local isEnabled = false
local mappedKey = nil
local controlThreadRunning = false
local currentTitle = nil
local currentText = nil
local currentButton = nil

local function pushHintMessage(action, title, text, button)
    SendNUIMessage({
        action = action,
        data = {
            title = title,
            text = text,
            button = button,
        }
    })
end

function st.showHintUI(title, text, button)
    if not title then
        print("Title is required")
        return
    end

    if not text then
        print("Text is required")
        return
    end

    if not button then
        print("Button is required")
        return
    end

    if not Keys[button] then
        print("Invalid button provided: " .. tostring(button))
        return
    end

    if isEnabled then
        if currentTitle == title and currentText == text and currentButton == button then
            return
        end

        return st.hintUpdate(title, text, button)
    end

    isEnabled = true
    mappedKey = button
    currentTitle = title
    currentText = text
    currentButton = button

    StartHintUIControlThread()
    pushHintMessage('hintUI', title, text, button)
end

RegisterNetEvent('st_libs:showHintUI', function(title, text, button)
    st.showHintUI(title, text, button)
end)

StartHintUIControlThread = function()
    if controlThreadRunning then
        return
    end

    controlThreadRunning = true

    Citizen.CreateThread(function()
        while isEnabled do
            Citizen.Wait(0)

            if IsControlJustReleased(0, Keys[mappedKey]) then
                st.hideHintUI()
            end
        end

        controlThreadRunning = false
    end)
end

function st.hintUpdate(title, text, button)
    if not title and not text and not button then
        print("At least one parameter (title, text, button) must be provided")
        return
    end

    if not isEnabled then
        print("Hint UI is not enabled... showing new hint UI")
        return st.showHintUI(title, text, button)
    end

    currentTitle = title or currentTitle
    currentText = text or currentText
    currentButton = button or currentButton
    mappedKey = currentButton

    pushHintMessage('hintUpdate', currentTitle, currentText, currentButton)
end

function st.hideHintUI()
    isEnabled = false
    mappedKey = nil
    currentTitle = nil
    currentText = nil
    currentButton = nil

    SendNUIMessage({
        action = 'hintUiHide',
    })
end

-- RegisterCommand('showHint', function()
--     st.showHintUI("Current Task", "Do something", "E")
-- end, false)

-- RegisterCommand('hideHint', function()
--     st.hideHintUI()
-- end, false)
