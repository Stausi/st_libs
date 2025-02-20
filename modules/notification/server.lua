st.notify = {}

st.notify.ShowNotification = function(source, msg)
    TriggerClientEvent(GetCurrentResourceName() .. ":client:ShowNotification", source, msg)
end

st.notify.ShowAdvancedNotification = function(source, title, subject, msg, icon, iconType)
    TriggerClientEvent(GetCurrentResourceName() .. ":client:ShowAdvancedNotification", source, title, subject, msg, icon, iconType)
end

st.notify.ShowHelpNotification = function(source, msg)
    TriggerClientEvent(GetCurrentResourceName() .. ":client:ShowHelpNotification", source, msg)
end

if GetResourceState("ox_lib") == "started" or GetResourceState("ox_lib") ~= "missing" then
	st.notify.oxNotify = function(source, type, title, description, duration)
		TriggerEvent("ox_lib:notify", source, {
			title = title,
			description = description, 
			type = type, 
			duration = duration
		})
	end
end
