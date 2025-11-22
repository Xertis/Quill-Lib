local mp = require "not_utils:main".multiplayer.api.server
local api = require "meshup:api/api".server
local synced = nil

mp.console.set_command(
    "meshup.to_entity: x1=<number>, y1=<number>, z1=<number>, x2=<number>, y2=<number>, z2=<number> -> Fill specified zone with blocks",
    {server={"meshup_spawn"}},
    function (region, client)

        synced = api.mesh.to_mesh({region.x1,region.y1, region.z1}, {region.x2, region.y2, region.z2})
        synced:set_pos(table.map({player.get_pos(client.player.pid)}, function (i, val)
            return val+1
        end))

        synced:animation_play("root")
    end
)

