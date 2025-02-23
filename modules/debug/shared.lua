st.debug = {}

local performanceRecords = {}

st.debug.perfomance = function(title, cb)
    local starTime = os.microtime()
    local result = table.pack(cb())
    local endTime = os.microtime()
    print(("%d, Performance: %s -> %d μs"):format(os.time(), title, endTime - starTime))
    return table.unpack(result)
end

--- @param title string An optional title describing this measurement
--- @return string The auto-generated ID to be used in performanceStop
st.debug.performanceStart = function(title)
    local resourceName = GetInvokingResource() or "UnknownResource"
    
    local uniqueID = string.format("%s_%d", resourceName, math.random(100000,999999))
    performanceRecords[uniqueID] = {
        startTime = os.microtime(),
        title     = title or ("ID_" .. uniqueID)
    }

    return uniqueID
end

--- @param id string The unique ID returned by performanceStart
--- @return number The elapsed time in microseconds
st.debug.performanceStop = function(id)
    local record = performanceRecords[id]
    if not record then
        error(("No record found for ID '%s'. Make sure you called performanceStart first."):format(tostring(id)))
    end

    local endTime = os.microtime()
    local elapsed = endTime - record.startTime

    print(("%d, Performance: %s -> %d μs"):format(os.time(), record.title, elapsed))

    performanceRecords[id] = nil

    return elapsed
end

return st.debug
