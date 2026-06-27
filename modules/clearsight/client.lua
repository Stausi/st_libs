-- Line-of-sight (LOS) check from the local player's eyes to a coord.
-- Returns: boolean hasClearLOS, table hitInfo (only populated when blocked)
--
-- Options (all optional):
--   ignoreEntity = entity to ignore in the ray (defaults to PlayerPedId())
--   includeVehicles = true/false (default false)
--   includePeds     = true/false (default false)
--   includeObjects  = true/false (default true)
--   includeMap      = true/false (default true)
--   includeWater    = true/false (default false)
--   debug           = true/false (default false; draws a line)
--
-- hitInfo fields when blocked:
--   endCoords, normal, entityHit
function st.HasClearLineOfSightToCoord(targetCoords, opts)
    opts = opts or {}

    local ped = PlayerPedId()
    local ignoreEntity = opts.ignoreEntity or ped

    -- Build shape-test flags (bitmask)
    -- 1 = Map, 2 = Vehicles, 4 = Peds, 8 = Objects, 16 = Water
    local flags = 0
    if (opts.includeMap ~= false) then flags = flags | 1  end
    if (opts.includeVehicles == true) then flags = flags | 2  end
    if (opts.includePeds == true) then flags = flags | 4  end
    if (opts.includeObjects ~= false) then flags = flags | 8  end
    if (opts.includeWater == true) then flags = flags | 16 end
    if flags == 0 then flags = 1 | 8 end -- sensible minimum: map + objects

    -- Ray origin from player's head (bone 31086) for more realistic LOS
    local eye = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
    local sx, sy, sz = eye.x, eye.y, eye.z
    local ex, ey, ez = targetCoords.x, targetCoords.y, targetCoords.z

    -- Cast the ray
    local ray = StartShapeTestRay(sx, sy, sz, ex, ey, ez, flags, ignoreEntity, 7)
    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)

    if opts.debug then
        -- Green if clear, red if blocked
        local r, g, b = (hit == 0) and 0 or 255, (hit == 0) and 255 or 0, 0
        DrawLine(sx, sy, sz, ex, ey, ez, r, g, b, 200)
        if hit ~= 0 and endCoords then
            DrawMarker(1, endCoords.x, endCoords.y, endCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, 0.1, 255, 0, 0, 200, false, false, 2, nil, nil, false)
        end
    end

    if hit == 0 then
        return true, nil
    else
        return false, {
            endCoords = endCoords,
            normal = surfaceNormal,
            entityHit = entityHit
        }
    end
end

return st.HasClearLineOfSightToCoord
