local Mesh = {}
Mesh.__index = Mesh

local sandbox = NEUTRON.sandbox
local __chunk_size = CHUNK_SIZE

local MESHES = {}

function Mesh.new(id, blocks, origin)
    local self = setmetatable({}, Mesh)
    self.id = id
    self.blocks = {}
    self.origin = origin
    self.rotation = { 0, 0, 0 }
    self.active = true

    for _, block in ipairs(blocks or {}) do
        self:put_block(block.pos)
    end

    MESHES[id] = self

    return self
end

--[[
self.blocks[unit_id] = {
    id = id,
    pos = pos,
    entity = entity,
    base_rot = entity.transform:get_rot(),
    local_pos = local_pos,
    logic = entity:require_component("meshup:block_logic")
}
]]

function Mesh:to_serialize()
    local mesh_tbl = {
        id = self.id,
        origin = self.origin,
        rotation = self.rotation,
        blocks = {}
    }

    for _, block in pairs(self.blocks) do
        mesh_tbl.blocks[#mesh_tbl.blocks + 1] = {
            id = block.id,
            uid = block.entity:get_uid(),
            base_rot = block.base_rot,
            local_pos = block.local_pos,
        }
    end

    return mesh_tbl
end

function Mesh:from_table(tbl)
    self.id = tbl.id
    self.origin = tbl.origin
    self.rotation = tbl.rotation
    self.blocks = {}

    for _, block in ipairs(tbl.blocks) do
        local unit_id = UTILS.pos_to_num(block.local_pos)
        local entity = entities.get(block.uid)
        self.blocks[unit_id] = {
            id = block.id,
            entity = entity,
            base_rot = block.base_rot,
            local_pos = block.local_pos,
            logic = entity:require_component("meshup:block_logic")
        }
    end
end

function Mesh.save()
    local save_tbl = {}
    for id, mesh in pairs(MESHES) do
        local str_id = tostring(id)

        save_tbl[str_id] = mesh:to_serialize()
    end

    local bytes = bjson.tobytes(save_tbl, true)
    file.write_bytes(MESHES_SAVING_FILE, bytes)
end

function Mesh.get_in_view(player)
    local in_view = {}
    for id, mesh in pairs(MESHES) do
        local chunk_x = math.floor(mesh.origin[1] / __chunk_size)
        local chunk_z = math.floor(mesh.origin[3] / __chunk_size)
        if sandbox.players.chunk_is_loaded(player, chunk_x, chunk_z) then
            in_view[id] = mesh
        end
    end
    return in_view
end

function Mesh.get(id)
    return MESHES[id]
end

function Mesh.remove(id)
    MESHES[id].active = false
    MESHES[id] = nil
end

function Mesh:in_view(player)
    local chunk_x = math.floor(self.origin[1] / __chunk_size)
    local chunk_z = math.floor(self.origin[3] / __chunk_size)
    return sandbox.players.chunk_is_loaded(player, chunk_x, chunk_z)
end

function Mesh:__get_blocks_data()
    local data = {}
    for _, block in pairs(self.blocks) do
        data[#data + 1] = { id = block.id, pos = block.pos }
    end
    return data
end

function Mesh:change_origin(pos)
    self.origin = pos

    for _, block in pairs(self.blocks) do
        block.pos = vec3.sub(block.pos, pos)
    end
end

function Mesh:get_unrotated_local_pos(block_world_pos)
    local current_rel_pos = vec3.sub(block_world_pos, self.origin)

    local rot_vec = self.rotation
    local rot_matrix = UTILS.vec_to_mat(rot_vec)
    local inv_rot_matrix = mat4.inverse(rot_matrix)

    local base_rel_pos = mat4.mul(inv_rot_matrix, current_rel_pos)

    return {
        math.floor(base_rel_pos[1]),
        math.floor(base_rel_pos[2]),
        math.floor(base_rel_pos[3])
    }
end

function Mesh:get_world_pos_and_rot(local_pos, base_rot)
    local rotation_matrix = UTILS.vec_to_mat(self.rotation)

    local rotated_pos = mat4.mul(rotation_matrix, local_pos)
    local world_pos = vec3.add(self.origin, rotated_pos)

    base_rot = base_rot or mat4.idt()

    local translate_to_origin = mat4.translate(vec3.mul(self.origin, -1))
    local translate_back = mat4.translate(self.origin)
    local global_rot_matrix = mat4.mul(translate_back, mat4.mul(rotation_matrix, translate_to_origin))

    local world_rot = mat4.mul(global_rot_matrix, base_rot)

    return world_pos, world_rot
end

function Mesh:update_block(unit_id, states)
    self.blocks[unit_id].logic.set_states(states)
end

function Mesh:remove_block(unit_id)
    if self.blocks[unit_id] then
        self.blocks[unit_id].entity:despawn()
        self.blocks[unit_id] = nil
    end
end

function Mesh:put_block(local_pos, id, states)
    states = states or 0
    if self.rotation[1] ~= 0 or self.rotation[2] ~= 0 or self.rotation[3] ~= 0 then
        error("Вращение должно быть нулевое")
    end

    if id == -1 or id == 0 then
        print(id, "такой айди нельзя вставить")
        return
    end

    local pos = self:get_world_pos_and_rot(local_pos)
    local unit_id = UTILS.pos_to_num(local_pos)

    local entity = entities.spawn("meshup:phys_block", pos,
        {
            meshup__block_logic = {
                id = id,
                unit_id = unit_id,
                mesh_id = self.id,
                local_pos = local_pos,
            },
            meshup__block_visuals = {
                id = id,
            },
        }
    )

    if self.blocks[unit_id] then
        self.blocks[unit_id].entity:despawn()
    end

    self.blocks[unit_id] = {
        id = id,
        pos = pos,
        entity = entity,
        base_rot = entity.transform:get_rot(),
        local_pos = local_pos,
        logic = entity:require_component("meshup:block_logic")
    }

    self:update_block(unit_id, states)

    return entity
end

function Mesh:__get_relative_pos(entity, pos)
    pos = pos or self.origin
    return vec3.sub(pos, entity.transform:get_pos())
end

function Mesh:set_pos(pos)
    self.origin = pos

    local rotation_matrix = UTILS.vec_to_mat(self.rotation)

    for _, block in pairs(self.blocks) do
        local rotated_pos = mat4.mul(rotation_matrix, block.local_pos)
        local tsf = block.entity.transform
        local new_pos = vec3.add(self.origin, rotated_pos)
        block.pos = new_pos
        tsf:set_pos(new_pos)
    end
end

function Mesh:move(move)
    local pos = vec3.add(self.origin, move)
    self:set_pos(pos)
end

function Mesh:get_states()
    local blocks = self.blocks
    local states = {}

    for unit_id, block in pairs(blocks) do
        states[unit_id] = block.logic.get_states()
    end

    return states
end

function Mesh:set_rot(rotation_vector)
    self.rotation = rotation_vector
    local rotation_matrix = UTILS.vec_to_mat(rotation_vector)

    for _, block in pairs(self.blocks) do
        local rotated_pos = mat4.mul(rotation_matrix, block.local_pos)
        local world_pos = vec3.add(self.origin, rotated_pos)
        local world_rot = mat4.mul(rotation_matrix, block.base_rot)

        block.pos = world_pos

        local tsf = block.entity.transform
        tsf:set_pos(world_pos)
        tsf:set_rot(world_rot)
    end
end


return Mesh
