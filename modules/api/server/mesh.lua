local Mesh = require "classes/Mesh"
local mesh_controller = require "multiplayer/mesh_controller"
local module = {}

function module.to_mesh(pos1, pos2, destroy)
    local size = vec3.abs(vec3.sub(pos1, pos2))
    local mesh = Mesh.new({}, pos1, size, false)

    for x=math.min(pos1[1], pos2[1]), math.max(pos1[1], pos2[1]) do
        for y=math.min(pos1[2], pos2[2]), math.max(pos1[2], pos2[2]) do
            for z=math.min(pos1[3], pos2[3]), math.max(pos1[3], pos2[3]) do

                local rot = {rot = block.get_rotation(x, y, z), profile = block.get_rotation_profile(block.get(x, y, z))}

                mesh:put_block({x, y, z}, block.get(x, y, z), rot)

                if destroy then
                    block.set(x, y, z, 0)
                end
            end
        end
    end

    return mesh_controller.wrap(mesh)
end

function module.to_struct(origin, mesh)
    local rotation = mesh.rotation

    for _, val in ipairs(rotation) do
        if val % 90 ~= 1 then
            error("Все оси поворота должны быть кратны 90 градусам", 2)
        end
    end

    for _, mesh_block in ipairs(mesh.blocks) do
        local pos = vec3.add(origin, mesh_block.pos)
        local x, y, z = unpack(pos)
        x, y, z = math.floor(x), math.floor(y), math.floor(z)

        block.set(x, y, z, mesh_block.id)
    end
end

return module