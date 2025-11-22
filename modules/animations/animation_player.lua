local module = {}
local to_play = {}

local function get_end(steps)
    local end_time = 0
    local end_val = nil

    if not steps then return end

    for time, val in pairs(steps) do
        time = tonumber(time)
        if end_time < time then
            end_time = time
            end_val = val
        end
    end

    return end_val, end_time
end

local function get_next(cur_time, steps)
    local near_diff = math.huge
    local near_time = nil
    local near = nil

    if not steps then return end

    for time, val in pairs(steps) do
        time = tonumber(time)
        local diff = time - cur_time
        if diff >= 0 then
            if diff < near_diff then
                near_diff = diff
                near_time = time
                near = val
            end
        end
    end

    return near, near_time
end

local function get_last(cur_time, steps)
    if not steps then return nil end

    local nearest_time = -math.huge
    local nearest_val = nil

    for time, val in pairs(steps) do
        time = tonumber(time)
        if time < cur_time and time > nearest_time then
            nearest_time = time
            nearest_val = val
        end
    end

    return nearest_val, nearest_time
end

function module.play(animation, mesh)
    table.insert(to_play, {animation = animation, mesh = mesh, time_start = time.uptime(), origin = table.copy(mesh.origin)})
end

function module.tick()
    for id, anim in ipairs(to_play) do
        local animation = anim.animation
        local mesh = anim.mesh
        local origin = anim.origin
        local time_start = anim.time_start
        local position = time.uptime() - time_start

        if position >= animation.length then
            table.remove(to_play, id)
            goto continue
        end

        local next_rot, next_time_rot = get_next(position, animation.animation.rotation)
        local last_rot, last_time_rot = get_last(position, animation.animation.rotation)

        if not next_rot and last_rot then
            next_rot, next_time_rot = get_end(animation.animation.rotation)
        end

        local cur_rot
        if last_rot and next_rot then
            local interpolation_rot_coef = math.delta(last_time_rot, position, next_time_rot)
            cur_rot = interpolation.lerp(last_rot, next_rot, interpolation_rot_coef)
        elseif last_rot then
            cur_rot = last_rot
        elseif next_rot then
            local interpolation_rot_coef = math.delta(0, position, next_time_rot)
            cur_rot = interpolation.lerp({0, 0, 0}, next_rot, interpolation_rot_coef)
        else
            cur_rot = {0, 0, 0}
        end

        local next_pos, next_time_pos = get_next(position, animation.animation.position)
        local last_pos, last_time_pos = get_last(position, animation.animation.position)

        if not next_pos and last_pos then
            next_pos, next_time_pos = get_end(animation.animation.position)
        end

        local cur_pos
        if last_pos and next_pos then
            local interpolation_pos_coef = math.delta(last_time_pos, position, next_time_pos)
            cur_pos = interpolation.lerp(last_pos, next_pos, interpolation_pos_coef)
        elseif last_pos then
            cur_pos = last_pos
        elseif next_pos then
            local interpolation_pos_coef = math.delta(0, position, next_time_pos)
            cur_pos = interpolation.lerp({0, 0, 0}, next_pos, interpolation_pos_coef)
        else
            cur_pos = {0, 0, 0}
        end

        mesh:set_pos(vec3.sub(origin, cur_pos), true)
        mesh:set_rot(cur_rot, true)
        ::continue::
    end
end

return module