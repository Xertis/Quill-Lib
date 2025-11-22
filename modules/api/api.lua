local mesh_utils = require "api/server/mesh"
local animation_storage = require "animations/animation_storage"
local module = {
    server = {
        mesh = mesh_utils,
    },
    client = {},
    general = {
        animations = {
            storage = animation_storage
        }
    }
}

for key, val in pairs(module.general) do
    module.server[key] = val
    module.client[key] = val
end

return module