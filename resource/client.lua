RegisterNUICallback('getConfig', function(_, cb)
    cb({
        primaryColor = GetConvar('st:primaryColor', 'blue'),
        primaryShade = GetConvarInt('st:primaryShade', 8)
    })
end)