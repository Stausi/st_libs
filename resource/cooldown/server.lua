local cooldownPools = {}

---@param pool string | string[]
---@return string[]
local function normalizePoolNames(pool)
    local poolType = type(pool)

    if poolType == 'string' then
        return { pool }
    end

    if poolType ~= 'table' then
        error(('pool must be a string or string array. Received %s'):format(poolType), 3)
    end

    local names = {}

    for index, name in ipairs(pool) do
        if type(name) ~= 'string' or name == '' then
            error(('pool[%s] must be a non-empty string'):format(index), 3)
        end

        names[#names + 1] = name
    end

    if #names == 0 then
        error('pool array cannot be empty', 3)
    end

    return names
end

---@param pool string | string[]
function st.registerCooldownPool(pool)
    local poolNames = normalizePoolNames(pool)

    for i = 1, #poolNames do
        local poolName = poolNames[i]

        if not cooldownPools[poolName] then
            cooldownPools[poolName] = 0
        end
    end
end

---@param pool string | string[]
---@param minutes number
function st.addCooldownToPool(pool, minutes)
    if type(minutes) ~= 'number' or minutes <= 0 then
        error(('minutes must be a number above 0. Received %s'):format(json.encode(minutes --[[@as unknown]])), 2)
    end

    local poolNames = normalizePoolNames(pool)
    local now = os.time()
    local durationSeconds = math.floor(minutes * 60)

    if durationSeconds < 1 then
        durationSeconds = 1
    end

    for i = 1, #poolNames do
        local poolName = poolNames[i]
        local expiresAt = cooldownPools[poolName] or 0

        if expiresAt < now then
            expiresAt = now
        end

        cooldownPools[poolName] = expiresAt + durationSeconds
    end
end

---@param pool string | string[]
---@return boolean
function st.IsPoolOnCooldown(pool)
    local poolNames = normalizePoolNames(pool)
    local now = os.time()

    for i = 1, #poolNames do
        local expiresAt = cooldownPools[poolNames[i]] or 0

        if expiresAt > now then
            return true
        end
    end

    return false
end