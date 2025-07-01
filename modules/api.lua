local Mesh = require "classes/Mesh"
local module = {}

function module.to_entity(pos1, pos2)
    local size = vec3.abs(vec3.sub(pos1, pos2))
    local mesh = Mesh.new({}, pos1, size, false)

    for x=math.min(pos1[1], pos2[1]), math.max(pos1[1], pos2[1]) do
        for y=math.min(pos1[2], pos2[2]), math.max(pos1[2], pos2[2]) do
            for z=math.min(pos1[3], pos2[3]), math.max(pos1[3], pos2[3]) do

                local rot = {rot = block.get_rotation(x, y, z), profile = block.get_rotation_profile(block.get(x, y, z))}

                mesh:put_block({x, y, z}, block.get(x, y, z), rot)
            end
        end
    end

    return mesh
end

return module