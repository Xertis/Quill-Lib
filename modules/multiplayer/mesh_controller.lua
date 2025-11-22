local mp = require "not_utils:main".multiplayer.api.server
local bit_buffer = require "not_utils:main".BitBuffer

local module = {}
local meshes = {}

local function concat(id, bytes)
    local buf = bit_buffer:new()

    buf:put_uint32(id)
    buf:put_bytes(bytes)

    return buf.bytes
end

local function parse(bytes)
    local buf = bit_buffer:new(bytes)
    local id = tohex(buf:get_uint32())

    local parsed_bytes = Bytearray()
    for i=5, #bytes do
        parsed_bytes:append(bytes[i])
    end

    return id, parsed_bytes
end

module.concat = concat
module.parse = parse

function module.wrap(mesh)
    local set_pos = mesh.set_pos
    local set_rot = mesh.set_rot
    local change_origin = mesh.change_origin
    local animation_play = mesh.animation_play
    local id = table.count_pairs(meshes)

    local hexed_id = tohex(id)

    mesh.is_registered = true

    mesh.set_pos = function (self, pos, is_animation)
        set_pos(self, pos)
        if not is_animation and self.is_registered then
            local bytes = mesh:serialize_origin()
            mp.events.echo(PACK_ID, PROTOCOL.set_pos, concat(id, bytes))
        end
    end

    mesh.set_rot = function (self, rot, is_animation)
        set_rot(self, rot)
        if not is_animation and self.is_registered then
            local bytes = mesh:serialize_rotation()
            mp.events.echo(PACK_ID, PROTOCOL.set_rot, concat(id, bytes))
        end
    end

    mesh.change_origin = function (self, pos)
        change_origin(self, pos)
        if self.is_registered then
            local buf = bit_buffer:new()
            buf:put_float32(pos[1])
            buf:put_float32(pos[2])
            buf:put_float32(pos[3])

            mp.events.echo(PACK_ID, PROTOCOL.change_origin, concat(id, buf.bytes))
        end
    end

    -- function Mesh:animation_play(animation)
    --     animation_player.play(animation_storage.get_animation(animation), self)
    -- end

    mesh.animation_play = function (self, animation)
        animation_play(self, animation)
        mp.events.echo(PACK_ID, PROTOCOL.animation_play, mp.bson.serialize({
            id = id,
            animation = animation
        }))
    end

    mesh.unreg = function (self)
        self.is_registered = false
        meshes[hexed_id] = nil
        mp.events.echo(PACK_ID, PROTOCOL.unreg, concat(id, {}))
    end

    meshes[hexed_id] = mesh

    mp.events.echo(PACK_ID, PROTOCOL.spawn, concat(id, mesh:serialize()))

    return mesh
end

return module