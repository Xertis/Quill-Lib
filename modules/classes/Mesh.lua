local mp = require "not_utils:main".multiplayer.api

local animation_player = require "animations/animation_player"
local animation_storage = require "animations/animation_storage"

local bit_buffer = require "not_utils:main".BitBuffer

local api = mp.server or mp.client
local bson = api.bson

local Mesh = {}
Mesh.__index = Mesh

local function __count_neighbors(x1, y1, z1, blocks)
    local count = 0

    local neighbor_offsets = {
        {x=1, y=0, z=0},
        {x=-1, y=0, z=0},
        {x=0, y=1, z=0},
        {x=0, y=-1, z=0},
        {x=0, y=0, z=1},
        {x=0, y=0, z=-1}
    }

    for _, offset in ipairs(neighbor_offsets) do
        local neighbor_pos = {
            x = x1 + offset.x,
            y = y1 + offset.y,
            z = z1 + offset.z
        }

        for _, block_data in ipairs(blocks) do
            local pos = block_data.pos
            if pos[1] == neighbor_pos.x and pos[2] == neighbor_pos.y and pos[3] == neighbor_pos.z then
                count = count + 1
                break
            end
        end
    end

    return count
end

function Mesh.new(blocks, origin, size, interpolated)
    local self = setmetatable({}, Mesh)
    self.blocks = {}
    self.invisible_blocks = {}
    self.struct_blocks = {}
    self.origin = origin
    self.size = size
    self.rotation = {}
    self.is_interpolated = interpolated or false
    self.entities = {}

    for _, block in ipairs(blocks or {}) do
        self:put_block(block.pos, block.id)
    end

    return self
end

function Mesh.frombytes(bytes)
    local data = bson.deserialize(
        compression.decode(bytes)
    )

    local mesh = Mesh.new(data.blocks, data.origin, data.size, true)
    mesh:set_rot(data.rotation)
    return mesh
end

function Mesh:__get_blocks_data()
    local data = {}
    for _, block in ipairs(self.blocks) do
        table.insert(data, {id = block.id, pos = block.pos})
    end
    return data
end

function Mesh:serialize()
    local blocks = self:__get_blocks_data()
    local rotation = self.rotation
    local data = {
        blocks = blocks,
        rotation = rotation,
        origin = self.origin,
        size = self.size
    }

    local non_compressed_data = bson.serialize(data)
    local compressed = compression.encode(non_compressed_data)

    return compressed
end

function Mesh:serialize_rotation()
    local buffer = bit_buffer:new()

    buffer:put_float32(self.rotation[1])
    buffer:put_float32(self.rotation[2])
    buffer:put_float32(self.rotation[3])

    return buffer.bytes
end

function Mesh:serialize_origin()
    local buffer = bit_buffer:new()

    buffer:put_float32(self.origin[1])
    buffer:put_float32(self.origin[2])
    buffer:put_float32(self.origin[3])

    return buffer.bytes
end

function Mesh:serialize_blocks_pos()
    local buffer = bit_buffer:new()
    buffer:put_uint32(#self.blocks)
    for _, block in ipairs(self.blocks) do
        local pos = block.pos
        buffer:put_float32(pos[1])
        buffer:put_float32(pos[2])
        buffer:put_float32(pos[3])
    end

    return compression.encode(buffer.bytes)
end

function Mesh:frombytes_rotation(bytes)
    local buffer = bit_buffer:new(bytes)
    self:set_rot({
        buffer:get_float32(),
        buffer:get_float32(),
        buffer:get_float32()
    })
end

function Mesh:frombytes_origin(bytes)
    local buffer = bit_buffer:new(bytes)
    local pos = {
        buffer:get_float32(),
        buffer:get_float32(),
        buffer:get_float32()
    }

    self:set_pos(pos)
end

function Mesh:frombytes_blocks_pos(bytes)
    local buffer = bit_buffer:new(compression.decode(bytes))
    local len = buffer:get_uint32()

    local blocks = self.blocks

    for i=1, len do
        blocks[i].pos = {
            buffer:get_float32(),
            buffer:get_float32(),
            buffer:get_float32(),
        }
    end
end

function Mesh:animation_play(animation)
    animation_player.play(animation_storage.get_animation(animation), self)
end

function Mesh:change_origin(pos)
    self.origin = pos

    for _, block in ipairs(self.blocks) do
        block.pos = vec3.sub(block.pos, pos)
    end
end

function Mesh:put_entity(uid)
    self.entities[uid] = entities.get(uid)
end

function Mesh:remove_entity(uid)
    self.entities[uid] = nil
end

function Mesh:__get_relative_pos(entity, pos)
    pos = pos or self.origin
    return vec3.sub(pos, entity.transform:get_pos())
end

function Mesh:set_config(config)
    self.is_obstacle = config.is_obstacle
    self.is_interpolated = config.is_interpolated
end

function Mesh:put_block(pos, id, rot)
    if id == -1 then
        return
    end

    table.insert(self.struct_blocks, {id = id})

    if id == 0 then
        return
    end

    local origin = self.origin
    local new_pos = vec3.sub(pos, origin)

    local entity = entities.spawn("meshup:phys_block", vec3.add(pos, 0.5),
            {meshup__phys_block={block=block.name(id)}})

    if rot then
        if ROTATIONS[rot.profile][rot.rot] then
            entity.transform:set_rot(ROTATIONS[rot.profile][rot.rot].rotation)
        end
    end

    entity.rigidbody:set_gravity_scale({0, 0, 0})
    table.insert(self.blocks, {
        id = id,
        pos = new_pos,
        entity = entity,
        base_rot = entity.transform:get_rot(),
        obstacle = {}
    })
end

function Mesh:set_pos(pos)
    local old_origin = self.origin
    self.origin = pos
    for _, block in ipairs(self.blocks) do
        local tsf = block.entity.transform

        tsf:set_pos(vec3.add(self.origin, block.pos))
    end

    for _, entity in ipairs(self.entities) do
        local tsf = entity.transform

        tsf:set_pos(vec3.add(self.origin, self:__get_relative_pos(entity, old_origin)))
    end
end

function Mesh:move(move)
    local pos = vec3.add(self.origin, move)
    self:set_pos(pos)
end

function Mesh:set_rot(rotation_vector)
    self.rotation = rotation_vector
    local rotation_matrix = mat4.vec_to_mat(rotation_vector)

    local translate_to_origin = mat4.translate(vec3.mul(self.origin, -1))
    local translate_back = mat4.translate(self.origin)
    local global_rot_matrix = mat4.mul(translate_back, mat4.mul(rotation_matrix, translate_to_origin))

    for _, block in ipairs(self.blocks) do
        local rotated_pos = mat4.mul(rotation_matrix, block.pos)

        local entity = block.entity
        local tsf = entity.transform
        local current_rot = block.base_rot
        local new_rot = mat4.mul(global_rot_matrix, current_rot)
        tsf:set_pos(vec3.add(self.origin, rotated_pos))
        tsf:set_rot(new_rot)
    end

    for _, entity in ipairs(self.entities) do
        local tsf = entity.transform
        local rotated_pos = mat4.mul(rotation_matrix, tsf:get_pos())

        local new_rot = mat4.mul(global_rot_matrix, tsf:get_rot())
        tsf:set_pos(vec3.add(self.origin, rotated_pos))
        tsf:set_rot(new_rot)
    end
end

function Mesh:remove_invisibles()
    local blocks_copy = table.copy(self.blocks)
    for id=#self.blocks, 1, -1 do
        local block_entity = self.blocks[id]
        local count = __count_neighbors(block_entity.pos[1], block_entity.pos[2], block_entity.pos[3], blocks_copy)

        if count > 5 then
            table.remove(self.blocks, id)

            block_entity.entity:despawn()
        end
    end
end

return Mesh