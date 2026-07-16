local body = entity.rigidbody
local rig = entity.skeleton

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
    local raw_model_name = block.model_name(block_id)
    local pack = raw_model_name:match("([^:]*)")
    local model_name = raw_model_name:match(":(.-)%.")
    rig:set_model(0, string.format("meshup__%s__%s", pack, model_name))

    body:set_material(block.material(block_id))
end

function on_used()
    messages.MeshUse:send({})
end
