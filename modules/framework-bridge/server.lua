st.require("table")
st.require("string")

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
    data = {}
}

---@return User
function User:get(source)
    self = table.copy(User)
    self.source = tonumber(source)
    self:init()
    return self
end

function User:init()
    if st.framework:is("ESX") then
        self.data = st.framework.object.GetPlayerFromId(self.source)
    elseif st.framework:is("QB") then
        self.data = st.framework.object.GetPlayer(self.source)
    end
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

---@return string Gang name
function User:getGang()
    if st.framework:is("QB") then
        return self.data.gang
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
    t = table.copy(FrameworkClass)
    t:init()
    return t
end

function FrameworkClass:init()
    if self:is("ESX") then
        bprint("ESX detected")
        self.object = exports["es_extended"]:getSharedObject()
        return
    elseif self:is("QB") then
        bprint("QB-Core detected")
        self.object = exports["qb-core"]:GetCoreObject()
        return
    end
    eprint("No compatible Framework detected. Please contact Stausi on discord")
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
                        bprint("Waiting start of " .. framework)
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

-------------
-- USER DATA
-------------

---@param source integer source ID
---@return table
function FrameworkClass:getUser(source)
    local user = User:get(source)
    return user
end

---@param source integer source ID
---@return table identifier
function FrameworkClass:getUserIdentifiers(source)
    local user = User:get(source)
    return user:getIdentifiers()
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