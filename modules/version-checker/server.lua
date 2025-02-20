-------------
-- ONLY FOR Stausi Scripts!
-------------

st.versionChecker = {}

local function urlencode(str)
	if str then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w ])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
		str = string.gsub(str, " ", "+")
	end
	return str
end

function string:split(inSplitPattern, outResults)
	if not outResults then
		outResults = {}
	end

	local theStart = 1
	local theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
	while theSplitStart do
		table.insert(outResults, string.sub(self, theStart, theSplitStart - 1))
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
	end

	table.insert(outResults, string.sub(self, theStart))

	return outResults
end

function convertVersion(version)
	if not version then 
		return 1 
	end

	local converted = 0
	if type(version) == "string" then
		local array = version:split("%.")
		local multiplicator = 1
		for i = #array, 1, -1 do
			converted = converted + multiplicator * array[i]
			multiplicator = multiplicator * 100
		end
	end
	return converted
end

function st.versionChecker.GetScriptVersion()
	return GetResourceMetadata(GetCurrentResourceName(), "version", 0) or 1
end

function st.versionChecker.StopAddon(resource)
	CreateThread(function()
		StopResource(resource)
	end)
	return true
end

exports("StopAddon", function(resource)
	return st.versionChecker.StopAddon(resource)
end)

function st.versionChecker.checkUpdate()
	local myResource = GetCurrentResourceName()
	local currentVersion = GetResourceMetadata(myResource, "version", 0)
	local packageID = tonumber(GetResourceMetadata(myResource, "package_id", 0))
	if not packageID or not currentVersion then return end

	local downloadAt = "https://keymaster.fivem.net/asset-grants"
	if myResource == "st_libs" then
		downloadAt = "https://github.com/Stausi/st_libs"
	end

	local serverName = urlencode(GetConvar("sv_hostname", ""))
	local link = ("https://api.stausi.com/versionCheck.php?package=%d&server_name=%s"):format(packageID, serverName)

	local waiter = promise.new()
	PerformHttpRequest(link, function(errorCode, resultData, resultHeaders, errorData)
		waiter:resolve("")

		if errorCode ~= 200 then
			return print("^3" .. myResource .. ": version checker API is offline. Impossible to check your version.^0")
		end

		resultData = json.decode(resultData)

		if not resultData.version then
			return print("^3" .. myResource .. ": " .. resultData.error .. "^0")
		end

		local lastVersion = convertVersion(resultData.version:sub(1))
		if convertVersion(currentVersion) >= lastVersion then
			return print(("^3%s: \x1b[92mUp to date - Version %s^0"):format(myResource, currentVersion))
		end

		print("^3┌───────────────────────────────────────────────────┐^0")
		print("")
		print("^3" .. myResource .. ": ^5 Update found : Version " .. resultData.version .. "^0")
		print("^3Download it on ^0" .. downloadAt)
		print("")
		print("^3Description of " .. resultData.version .. ":^0")
		print(resultData.release_notes)
		print("")
		print("^3└───────────────── shop.stausi.com ──────────────┘^0")
	end)

	Citizen.Await(waiter)

	local dependencies = GetResourceMetadata(myResource, "dependencies_version_min", 0)
	if dependencies then
		dependencies = dependencies:split(",")
		for _, dependency in ipairs(dependencies) do
			local data = dependency:split(":")
			local script = data[1]
			local minVersion = data[2]

			if GetResourceState(script) ~= "started" then
				eprint(script .. " is missing !")
			else
				local currentVersion = exports[script]:GetScriptVersion()
				if convertVersion(currentVersion) < convertVersion(minVersion) then
					print("^1" .. script .. " needs to be updated^0: Required version: " .. minVersion .. ", Your version: " .. currentVersion)
				end
			end
		end
	end
end

st.ready(function()
  	st.versionChecker.checkUpdate()
end)
