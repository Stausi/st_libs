st.me = PlayerPedId()
st.meCoords = GetEntityCoords(me)
st.mePlayerId = PlayerId()
st.meServerId = GetPlayerServerId(st.mePlayerId)
st.meIsMale =  IsPedMale(PlayerPedId())

local timer = 1000
local timeout

st.require('timeout')

local function updateMe()
    st.forceUpdateMe()
end
timeout = st.timeout.loop(timer,updateMe)

---@param value integer the new interval to update me values
function st.updateMeTimer(value)
    timer = value
    if timeout then
        timeout:clear()
    end
    if timer then
        timeout = st.timeout.loop(timer,updateMe)
    end
end

function st.forceUpdateMe()
    st.me = PlayerPedId()
    st.meCoords = GetEntityCoords(st.me)
    st.mePlayerId = PlayerId()
    st.meServerId = GetPlayerServerId(st.mePlayerId)
    st.meIsMale = IsPedMale(st.me)
    TriggerEvent("st_me:updateMe",st.me,st.meCoords,st.mePlayerId,st.meServerId,st.meIsMale)
end

exports('st_me_forceUpdateMe', st.forceUpdateMe)