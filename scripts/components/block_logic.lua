local Mesh = require "classes/mesh"
local block_api = require "api/block"
local space = require "api/space"

local tsf = entity.transform
local body = entity.rigidbody
local rig = entity.skeleton

--[[
Структура SAVED_DATA

local SAVED_DATA = {
    block = {
        id = 0
    }
}
]]

local block_id = ARGS.id
local block_local_pos = ARGS.local_pos

local unit_id = ARGS.unit_id
local mesh_id = ARGS.mesh_id

local block_states = ARGS.states

if SAVED_DATA.block then
    block_id = SAVED_DATA.block.id
    block_local_pos = SAVED_DATA.block.local_pos
    block_states = SAVED_DATA.block.states

    unit_id = SAVED_DATA.unit_id
    mesh_id = SAVED_DATA.mesh_id
end

local rot_profile = block.get_rotation_profile(block_id)

function on_save()
    SAVED_DATA = {
        block = {
            id = block_id,
            local_pos = block_local_pos,
            states = block_states
        },
        unit_id = unit_id,
        mesh_id = mesh_id,
    }
end

do -- setup physics
    body:set_gravity_scale(0)
    body:set_mass(math.huge)
end

local block_module = nil
local space_api = nil
do -- setup api
    block_module = block_api.require(block_id)

    space_api = space.get_mesh(Mesh.get(mesh_id), unit_id)
end

function get_states()
    return block_states
end

function set_states(states)
    block_states = states
end

function get_id()
    return block_id
end

function get_mesh_id()
    return mesh_id
end

function get_unit_id()
    return unit_id
end

function on_update()
    if block_module.on_update then
        block_module.on_update(
            space_api,
            tsf:get_pos()
        )
    end
end

function on_physics_update()
    local mesh = Mesh.get(mesh_id)

    local rot = bit.band(block_states, 7)
    local min_pos, hitbox = unpack(block.get_hitbox(block_id, rot))
    body:set_size(vec3.sub(hitbox, { 0.0001, 0.0001, 0.0001 }))
    local center = vec3.add(min_pos, vec3.div(hitbox, 2))

    local local_offset = vec3.add(block_local_pos, center)
    local local_rot = ROTATION_MATRICES[rot_profile][rot]

    local world_pos, world_rot = mesh:get_world_pos_and_rot(local_offset, local_rot)

    tsf:set_pos(world_pos)
    tsf:set_rot(world_rot)
end
