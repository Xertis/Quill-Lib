local mp = require "not_utils:main".multiplayer.api.server
local animation_player = require "animations/animation_player"
local animation_storage = require "animations/animation_storage"
local api = require "api/server"
local synced = nil

mp.console.set_command(
    "meshup.to_entity: x1=<number>, y1=<number>, z1=<number>, x2=<number>, y2=<number>, z2=<number> -> Fill specified zone with blocks",
    {server={"meshup_spawn"}},
    function (region, client)

        synced = api.to_mesh({region.x1,region.y1, region.z1}, {region.x2, region.y2, region.z2})
        synced:set_pos(table.map({player.get_pos(0)}, function (i, val)
            return val+10
        end))
        animation_storage.load_animation(file.read(PACK_ID .. ":animations/root.json"))

        animation_player.play(animation_storage.get_animation("root"), synced)
    end
)

