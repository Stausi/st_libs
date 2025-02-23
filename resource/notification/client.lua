---@alias NotificationPosition 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left' | 'center-right' | 'center-left'
---@alias NotificationType 'info' | 'warning' | 'success' | 'error'
---@alias IconAnimationType 'spin' | 'spinPulse' | 'spinReverse' | 'pulse' | 'beat' | 'fade' | 'beatFade' | 'bounce' | 'shake'

---@class NotifyProps
---@field id? string
---@field title? string
---@field description? string
---@field duration? number
---@field showDuration? boolean
---@field position? NotificationPosition
---@field type? NotificationType
---@field style? { [string]: any }
---@field icon? string | { [1]: IconProp, [2]: string }
---@field iconAnimation? IconAnimationType
---@field iconColor? string
---@field alignIcon? 'top' | 'center'
---@field sound? { bank?: string, set: string, name: string }

---`client`
---@param data NotifyProps
---@diagnostic disable-next-line: duplicate-set-field
function st.notify(data)
    data.position = data.position

    SendNUIMessage({
        action = 'notify',
        data = data
    })

    if not data.sound then return end

    if data.sound.bank then 
		st.requestAudioBank(sound.bank) 
	end

    local soundId = GetSoundId()
    PlaySoundFrontend(soundId, data.sound.name, data.sound.set, true)
    ReleaseSoundId(soundId)

    if data.sound.bank then 
		ReleaseNamedScriptAudioBank(data.sound.bank) 
	end
end

RegisterNetEvent('st_libs:notify', st.notify)