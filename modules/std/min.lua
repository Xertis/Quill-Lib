function block.count_neighbors(x1, y1, z1)
    local count = 0

    local directions = {
        {x=1, y=0, z=0},
        {x=-1, y=0, z=0},
        {x=0, y=1, z=0},
        {x=0, y=-1, z=0},
        {x=0, y=0, z=1},
        {x=0, y=0, z=-1}
    }

    for _, dir in ipairs(directions) do
        local x = x1 + dir.x
        local y = y1 + dir.y
        local z = z1 + dir.z

        if not table.has({0, -1}, block.get(x, y, z)) then
            count = count + 1
        end
    end

    return count
end


interpolation = {}
function interpolation.by_velocity(current_pos, target_pos, time_to_reach)
    local direction = vec3.sub(target_pos, current_pos)
    local distance = vec3.length(direction)

    if distance > 10 or distance < 0.01 then
        return false
    else
        local velocity = vec3.mul(vec3.normalize(direction), distance / time_to_reach)
        return velocity
    end
end

function interpolation.lerp(a, b, delta)
    delta = math.clamp(delta, 0, 1)

    local diff = vec3.sub(b, a)
    local scaledDiff = vec3.mul(diff, delta)
    return vec3.add(a, scaledDiff)
end

function table.keys(tbl)
    local keys = {}

    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end

    return keys
end

function math.delta(a, cur, b)
    return (cur - a) / (b - a)
end

function vec3.map(vec, func)
    return {
        func(vec[1]),
        func(vec[2]),
        func(vec[3])
    }
end

local function mat4_mul(matrices)
    local result = mat4.idt()

    for _, matrix in ipairs(matrices) do
        result = mat4.mul(result, matrix)
    end

    return result
end

function mat4.vec_to_mat(vector)
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