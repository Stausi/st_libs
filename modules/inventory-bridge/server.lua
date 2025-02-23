local mainResourceInventory = {
    OX = { "ox_inventory" },
}

-------------
-- INVENTORY
-------------

---@class InventoryClass : table Inventory class
---@field name string @InventoryClass name
---@field object table  @InventoryClass object
local InventoryClass = {
    name = "",
    object = {},
}

---@return InventoryClass InventoryClass class
function InventoryClass:new(t)
    t = st.table.copy(InventoryClass)
    t:init()
    return t
end

function InventoryClass:init()
    if self:is("OX") then
        st.print.info("OX Inventory detected")
        self.object = exports["ox_inventory"]
        return
    end
    st.print.error("No compatible Inventory detected. Please contact Stausi on discord")
end

---@return string Name of the inventory
function InventoryClass:get()
    if self.name ~= "" then return self.name end

    for inventory, resources in pairs(mainResourceInventory) do
        local rightInventory = true
        for _, resource in pairs(resources) do
            if resource:sub(1, 1) == "!" then
                if GetResourceState(resource) ~= "missing" then
                    rightInventory = false
                    break
                end
            else
                if GetResourceState(resource) == "missing" then
                    rightInventory = false
                    break
                end
            end
        end

        if rightInventory then
            self.name = inventory
            for _, resource in pairs(resources) do
                if resource:sub(1, 1) ~= "!" then
                    while GetResourceState(resource) ~= "started" do
                        st.print.info("Waiting start of " .. inventory)
                        Wait(1000)
                    end
                end
            end
            return self.name
        end
    end

    return self.name
end

---@param name string Name of the inventory
---@return boolean
function InventoryClass:is(name)
    return self:get() == name
end

-------------
-- END INVENTORY
-------------

-------------
-- INVENTORY FUNCTIONS
-------------

function InventoryClass:Items()
    if self:is("OX") then
        return self.object.Items()
    end
    return {}
end

---@param inv table | string | integer
---@param item string
---@param count integer
---@param metadata? table
---@return boolean
function InventoryClass:GetItem(inv, item, metadata)
    if self:is("OX") then
        return self.object:GetItem(inv, item, metadata)
    end
    return nil
end

function InventoryClass:GetItemCount(inv, item, metadata)
    if self:is("OX") then
        return self.object:GetItem(inv, item, metadata, true)
    end
    return 0
end

---@param inv table | string | integer
---@param item string
---@param metadata? table
---@return table
function InventoryClass:GetInventoryItems(inv, item, metadata)
    if self:is("OX") then
        return self.object:Search(inv, "slots", item, metadata)
    end
    return nil
end

---@param inv table | string | integer
---@param item string
---@param metadata? table
---@return integer
function InventoryClass:GetInventoryItemsCount(inv, item, metadata)
    if self:is("OX") then
        return self.object:Search(inv, "count", item, metadata)
    end
    return nil
end

---@param inv table | string | integer
---@param item string
---@param count integer
---@param metadata? table
---@param slot? integer
---@return boolean
function InventoryClass:AddItem(inv, item, count, metadata, slot)
    if self:is("OX") then
        return self.object:AddItem(inv, item, count, metadata, slot)
    end
    return false
end

---@param inv table | string | integer
---@param item string
---@param count integer
---@param metadata? table
---@param slot? integer
---@return boolean
function InventoryClass:RemoveItem(inv, item, count, metadata, slot)
    if self:is("OX") then
        return self.object:RemoveItem(inv, item, count, metadata, slot)
    end
    return false
end

---@param inv table | string | integer
---@param item string
---@param count integer
---@param metadata? table
---@return boolean
function InventoryClass:CanCarryItem(inv, item, count, metadata)
    if self:is("OX") then
        return self.object:CanCarryItem(inv, item, count, metadata)
    end
    return false
end

st.inventory = InventoryClass:new()