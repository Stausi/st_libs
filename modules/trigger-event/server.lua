st.triggerEvent = {}

function st.triggerEvent.server(source, event, ...)
  TriggerClientEvent("st_libs:trigger-event:client:receive", source, event, ...)
end