NEUTRON.entities.desync("meshup:phys_block")

local model_builder = require "utils/model_builder"
for id = 0, block.defs_count() - 1 do
    local pack, block_name = parse_path(block.name(id))
    local path = string.format("%s:blocks/%s.json", pack, block_name)
    if pack == "core" then goto continue end

    local data = json.parse(file.read(path))
    local vcm = model_builder.build(data)

    local model_name = block.model_name(id):match(":(.-)%.")
    assets.parse_model("vcm", vcm, string.format("meshup__%s__%s", pack, model_name))

    ::continue::
end

require "net/client/mesh_listener"
