st.require("framework-bridge")

local JobsCache = {
    data = {},
}

function JobsCache:new(t)
    t = table.copy(JobsCache)
    return t
end

function JobsCache:getJobCount(name)
    if not st.jobscache.data[name] then
        return 0
    end

    return st.jobscache.data[name]
end

st.jobscache = JobsCache:new()

if st.framework:is("ESX") then
    AddEventHandler('esx:setJob', function(source, job, lastJob)
        if st.jobscache.data[lastJob.name] then
            st.jobscache.data[lastJob.name] = st.jobscache.data[lastJob.name] - 1

            if st.jobscache.data[lastJob.name] < 0 then
                st.jobscache.data[lastJob.name] = nil
            end
        end
        
        if not st.jobscache.data[job.name] then
            st.jobscache.data[job.name] = 1
        else
            st.jobscache.data[job.name] = st.jobscache.data[job.name] + 1
        end
    end)

    AddEventHandler('esx:playerDropped', function(playerId)
        local user = st.User:get(playerId)
        if user and st.jobscache.data[user.getJob().name] then
            st.jobscache.data[user.getJob().name] = st.jobscache.data[user.getJob().name] - 1

            if st.jobscache.data[user.getJob().name] < 0 then
                st.jobscache.data[user.getJob().name] = nil
            end
        end
    end)

    AddEventHandler("esx:playerLoaded", function(_, xPlayer)
        if not st.jobscache.data[xPlayer.job.name] then
            st.jobscache.data[xPlayer.job.name] = 1
        else
            st.jobscache.data[xPlayer.job.name] = st.jobscache.data[xPlayer.job.name] + 1
        end
    end)
elseif st.framework:is("QB") then
    -- Todo: Implement QB Framework
end
