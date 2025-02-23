st.notify = {}

st.notify.ShowNativeNotification = function(source, msg)
    TriggerClientEvent(GetCurrentResourceName() .. ":client:ShowNativeNotification", source, msg)
end

st.notify.ShowAdvancedNotification = function(source, title, subject, msg, icon, iconType)
    TriggerClientEvent(GetCurrentResourceName() .. ":client:ShowAdvancedNotification", source, title, subject, msg, icon, iconType)
end

st.notify.ShowHelpNotification = function(source, msg)
    TriggerClientEvent(GetCurrentResourceName() .. ":client:ShowHelpNotification", source, msg)
end

st.notify.ShowNotification = function(source, data)
	TriggerClientEvent(GetCurrentResourceName() .. ":client:ShowNotification", source, data)
end
