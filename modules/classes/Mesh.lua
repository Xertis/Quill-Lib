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

    self.loaded = true
    self.deferred_data = nil

    for _, block in ipairs(blocks or {}) do
        self:put_block(block.pos)
    end

    MESHES[id] = self

    return self
end

function Mesh:to_serialize()
    local mesh_tbl = {
        id = self.id,
        origin = self.origin,
        rotation = self.rotation,
        blocks = {}
    }

    for _, block in pairs(self.blocks) do
        if not block.segment_of then
            mesh_tbl.blocks[#mesh_tbl.blocks + 1] = {
                id = block.id,
                uid = block.entity:get_uid(),
                base_rot = block.base_rot,
                local_pos = block.local_pos,
            }
        end
    end

    return mesh_tbl
end

function Mesh:wakeup()
    local tbl = self.deferred_data
    if not tbl then return end

    self.id = tbl.id
    self.origin = tbl.origin
    self.rotation = tbl.rotation
    self.blocks = {}

    for _, block in ipairs(tbl.blocks) do
        local unit_id = UTILS.pos_to_num(block.local_pos)
        local entity = entities.get(block.uid)
        local logic = entity:require_component("meshup:block_logic")

        local rot = bit.band(logic.get_states() or 0, 7)
        local occupied = UTILS.get_occupied_cells(block.id, rot)

        local entry = {
            id = block.id,
            entity = entity,
            base_rot = block.base_rot,
            local_pos = block.local_pos,
            logic = logic,
            occupied = occupied,
            origin_unit_id = unit_id,
        }

        self.blocks[unit_id] = entry

        for _, offset in ipairs(occupied) do
            if offset[1] ~= 0 or offset[2] ~= 0 or offset[3] ~= 0 then
                local cell_pos = vec3.add(block.local_pos, offset)
                self.blocks[UTILS.pos_to_num(cell_pos)] = { segment_of = unit_id }
            end
        end
    end

    self.deferred_data = nil
    self.loaded = true
end

function Mesh.save()
    local save_tbl = {}
    for _, mesh in pairs(MESHES) do
        save_tbl[#save_tbl+1] = mesh:to_serialize()
    end

    local bytes = bjson.tobytes(
        {meshes = save_tbl},
    true)
    file.write_bytes(MESHES_SAVING_FILE, bytes)
end

function Mesh.load()
    if not file.exists(MESHES_SAVING_FILE) then
        return
    end

    local bytes = file.read_bytes(MESHES_SAVING_FILE)
    local save_tbl = bjson.frombytes(bytes).meshes

    for _, mesh_info in pairs(save_tbl) do
        local mesh = Mesh.new(mesh_info.id, {}, mesh_info.origin)
        mesh.loaded = false
        mesh.deferred_data = mesh_info
    end
end

function Mesh.get_in_view(player)
    local in_view = {}
    for id, mesh in pairs(MESHES) do
        local chunk_x = math.floor(mesh.origin[1] / __chunk_size)
        local chunk_z = math.floor(mesh.origin[3] / __chunk_size)
        if sandbox.players.chunk_is_loaded(player, chunk_x, chunk_z) then
            if not mesh.loaded then mesh:wakeup() end
            in_view[id] = mesh
        end
    end
    return in_view
end

function Mesh.get(id)
    return MESHES[id]
end

function Mesh.remove(id)
    local mesh = MESHES[id]
    mesh.active = false
    MESHES[id] = nil

    for _, block in pairs(mesh.block) do
        block.entity:despawn()
    end
end

function Mesh:get_block_entry(unit_id)
    local b = self.blocks[unit_id]
    if not b then return nil end
    if b.segment_of then
        return self.blocks[b.segment_of]
    end
    return b
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
    local entry = self:get_block_entry(unit_id)
    if entry then
        entry.logic.set_states(states)
    end
end

function Mesh:remove_block(unit_id)
    local entry = self:get_block_entry(unit_id)
    if not entry then return end

    for _, offset in ipairs(entry.occupied) do
        local cell_pos = vec3.add(entry.local_pos, offset)
        self.blocks[UTILS.pos_to_num(cell_pos)] = nil
    end

    entry.entity:despawn()
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
    local rot = bit.band(states, 7)
    local occupied = UTILS.get_occupied_cells(id, rot)

    local to_clear = {}
    for _, offset in ipairs(occupied) do
        local cell_pos = vec3.add(local_pos, offset)
        local cell_unit_id = UTILS.pos_to_num(cell_pos)
        local existing = self.blocks[cell_unit_id]
        if existing then
            local origin_id = existing.segment_of or cell_unit_id
            to_clear[origin_id] = true
        end
    end
    for origin_id in pairs(to_clear) do
        self:remove_block(origin_id)
    end

    local entity = entities.spawn("meshup:phys_block", pos,
        {
            meshup__block_logic = {
                id = id,
                unit_id = unit_id,
                mesh_id = self.id,
                local_pos = local_pos,
            },
            meshup__block_visuals = { id = id },
        }
    )

    local entry = {
        id = id,
        pos = pos,
        entity = entity,
        base_rot = entity.transform:get_rot(),
        local_pos = local_pos,
        logic = entity:require_component("meshup:block_logic"),
        occupied = occupied,
        origin_unit_id = unit_id,
    }

    self.blocks[unit_id] = entry

    for _, offset in ipairs(occupied) do
        if offset[1] ~= 0 or offset[2] ~= 0 or offset[3] ~= 0 then
            local cell_pos = vec3.add(local_pos, offset)
            local cell_unit_id = UTILS.pos_to_num(cell_pos)
            self.blocks[cell_unit_id] = { segment_of = unit_id }
        end
    end

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
        if not block.segment_of then
            local rotated_pos = mat4.mul(rotation_matrix, block.local_pos)
            local new_pos = vec3.add(self.origin, rotated_pos)
            block.pos = new_pos
            block.entity.transform:set_pos(new_pos)
        end
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
        if not block.segment_of then
            states[unit_id] = block.logic.get_states()
        end
    end

    return states
end

function Mesh:set_rot(rotation_vector)
    self.rotation = rotation_vector
    local rotation_matrix = UTILS.vec_to_mat(rotation_vector)

    for _, block in pairs(self.blocks) do
        if not block.segment_of then
            local rotated_pos = mat4.mul(rotation_matrix, block.local_pos)
            local world_pos = vec3.add(self.origin, rotated_pos)
            local world_rot = mat4.mul(rotation_matrix, block.base_rot)

            block.pos = world_pos

            local tsf = block.entity.transform
            tsf:set_pos(world_pos)
            tsf:set_rot(world_rot)
        end
    end
end


return Mesh
