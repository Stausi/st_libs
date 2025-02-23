---@param value string
function st.setClipboard(value)
    SendNUIMessage({
        action = 'setClipboard',
        data = value
    })
end