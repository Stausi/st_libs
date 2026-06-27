local maxProps = GetConvarInt('st:progressPropLimit', 2)

---@param props ProgressPropProps | ProgressPropProps[] | nil
RegisterNetEvent('st_lib:progressProps', function(props)
    local source = source

    if type(props) == 'table' then
        props = #props > maxProps and { table.unpack(props, 1, maxProps) } or props
    else
        props = nil
    end

    Player(source).state:set('st:progressProps', props, true)
end)