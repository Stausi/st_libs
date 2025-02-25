---Loads an audio bank.
---@param audioBank string
---@param timeout number?
---@return string
function st.requestAudioBank(audioBank, timeout)
    return st.waitFor(function()
        if RequestScriptAudioBank(audioBank, false) then return audioBank end
    end, ("failed to load audiobank '%s' - this may be caused by\n- too many loaded assets\n- oversized, invalid, or corrupted assets"):format(audioBank), timeout or 30000)
end

return st.requestAudioBank
