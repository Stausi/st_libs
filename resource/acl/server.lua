local function allowAce(allow)
	return allow == false and 'deny' or 'allow'
end

function st.addAce(principal, ace, allow)
	if type(principal) == 'number' then
		principal = 'player.'..principal
	end

	ExecuteCommand(('add_ace %s %s %s'):format(principal, ace, allowAce(allow)))
end

function st.removeAce(principal, ace, allow)
	if type(principal) == 'number' then
		principal = 'player.'..principal
	end

	ExecuteCommand(('remove_ace %s %s %s'):format(principal, ace, allowAce(allow)))
end

function st.addPrincipal(child, parent)
	if type(child) == 'number' then
		child = 'player.'..child
	end

	ExecuteCommand(('add_principal %s %s'):format(child, parent))
end

function st.removePrincipal(child, parent)
	if type(child) == 'number' then
		child = 'player.'..child
	end

	ExecuteCommand(('remove_principal %s %s'):format(child, parent))
end

st.callback.register('st_libs:checkPlayerAce', function(source, command)
    return IsPlayerAceAllowed(source, command)
end)