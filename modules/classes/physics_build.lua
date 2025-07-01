local PhysicsBuild = {}
PhysicsBuild.__index = PhysicsBuild

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

function PhysicsBuild.new(blocks, origin, size, interpolated, obstacle)
    local self = setmetatable({}, PhysicsBuild)
    self.blocks = {}
    self.origin = origin
    self.size = size
    self.is_interpolated = interpolated or false
    self.is_obstacle = obstacle or false
    self.entities = {}

    for _, block in ipairs(blocks or {}) do
        self:put_block(block.pos, block.id)
    end

    return self
end


function PhysicsBuild:put_entity(uid)
    self.entities[uid] = entities.get(uid)
end

function PhysicsBuild:remove_entity(uid)
    self.entities[uid] = nil
end

function PhysicsBuild:__obstacle_update()
    local obstacle_id = block.index("spatium:obstacle")

    local new_positions = {}
    for _, block_entity in ipairs(self.blocks) do
        local block_pos = block_entity.entity.transform:get_pos()
        local obstacle_pos = {
            math.floor(block_pos[1]),
            math.floor(block_pos[2]),
            math.floor(block_pos[3])
        }
        new_positions[obstacle_pos[1]..","..obstacle_pos[2]..","..obstacle_pos[3]] = true
    end

    for _, block_entity in ipairs(self.blocks) do
        local old_pos = block_entity.obstacle.old_pos
        if old_pos then
            local old_pos_key = old_pos[1]..","..old_pos[2]..","..old_pos[3]
            if not new_positions[old_pos_key] then
                block.set(old_pos[1], old_pos[2], old_pos[3], 0)
            end
        end
    end

    for _, block_entity in ipairs(self.blocks) do
        local block_pos = block_entity.entity.transform:get_pos()
        local obstacle_pos = {
            math.floor(block_pos[1] + 0.5),
            math.floor(block_pos[2] + 0.5),
            math.floor(block_pos[3] + 0.5)
        }
        block.set(obstacle_pos[1], obstacle_pos[2], obstacle_pos[3], obstacle_id)
        block_entity.obstacle.old_pos = obstacle_pos
    end
end

function PhysicsBuild:__get_relative_pos(entity, pos)
    pos = pos or self.origin
    return vec3.sub(pos, entity.transform:get_pos())
end

function PhysicsBuild:set_config(config)
    self.is_obstacle = config.is_obstacle
    self.is_interpolated = config.is_interpolated
end

function PhysicsBuild:put_block(pos, id, rot)
    if id == 0 or id == -1 then
        return
    end

    local origin = self.origin
    local new_pos = vec3.sub(pos, origin)

    local entity = entities.spawn("spatium:phys_block", vec3.add(pos, 0.5),
            {spatium__phys_block={block=block.name(id)}})

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

function PhysicsBuild:set_pos(pos)
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

    if not self.is_obstacle then
        return
    end

    self:__obstacle_update()
end

function PhysicsBuild:move(move)
    local pos = vec3.add(self.origin, move)
    self:set_pos(pos)

    if not self.is_obstacle then
        return
    end

    self:__obstacle_update()
end

function PhysicsBuild:set_rot(rotation_matrix)
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

    if not self.is_obstacle then
        return
    end

    self:__obstacle_update()
end

function PhysicsBuild:remove_invisibles()
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

return PhysicsBuild