function on_scripts_loading()
    require "utils/func"
    local m = _G["$Multiplayer"]
    local api = require(string.format("%s:api/%s/api", m.pack_id, m.api_references.Neutron.latest))[m.side]
    PACK_ENV["NEUTRON"] = api
    PACK_ENV["Module"] = api.utils.classes.module
    require "globals"
end

function on_content_loaded()
    if vc.is_client() then
        require "init/client"
    else
        require "init/server"
    end
end
