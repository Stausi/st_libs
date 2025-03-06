local mainResourceFramework = {
    ESX = { "es_extended" },
    QB = { "qb-core" },
}

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
    st.table.merge(self,t or {})
    self:init()
    return self
end

---@return void
function FrameworkClass:init()
    self.name = self:get()

    if self.name == "ESX" then
        self.object = exports["es_extended"]:getSharedObject()
    elseif self.name == "QB" then
        self.object = exports["qb-core"]:GetCoreObject()
    end

    self.player = self:getPlayer()
end

---@return string Name of the frameworkt
---@return table Object of the framework
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

---@return string Job grade name
function FrameworkClass:GetGradeName()
    if self.name == "ESX" then
        return self.player.job.grade_name
    elseif self.name == "QB" then
        return self.player.job.grade.name
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

st.framework = FrameworkClass:new()

if st.framework:is("ESX") then
    RegisterNetEvent("esx:playerLoaded", function(xPlayer)
        st.framework.player = xPlayer
        st.hook.doActions("playerLoaded")
    end)

    RegisterNetEvent("esx:onPlayerLogout", function()
        st.framework.player = nil
        st.hook.doActions("onPlayerLogout")
    end)

    RegisterNetEvent("esx:setJob", function(newJob)
        st.framework.player.job = newJob
        st.hook.doActions("setJob", newJob)
    end)
end

if st.framework:is("QB") then
    RegisterNetEvent("QBCore:Client:OnJobUpdate", function(JobInfo)
        st.framework.player.job = JobInfo
        st.hook.doActions("setJob", JobInfo)
    end)

    RegisterNetEvent("QBCore:Client:OnGangUpdate", function(GangInfo)
        st.framework.player.gang = GangInfo
    end)

    RegisterNetEvent("QBCore:Client:SetDuty", function(duty)
        if st.framework.player and st.framework.player.job then
            st.framework.player.job.onduty = duty
        end
    end)

    RegisterNetEvent("qb-clothes:client:CreateFirstCharacter", function()
        st.framework.object.Functions.GetPlayerData(function(pd)
            st.framework.player = pd
        end)
    end)
end

return st.framework
