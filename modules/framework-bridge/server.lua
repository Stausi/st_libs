local mainResourceFramework = {
    ESX = { "es_extended" },
    QB = { "qb-core" },
}

-------------
-- USER CLASS
-------------

---@class User : table User class
---@field source integer source ID
local User = {
    source = 0,
    identifier = "",
    data = {}
}

---@param source integer source ID
---@return User
function User:get(source)
    self = st.table.copy(User)
    self.source = tonumber(source)
    self:init()
    self.identifier = self:getPlayerIdentifier()
    return self
end

function User:init()
    if st.framework:is("ESX") then
        self.data = st.framework.object.GetPlayerFromId(self.source)
    elseif st.framework:is("QB") then
        self.data = st.framework.object.GetPlayer(self.source)
    end
end

---@param identifier string Player identifier
---@return User
function User:getByIdentifier(identifier)
    self = st.table.copy(User)
    self.identifier = identifier
    self:initByIdentifier()
    return self
end

function User:initByIdentifier()
    if st.framework:is("ESX") then
        self.data = st.framework.object.GetPlayerFromIdentifier(self.identifier)
    elseif st.framework:is("QB") then
        self.data = st.framework.object.GetPlayerByCitizenId(self.identifier)
    end
end

function User:IsOnline()
    return self.data ~= nil
end

---@param moneyType string cash, bank, default: money
---@return integer
function User:getMoney(moneyType)
    if not moneyType then 
        moneyType = "cash" 
    end

    if st.framework:is("ESX") then
        return self.data.getAccount(moneyType)?.money or 0
    elseif st.framework:is("QB") then
        return self.data.money[moneyType] or 0
    end

    return 0
end

---@param moneyType string cash, bank, default: cash
---@param money integer
---@return boolean
function User:HasMoney(moneyType, money)
    return self:getMoney(moneyType) >= money
end

---@param moneyType string cash, bank, default: cash
---@param money integer
---@return boolean
function User:RemoveMoney(moneyType, money)
    if self:HasMoney(moneyType, money) then
        if st.framework:is("ESX") then
            self.data.removeAccountMoney(moneyType, money)
        elseif st.framework:is("QB") then
            self.data.RemoveMoney(moneyType, money)
        end
        return true
    end

    return false
end

---@param moneyType string cash, bank, default: cash
---@param money integer
---@return boolean
function User:addMoney(moneyType, money)
    if st.framework:is("ESX") then
        self.data.addAccountMoney(moneyType, money)
    elseif st.framework:is("QB") then
        self.data.addMoney(moneyType, money)
    end
end

---@return string Player Job
function User:getJob()
    if st.framework:is("ESX") then
        return self.data.getJob()
    elseif st.framework:is("QB") then
        return self.data.job
    end

    return nil
end

function User:getPlayerIdentifier()
    if not self.data then 
        return nil
    end

    if st.framework:is("ESX") then
        return self.data.identifier
    elseif st.framework:is("QB") then
        return self.data.citizenid
    end
  
    return nil
end

function User:getRPName()
    if not self.data then 
        return "Unknown"
    end

    if st.framework:is("ESX") then
        if self.data.get and self.data.get("firstName") and self.data.get("lastName") then
            return self.data.get("firstName") .. " " .. self.data.get("lastName")
        end
    elseif st.framework:is("QB") then
        return self.data.firstname .. " " .. self.data.lastname
    end

    return "Unknown"
end

function User:getJob()
    if st.framework:is("ESX") then
        return self.data.job
    elseif st.framework:is("QB") then
        return self.data.job
    end
    return nil
end

---@param name string Job name
---@param grade integer Job grade
function User:setJob(name, grade)
    if st.framework:is("ESX") then
        self.data.setJob(name, grade)
    elseif st.framework:is("QB") then
    end
end

---@return string Gang name
function User:getGang()
    if st.framework:is("QB") then
        return self.data.gang
    end

    return nil
end

---@return string Job name
function User:getJobName()
    if st.framework:is("ESX") then
        return self.data.job.name
    elseif st.framework:is("QB") then
        return self.data.job
    end
    return nil
end

---@return string Job grade name
function User:getGradeName()
    if st.framework:is("ESX") then
        return self.data.job.grade_name
    elseif st.framework:is("QB") then
        return self.data.job
    end
    return nil
end

---@return string Player Name
function User:getPhoneNumber()
    if st.framework:is("ESX") then
        return self.data.phoneNumber
    elseif st.framework:is("QB") then
        return self.data.phone_number
    end
    return nil
end

---@param item string Item name
---@param count integer Item count
---@param metadata? table Item metadata
---@return table Identifiers
function User:CanCarryItem(item, count, metadata)
    return st.inventory:CanCarryItem(self.source, item, count, metadata)
end

---@param item string Item name
---@param metadata? table Item metadata
---@return table Item
function User:GetItem(item, metadata)
    return st.inventory:GetItem(self.source, item, metadata)
end

---@param item string Item name
---@param metadata? table Item metadata
---@return integer Item count
function User:GetItemCount(item, metadata)
    return st.inventory:GetItemCount(self.source, item, metadata)
end

---@param item string Item name
---@param metadata? table Item metadata
---@return table Items
function User:GetInventoryItems(item, metadata)
    return st.inventory:GetInventoryItems(self.source, item, metadata)
end

---@param item string Item name
---@param metadata? table Item metadata
---@return integer Item count
function User:GetInventoryItemsCount(item, metadata)
    return st.inventory:GetInventoryItemsCount(self.source, item, metadata)
end

---@param item string Item name
---@param count integer Item count
---@param metadata? table Item metadata
---@param slot? integer Item slot
---@return boolean
function User:AddItem(item, count, metadata, slot)
    return st.inventory:AddItem(self.source, item, count, metadata, slot)
end

---@param item string Item name
---@param count integer Item count
---@param metadata? table Item metadata
---@param slot? integer Item slot
---@return boolean
function User:RemoveItem(item, count, metadata, slot)
    return st.inventory:RemoveItem(self.source, item, count, metadata, slot)
end

st.User = User

-------------
-- END USER CLASS
-------------

-------------
-- FRAMEWORK CLASS
-------------

---@class FrameworkClass : table Framework class
---@field name string @FrameworkClass name
---@field object table  @FrameworkClass object
local FrameworkClass = {
    name = "",
    object = {},
}

---@return FrameworkClass FrameworkClass class
function FrameworkClass:new(t)
    t = st.table.copy(FrameworkClass)
    t:init()
    return t
end

function FrameworkClass:init()
    if self:is("ESX") then
        st.print.info("ESX detected")
        self.object = exports["es_extended"]:getSharedObject()
        return
    elseif self:is("QB") then
        st.print.info("QB-Core detected")
        self.object = exports["qb-core"]:GetCoreObject()
        return
    end
    st.print.error("No compatible Framework detected. Please contact Stausi on discord")
end

---@return string Name of the framework
function FrameworkClass:get()
    if self.name ~= "" then return self.name end
  
    for framework, resources in pairs(mainResourceFramework) do
        local rightFramework = true
        for _, resource in pairs(resources) do
            if resource:sub(1, 1) == "!" then
                if GetResourceState(resource) ~= "missing" then
                    rightFramework = false
                    break
                end
            else
                if GetResourceState(resource) == "missing" then
                    rightFramework = false
                    break
                end
            end
        end

        if rightFramework then
            self.name = framework
            for _, resource in pairs(resources) do
                if resource:sub(1, 1) ~= "!" then
                    while GetResourceState(resource) ~= "started" do
                        st.print.info("Waiting start of " .. framework)
                        Wait(1000)
                    end
                end
            end
            return self.name
        end
    end

    return self.name
end

---@param name string Name of the framework
---@return boolean
function FrameworkClass:is(name)
    return self:get() == name
end

function FrameworkClass:getPlayers()
    if self:is("ESX") then
        return self.object.GetPlayers()
    elseif self:is("QB") then
        return self.object.GetPlayers()
    end
    return {}
end

function FrameworkClass:getJobs()
    if self:is("ESX") then
        return self.object.GetJobs()
    elseif self:is("QB") then
        return self.object.GetJobs()
    end
    return {}
end

function FrameworkClass:getJobData(name)
    local jobs = self:getJobs()
    for _, job in pairs(jobs) do
        if job.name == name then
            return job
        end
    end
    return nil
end

function FrameworkClass:refreshJob(name)
    if self:is("ESX") then
        if not self.object.RefreshJob then
            return st.print.error("RefreshJob not found in ESX. Please read the docs at https://docs.stausi.com/")
        end

        self.object.RefreshJob(name)
    elseif self:is("QB") then
        self.object.RefreshJob(name)
    end
end

-------------
-- USER DATA
-------------

---@param source integer source ID
---@return table
function FrameworkClass:getUser(source)
    local user = User:get(source)
    return user
end

---@param identifier string Player identifier
---@return table
function FrameworkClass:getUserByIdentifier(identifier)
    local user = User:getByIdentifier(identifier)
    return user
end

---@param source integer source ID
---@return table identifier
function FrameworkClass:getUserIdentifier(source)
    local user = User:get(source)
    return user:getPlayerIdentifier()
end

---@param source integer source ID
---@return string job Player job
function FrameworkClass:getJob(source)
    local user = User:get(source)
    return user:getJob()
end

function FrameworkClass:getGang(source)
    local user = User:get(source)
    return user:getGang()
end
  
-------------
-- END USER DATA
-------------

-------------
-- MONEY
-------------

---@param source integer
---@param amount number
---@param moneyType string cash, bank, default: cash
---@param removeIfCan? boolean (optinal) default : false
---@return boolean
function FrameworkClass:canUserBuy(source, amount, moneyType, removeIfCan)
    local user = User:get(source)
    return user:HasMoney(amount, moneyType, removeIfCan)
end

---@param source integer
---@param amount number
---@param moneyType string cash, bank, default: cash
function FrameworkClass:addMoney(source, amount, moneyType)
    local user = User:get(source)
    user:addMoney(amount, moneyType or 0)
end

-------------
-- END MONEY
-------------

st.framework = FrameworkClass:new()

if st.framework:is("ESX") then
    RegisterNetEvent("esx:setJob", function(source, newJob, lastJob)
        st.hook.doActions("setJob", source, newJob, lastJob)
        local user = st.framework:getUser(source)
        user.data.job = newJob
    end)

    RegisterNetEvent("esx:playerLoaded", function(playerId)
        st.hook.doActions("playerLoaded", playerId)
    end)

    RegisterNetEvent("esx:playerDropped", function(playerId)
        st.hook.doActions("playerDropped", playerId)
    end)
elseif st.framework:is("QB") then
end

return st.framework