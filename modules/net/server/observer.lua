local module = {}

local Mesh = require "classes/mesh"
local messages = require "net/messages"
local sandbox = NEUTRON.sandbox
local PLAYERS_META = {}

--[[
action:
    0 - блок заспавнили
    1 - блок удалили
    2 - блок изменили
]]

local function bind_meta(player)
    PLAYERS_META[player.pid] = PLAYERS_META[player.pid] or {
        meshes = {},
        old_meshes_info = {}
    }
end

local function get_meta(player)
    return PLAYERS_META[player.pid]
end

local function remove_meta(player)
    PLAYERS_META[player.pid] = nil
end

local function states_diff(current_states, old_states, mesh)
    old_states = table.copy(old_states)
    local diff = {}

    for unit_id, state in pairs(current_states) do
        local old_state = old_states[unit_id]
        old_states[unit_id] = nil
        if not old_state then
            local block_id = mesh.blocks[unit_id].id
            diff[#diff + 1] = {
                unit_id,
                BLOCK_PUSHED,
                {state, block_id}
            }
        elseif old_state ~= state then
            diff[#diff + 1] = {
                unit_id,
                BLOCK_UPDATED,
                {state, nil}
            }
        end
    end

    for unit_id, _ in pairs(old_states) do
        diff[#diff + 1] = {
            unit_id,
            BLOCK_REMOVED,
            nil
        }
    end

    return diff
end

function module.binding(player)
    local meshes_in_view = Mesh.get_in_view(player)
    local meta = get_meta(player)

    for id, mesh in pairs(meshes_in_view) do
        if not meta.meshes[id] then
            meta.meshes[id] = mesh
            meta.old_meshes_info[id] = {
                states = {},
                rotation = {0, 0, 0},
                origin = {0, 0, 0}
            }
        end
    end
end

function module.update(player)
    local meta = get_meta(player)
    for id, mesh in pairs(meta.meshes) do
        if not mesh:in_view(player) then
            meta.meshes[id] = nil
            meta.old_meshes_info[id] = nil
            goto continue
        end

        local client = sandbox.players.get_client(player)

        local current_mesh_states = mesh:get_states()
        local current_mesh_rotation = mesh.rotation
        local current_mesh_origin = mesh.origin

        local old_mesh_info = meta.old_meshes_info[id]
        local old_mesh_states = old_mesh_info.states
        local old_mesh_rotation = old_mesh_info.rotation
        local old_mesh_origin = old_mesh_info.origin

        local diff = states_diff(current_mesh_states, old_mesh_states, mesh)

        if #diff > 0 then
            messages.MeshUpdate:tell(client, {
                mesh_id = id,
                dirty = diff
            })
        end

        if  old_mesh_origin[1] ~= current_mesh_origin[1] or
            old_mesh_origin[2] ~= current_mesh_origin[2] or
            old_mesh_origin[3] ~= current_mesh_origin[3] then
            messages.MeshMoved:tell(client, {
                mesh_id = id,
                pos = current_mesh_origin
            })
        end

        if  old_mesh_rotation[1] ~= current_mesh_rotation[1] or
            old_mesh_rotation[2] ~= current_mesh_rotation[2] or
            old_mesh_rotation[3] ~= current_mesh_rotation[3] then
            messages.MeshRotated:tell(client, {
                mesh_id = id,
                rot = current_mesh_origin
            })
        end

        meta.old_meshes_info[id] = {
            states = current_mesh_states,
            rotation = current_mesh_rotation,
            origin = current_mesh_origin
        }

        ::continue::
    end
end

function module.process(player)
    bind_meta(player)
    module.binding(player)
    module.update(player)
end

return module
