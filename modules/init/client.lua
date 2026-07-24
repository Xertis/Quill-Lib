NEUTRON.entities.desync("meshup:phys_block")

local model_builder = require "utils/model_builder"
local model_manager = require "utils/model_manager"

for id = 0, block.defs_count() - 1 do
    local pack, block_name = parse_path(block.name(id))
    local path = string.format("%s:blocks/%s.json", pack, block_name)
    if pack == "core" then goto continue end

    local data = json.parse(file.read(path))
    local vcm = model_builder.build(data)

    if vcm then
        local raw_model_name = block.model_name(id):match(":(.-)%.")
        local model_name = string.format("meshup__%s__%s", pack, raw_model_name)
        assets.parse_model("vcm", vcm, model_name)
        model_manager.reg_model(id, {
            name = model_name,
            type = GENERATED_MODEL_TYPE
        })
    else
        model_manager.reg_model(id, {
            name = block.model_name(id),
            type = DEFAULT_MODEL_TYPE
        })
    end

    ::continue::
end

require "net/client/mesh_listener"
