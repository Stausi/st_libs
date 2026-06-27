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
---@field persistent? boolean   -- 🔹 new flag

local activeNotifications = 0
local normalOffset = 20
local pushedOffset = 100
local defaultDuration = 3000

local function setDispatchOffset(offset)
    -- Set the offset for the notification dispatch
end

local function beginOffset()
    activeNotifications = activeNotifications + 1
    setDispatchOffset(pushedOffset)
end

local function endOffsetAfter(duration)
    SetTimeout(duration or defaultDuration, function()
        activeNotifications = activeNotifications - 1

        if activeNotifications < 0 then
            activeNotifications = 0
        end

        if activeNotifications == 0 then
            setDispatchOffset(normalOffset)
        end
    end)
end

---`client`
---@param data NotifyProps
---@diagnostic disable-next-line: duplicate-set-field
function st.notify(data)
    beginOffset()

    SendNUIMessage({
        action = 'notify',
        data = data
    })

    endOffsetAfter(data.duration)

    if not data.sound then return end

    if data.sound.bank then
        st.requestAudioBank(data.sound.bank)
    end

    local soundId = GetSoundId()
    PlaySoundFrontend(soundId, data.sound.name, data.sound.set, true)
    ReleaseSoundId(soundId)

    if data.sound.bank then
        ReleaseNamedScriptAudioBank(data.sound.bank)
    end
end

exports('notify', st.notify)
RegisterNetEvent('st_libs:notify', st.notify)

--- Create a persistent notification that stays until manually dismissed.
--- @param data NotifyProps
--- @return string id
function st.persistentNotification(data)
    if not data.id then
        data.id = tostring(math.random(100000, 999999)) .. tostring(GetGameTimer())
    end

    data.persistent = true
    data.duration = 0 
    data.showDuration = false

    beginOffset()

    SendNUIMessage({
        action = 'notify',
        data = data
    })

    if data.sound then
        if data.sound.bank then
            st.requestAudioBank(data.sound.bank)
        end

        local soundId = GetSoundId()
        PlaySoundFrontend(soundId, data.sound.name, data.sound.set, true)
        ReleaseSoundId(soundId)

        if data.sound.bank then
            ReleaseNamedScriptAudioBank(data.sound.bank)
        end
    end

    return data.id
end
exports('persistentNotification', st.persistentNotification)

function st.dismissNotification(id)
    if not id then return end

    SendNUIMessage({
        action = 'clearNotification',
        data = {
            id = id
        }
    })

    activeNotifications = activeNotifications - 1

    if activeNotifications < 0 then
        activeNotifications = 0
    end

    if activeNotifications == 0 then
        setDispatchOffset(normalOffset)
    end
end
exports('dismissNotification', st.dismissNotification)