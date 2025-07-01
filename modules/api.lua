local PhysBuild = require "classes/physics_build"
local module = {}

function module.to_entity(pos1, pos2)
    local size = vec3.abs(vec3.sub(pos1, pos2))
    local phys_block = PhysBuild.new({}, pos1, size, false)

    for x=math.min(pos1[1], pos2[1]), math.max(pos1[1], pos2[1]) do
        for y=math.min(pos1[2], pos2[2]), math.max(pos1[2], pos2[2]) do
            for z=math.min(pos1[3], pos2[3]), math.max(pos1[3], pos2[3]) do

                local rot = {rot = block.get_rotation(x, y, z), profile = block.get_rotation_profile(block.get(x, y, z))}

                phys_block:put_block({x, y, z}, block.get(x, y, z), rot)
            end
        end
    end

    return phys_block
end

return module