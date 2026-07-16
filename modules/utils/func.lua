UTILS = {}

function UTILS.pos_to_num(pos)
    local x, y, z = pos[1], pos[2], pos[3]
    local ux = bit.band(x, 0xFFF)
    local uz = bit.band(z, 0xFFF)

    return bit.bor(
        bit.lshift(ux, 20),
        bit.lshift(y, 12),
        uz
    )
end

function UTILS.num_to_pos(n)
    local uz = bit.band(n, 0xFFF)
    local y  = bit.band(bit.rshift(n, 12), 0xFF)
    local ux = bit.band(bit.rshift(n, 20), 0xFFF)

    local x  = ux >= 2048 and (ux - 4096) or ux
    local z  = uz >= 2048 and (uz - 4096) or uz

    return { x, y, z }
end

local function mat4_mul(matrices)
    local result = mat4.idt()

    for _, matrix in ipairs(matrices) do
        result = mat4.mul(result, matrix)
    end

    return result
end

function UTILS.vec_to_mat(vector)
    local matrices = {}
    for pos, axis in ipairs(vector) do
        local vec = { 0, 0, 0 }

        if axis ~= 0 then
            vec[pos] = 1
            table.insert(matrices, mat4.rotate(vec, axis))
        end
    end

    return mat4_mul(matrices)
end

function UTILS.table_checksum(data)
    local hash = 5381
    local MAX_32 = 4294967296
    local uint24_mask = 16777216

    local function mix(val)
        hash = ((hash * 33) + val) % MAX_32
    end

    local function process(item)
        local t = type(item)

        if t == "number" then
            mix(1)
            local floor, frac = math.modf(item)
            mix(math.abs(floor) % MAX_32)
            mix(math.floor(math.abs(frac) * 1000000))
        elseif t == "string" then
            mix(2)
            for i = 1, #item do
                mix(string.byte(item, i))
            end
        elseif t == "boolean" then
            mix(3)
            mix(item and 1 or 0)
        elseif t == "table" then
            mix(4)
            local keys = {}
            for k in pairs(item) do
                local kt = type(k)
                if kt == "string" or kt == "number" or kt == "boolean" then
                    table.insert(keys, k)
                end
            end

            table.sort(keys, function(a, b)
                if type(a) ~= type(b) then
                    return type(a) < type(b)
                end
                return a < b
            end)

            for _, k in ipairs(keys) do
                process(k)
                process(item[k])
            end
        end
    end

    process(data)

    return hash % uint24_mask
end

function UTILS.vec3_chunk(vec)
    local x = math.floor(vec[1] / 16)
    local z = math.floor(vec[3] / 16)
    return x, z
end
