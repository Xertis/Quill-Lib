local cache = {}

local function get_block(mesh, world_pos)
    local unrotated_pos = mesh:get_unrotated_local_pos(world_pos)
    local unit_id = UTILS.pos_to_num(unrotated_pos)
    local block = mesh:get_block_entry(unit_id)
    if not block then
        debug.print(world_pos)
        error("нет такого блока")
    end
    return block, block.local_pos
end

local function get_mesh(mesh, unit_id)
    if cache[string.format("%s|%s", mesh.id, unit_id)] then
        return cache[string.format("%s|%s", mesh.id, unit_id)]
    end

    local space_block = mesh.blocks[unit_id]
    local space = {
        kind = "mesh",

        get = function(pos)
            local block = (not pos) and space_block or get_block(mesh, pos)
            return block and block.id or -1
        end,

        set = function(pos, id, states)
            local local_pos = nil
            if not pos then
                local_pos = ({get_block(mesh, pos)})[2]
            else
                local_pos = space_block.local_pos
            end

            mesh:put_block(local_pos, id, states)
        end,

        get_states = function(pos)
            local block = (not pos) and space_block or get_block(mesh, pos)
            return block and block.logic.get_states() or 0
        end,

        set_states = function(pos, states)
            local block = (not pos) and space_block or get_block(mesh, pos)
            if block then
                block.logic.set_states(states)
            end
        end,

        get_rotation = function(pos)
            local block = (not pos) and space_block or get_block(mesh, pos)
            if not block then return 0 end

            local state = block.logic.get_states()
            return bit.band(state, 7)
        end,

        set_rotation = function(pos, rotation)
            local _block = (not pos) and space_block or get_block(mesh, pos)
            if not _block then return end

            local state = _block.logic.get_states()

            local _, segment, userbits = unpack(block.decompose_state(state))

            local new_state = block.compose_state({
                rotation,
                segment,
                userbits
            })

            _block.logic.set_states(new_state)
        end,

        get_user_bits = function(pos, offset, bits)
            local block = (not pos) and space_block or get_block(mesh, pos)
            if not block then return 0 end

            local state = block.logic.get_states()
            return bit.band(bit.rshift(state, offset + 5), bit.lshift(1, bits) - 1)
        end,

        set_user_bits = function(pos, offset, bits, value)
            local block = (not pos) and space_block or get_block(mesh, pos)
            if not block then return end

            local state = block.logic.get_states()

            local mask = bit.lshift(bit.lshift(1, bits) - 1, offset + 5)
            state = bit.band(state, bit.bnot(mask))
            state = bit.bor(state, bit.lshift(value, offset + 5))

            block.logic.set_states(state)
        end,
    }

    cache[string.format("%s|%s", mesh.id, unit_id)] = space

    return space
end

local world_api = {
    kind = "world",
    get = function(pos)
        return block.get(pos[1], pos[2], pos[3])
    end,
    set = function(pos, id, states)
        block.set(pos[1], pos[2], pos[3], id, states)
    end
}

return {
    get_mesh = get_mesh,
    get_world = function ()
        return world_api
    end
}
