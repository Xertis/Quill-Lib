-- Ивенты вешаем
local Mesh = require "classes/mesh"

local block_api = require "api/block"
local space = require "api/space"

local messages = require "net/messages"

local inddd = 0
messages.PhysStickSpawn:on(function(client, data)
    local pos = { data.x, data.y, data.z }
    local mesh = Mesh.new(inddd, {}, pos)

    inddd = inddd + 1

    local id = block.get(data.x, data.y, data.z)
    local states = block.get_states(data.x, data.y, data.z)
    block.set(data.x, data.y, data.z, 0)
    mesh:put_block({ 0, 0, 0 }, id, states)
end)

messages.MeshUse:on(function (client)
    local pid = client.player.pid
    local pos = vec3.add({ player.get_pos(pid) }, {0, 1, 0})
    local dir = player.get_dir(pid)
    local dist = player.get_interaction_distance(pid)
    local player_uid = player.get_entity(pid)

    local raycast = entities.raycast(
        pos,
        dir,
        dist,
        player_uid
    ) or {}

    if not raycast.entity then return end
    local entity = entities.get(raycast.entity)
    if entity:def_index() ~= PHYS_BLOCK_ID then return end

    local logic = entity:require_component("meshup:block_logic")
    local block_module = block_api.require(logic.get_id())

    local space_api = space.get_mesh(Mesh.get(logic.get_mesh_id()), logic.get_unit_id())

    local block_pos = entity.transform:get_pos()

    if not block_module.on_interact then return end

    block_module.on_interact(
        space_api,
        block_pos,
        client.player
    )
end)
