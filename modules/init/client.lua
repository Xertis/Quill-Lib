local _mp = require "not_utils:main".multiplayer
local mesh_controller = require "multiplayer/mesh_controller"
local Mesh = require "classes/Mesh"

local mp = _mp.api.client
local mode = _mp.mode

local meshes = {}

mp.entities.desync(PACK_ID .. ":phys_block")

if mode ~= "standalone" then
    mp.events.on(PACK_ID, PROTOCOL.spawn, function (data)
        local id, bytes = mesh_controller.parse(data)
        print("спавним с айди", id)
        meshes[id] = Mesh.frombytes(bytes)
    end)

    mp.events.on(PACK_ID, PROTOCOL.unreg, function (data)
        local id, bytes = mesh_controller.parse(data)
        -- TODO: Реализовать удаление мэшей
    end)

    mp.events.on(PACK_ID, PROTOCOL.set_rot, function (data)
        local id, bytes = mesh_controller.parse(data)
        meshes[id]:frombytes_rotation(bytes)
    end)

    mp.events.on(PACK_ID, PROTOCOL.set_pos, function (data)
        local id, bytes = mesh_controller.parse(data)
        print("телепортируем с айди", id)
        meshes[id]:frombytes_origin(bytes)
    end)

    mp.events.on(PACK_ID, PROTOCOL.change_origin, function (data)
        local id, bytes = mesh_controller.parse(data)
        meshes[id]:frombytes_blocks_pos(bytes)
    end)

    mp.events.on(PACK_ID, PROTOCOL.animation_play, function (bytes)
        local data = mp.bson.deserialize(bytes)
        print(data.animation)
        meshes[tohex(data.id)]:animation_play(data.animation)
    end)
end