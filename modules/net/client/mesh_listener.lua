local Mesh = require "classes/mesh"
local messages = require "net/messages"

local MESHES = {}

messages.MeshSpawn:on(function(data)
    MESHES[data.mesh_id] = Mesh.new(data.mesh_id, {}, data.origin)
end)

messages.MeshPutBlock:on(function(data)
    local mesh_id = data.mesh_id
    local block = data.block
    local mesh = MESHES[mesh_id]

    local local_pos = {
        block.local_pos.x,
        block.local_pos.y,
        block.local_pos.z
    }

    mesh:put_block(
        local_pos,
        block.id
    )
end)

messages.MeshUpdate:on(function(data)
    local mesh_id = data.mesh_id
    local mesh = MESHES[mesh_id]
    if not mesh then
        mesh = Mesh.new(mesh_id, {}, { 0, 0, 0 })
        MESHES[mesh_id] = mesh
    end

    for _, info in ipairs(data.dirty) do
        local unit_id = info[1]
        local action = info[2]

        local states = (info[3] or {})[1]
        local block_id = (info[3] or {})[2]

        if action == BLOCK_PUSHED then
            mesh:put_block(
                UTILS.num_to_pos(unit_id),
                block_id,
                states
            )
        elseif action == BLOCK_UPDATED then
            mesh:update_block(unit_id, states)
        elseif action == BLOCK_REMOVED then
            mesh:remove_block(unit_id)
        end
    end
end)

messages.MeshMoved:on(function (data)
    local mesh_id = data.mesh_id
    local mesh = MESHES[mesh_id]

    mesh:set_pos(data.pos)
end)
