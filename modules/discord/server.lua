st.discord = {}

st.discord.DiscordEmbed = function(webhook, name, title, description, codeblock)
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    
    if description ~= nil then
        local description = description .. ' ' .. timestamp
    else
        local description = timestamp
    end
    
    local codeblock = codeblock
    if codeblock then
        if codeblock ~= "" then
            codeblock = "```\n" .. codeblock .. "```"
        else
            codeblock = ""
        end
    end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description .. codeblock,
            ["color"] = 15616206,
            ["timestamp"] = timestamp,
            ["footer"] = {
                ["text"] = name,
                ["icon_url"] = "https://i.imgur.com/yHRNWQL.png",
            },
            ["author"] = {
                ["name"] = name,
                ["icon_url"] = "https://i.imgur.com/yHRNWQL.png"
            }
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({username = user, embeds = embed}), {['Content-Type'] = 'application/json'})
end

return st.discord
