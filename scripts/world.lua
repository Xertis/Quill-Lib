require "constants"
require "std/min"

local animation_player = require "animations/animation_player"
local animation_storage = require "animations/animation_storage"
local api = require "api"
local synced = nil

function on_world_open()
    console.add_command(
        "blocks.to_entity x1:int~pos.x y1:int~pos.y z1:int~pos.z "..
                        "x2:int~pos.x y2:int~pos.y z2:int~pos.z",
        "Fill specified zone with blocks",
        function(args, kwargs)
            local x1,y1,z1, x2,y2,z2 = unpack(args)

            synced = api.to_entity({x1, y1, z1}, {x2, y2, z2})
            --synced:set_config({is_obstacle = true})
            synced:set_pos({player.get_pos(0)})

            animation_storage.load_animation(file.read("quill:animations/root.json"))

            animation_player.play(animation_storage.get_animation("root"), synced)
        end
    )
end

function on_world_tick()
    animation_player.tick()
end