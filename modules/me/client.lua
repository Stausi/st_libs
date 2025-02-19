st.me = PlayerPedId()
st.meCoords = GetEntityCoords(st.me)
st.mePlayerId = PlayerId()
st.meServerId = GetPlayerServerId(st.mePlayerId)
st.meIsMale = IsPedMale(PlayerPedId())

local valueUpdated = false

AddEventHandler('st_me:updateMe', function(me, meCoords, mePlayerId, meServerId, meIsMale)
    st.me = me
    st.meCoords = meCoords
    st.mePlayerId = mePlayerId
    st.meServerId = meServerId
    st.meIsMale = meIsMale
    valueUpdated = true
end)

function st.forceUpdateMe()
    valueUpdated = false
    exports.st_libs:st_me_forceUpdateMe()
    while not valueUpdated do Wait(0) end
end