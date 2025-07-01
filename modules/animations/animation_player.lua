local module = {}
local to_play = {}

local function mat4_mul(matrices)
    local result = mat4.idt()

    for _, matrix in ipairs(matrices) do
        result = mat4.mul(result, matrix)
    end

    return result
end

local function vec_to_mat4(vector)
    local matrices = {}
    for pos, axis in ipairs(vector) do
        local vec = {0, 0, 0}

        if axis ~= 0 then
            vec[pos] = 1
            table.insert(matrices, mat4.rotate(vec, axis))
        end
    end

    return mat4_mul(matrices)
end

local function get_next(cur_time, steps)
    local near_diff = math.huge
    local near_time = nil
    local near = nil

    for time, val in pairs(steps) do
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
    local last_diff = 0
    local last_time = nil
    local last = nil

    for time, val in pairs(steps) do
        local diff = time - cur_time
        if diff <= 0 then
            diff = math.abs(diff)
            if diff > last_diff then
                last_diff = diff
                last_time = time
                last = val
            end
        end
    end

    return last, last_time
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

        local cur_rot
        if last_rot and next_rot then

            local interpolation_rot_coef = math.delta(last_time_rot, position, next_time_rot)
            cur_rot = interpolation.lerp(last_rot.vector, next_rot.vector, interpolation_rot_coef)
        elseif last_rot then
            cur_rot = last_rot.vector
        elseif next_rot then
            cur_rot = next_rot.vector
        else
            cur_rot = {0, 0, 0}
        end

        local next_pos, next_time_pos = get_next(position, animation.animation.position)
        local last_pos, last_time_pos = get_last(position, animation.animation.position)

        local cur_pos
        if last_pos and next_pos then
            local interpolation_pos_coef = math.delta(last_time_pos, position, next_time_pos)
            cur_pos = interpolation.lerp(last_pos.vector, next_pos.vector, interpolation_pos_coef)
        elseif last_pos then
            cur_pos = last_pos.vector
        elseif next_pos then
            cur_pos = next_pos.vector
        else
            cur_pos = {0, 0, 0}
        end

        mesh:set_pos(vec3.sub(origin, cur_pos))
        mesh:set_rot(vec_to_mat4(cur_rot))
        ::continue::
    end
end

return module