if not table.merge then
    st.require('table')
end

---@class FrameworkClass : table Framework class
---@field name string @FrameworkClass name
---@field object table  @FrameworkClass object
---@field player table @FrameworkClass player
local FrameworkClass = {
    name = "",
    object = {},
    player = {},
}

---@return FrameworkClass FrameworkClass class
function FrameworkClass:new(t)
    table.merge(self,t or {})
    self:init()
    return self
end

---@return void
function FrameworkClass:init()
    local name, object = self:get()
    while not name or table.isEmpty(object) do
        Citizen.Wait(1000)
        name, object = self:get()
    end

    self.name = name
    self.object = object

    if self.name == "" or table.isEmpty(self.object) then
        return
    end

    self.player = self:getPlayer()
end

---@return string Name of the frameworkt
---@return table Object of the framework
function FrameworkClass:get()
    if self.name ~= "" then 
        return self.name, self.object
    end

    if not table.isEmpty(self.object) then
        return self.name, self.object
    end
  
    if GetResourceState('es_extended') == "started" then
        self.name = "ESX"
        self.object = exports["es_extended"]:getSharedObject()
    elseif GetResourceState('qb-core') == "started" then
        self.name = "QB"
        self.object = exports["qb-core"]:GetCoreObject()
    end

    return self.name, self.object
end

---@return table Player data
function FrameworkClass:getPlayer()
    if not table.isEmpty(self.player) then
        return self.player
    end

    if self.name == "ESX" then
        return self.object.GetPlayerData()
    elseif self.name == "QB" then
        return self.object.Functions.GetPlayerData()
    end

    return nil
end

---@return string Job name
function FrameworkClass:GetJobName()
    if self.name == "ESX" then
        return self.player.job.name
    elseif self.name == "QB" then
        return self.player.job.name
    end

    return nil
end

---@return number Job grade
function FrameworkClass:GetJobGrade()
    if self.name == "ESX" then
        return self.player.job.grade
    elseif self.name == "QB" then
        return self.player.job.grade.level
    end

    return nil
end

---@return string Gang name
function FrameworkClass:GetGangName()
    if self.name == "QB" then
        return self.player.gang?.name
    end

    return nil
end

---@return number Gang grade
function FrameworkClass:GetGangGrade()
    if self.name == "QB" then
        return self.player.gang?.grade
    end

    return nil
end

---@param name string Name of the framework
---@return boolean
function FrameworkClass:is(name)
    return self:get() == name
end

if FrameworkClass:is("ESX") then
    RegisterNetEvent("esx:playerLoaded", function(xPlayer)
        self.player = xPlayer
    end)

    RegisterNetEvent("esx:onPlayerLogout", function()
        self.player = nil
    end)

    RegisterNetEvent("esx:setJob", function(job)
        self.player.job = job
    end)
end

if FrameworkClass:is("QB") then
    RegisterNetEvent("QBCore:Client:OnJobUpdate", function(JobInfo)
        self.player.job = JobInfo
    end)

    RegisterNetEvent("QBCore:Client:OnGangUpdate", function(GangInfo)
        self.player.gang = GangInfo
    end)

    RegisterNetEvent("QBCore:Client:SetDuty", function(duty)
        if self.player and self.player.job then
            self.player.job.onduty = duty
        end
    end)

    RegisterNetEvent("qb-clothes:client:CreateFirstCharacter", function()
        self.object.Functions.GetPlayerData(function(pd)
            self.player = pd
        end)
    end)
end

st.framework = FrameworkClass:new()
