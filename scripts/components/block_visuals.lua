if not vc.is_client() then return end

local body = entity.rigidbody
local rig = entity.skeleton

local model_manager = require "utils/model_manager"
local messages = require "net/messages"

local block_id = ARGS.id
local block_pos = ARGS.pos

if SAVED_DATA.block then
    block_id = SAVED_DATA.block.id
    block_pos = SAVED_DATA.block.pos
end

function on_save()
    SAVED_DATA = {
        block = {
            id = block_id,
            pos = block_pos,
        },
    }
end

do -- setup visuals
    local model_info = model_manager.get_model(block_id)
    rig:set_model(0, model_info.name)

    if model_info.type == DEFAULT_MODEL_TYPE then
        rig:set_matrix(0, mat4.translate({-0.5,-0.5,-0.5}))
    end

    body:set_material(block.material(block_id))
end

function on_used()
    messages.MeshUse:send({})
end
