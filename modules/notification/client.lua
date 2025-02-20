st.notify = {}

st.notify.ShowNotification = function(msg)
	SetTextFont(st.notify.fontId)
	SetNotificationTextEntry('STRING')
	AddTextComponentSubstringPlayerName(msg)
	DrawNotification(false, true)
end

st.notify.ShowAdvancedNotification = function(title, subject, msg, icon, iconType)
	SetTextFont(st.notify.fontId)
	SetNotificationTextEntry('STRING')
	AddTextComponentSubstringPlayerName(msg)
	SetNotificationMessage(icon, icon, false, iconType, title, subject)
	DrawNotification(false, false)
end

st.notify.ShowHelpNotification = function(msg)
	SetTextFont(st.notify.fontId)
	BeginTextCommandDisplayHelp('STRING')
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandDisplayHelp(0, false, true, -1)
end

Citizen.CreateThread(function()
	RegisterFontFile('athiti')
    st.notify.fontId = RegisterFontId('athiti')
end)

RegisterNetEvent(GetCurrentResourceName() .. ":client:ShowNotification", function(msg)
    st.notify.ShowNotification(msg)
end)

RegisterNetEvent(GetCurrentResourceName() .. ":client:ShowAdvancedNotification", function(title, subject, msg, icon, iconType)
    st.notify.ShowAdvancedNotification(title, subject, msg, icon, iconType)
end)

RegisterNetEvent(GetCurrentResourceName() .. ":client:ShowHelpNotification", function(msg)
    st.notify.ShowHelpNotification(msg)
end)

if GetResourceState("ox_lib") == "started" or GetResourceState("ox_lib") ~= "missing" then
	st.notify.oxNotify = function(type, title, description, duration)
		TriggerEvent("ox_lib:notify", {
			title = title,
			description = description, 
			type = type, 
			duration = duration
		})
	end

	RegisterNetEvent(GetCurrentResourceName() .. ":client:oxNotify", function(title, description, type, duration)
		st.notify.oxNotify(type, title, description, duration)
	end)
end
