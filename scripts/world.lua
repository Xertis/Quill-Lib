require "constants"
require "std/min"

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
            synced:set_config({is_obstacle = true})
            synced:set_pos({player.get_pos(0)})
            synced:remove_invisibles()
            synced:put_entity(player.get_entity(0))
        end
    )
end

local tick = 0
function on_world_tick()
    if not synced then
        return
    end

    tick = tick + 1

    --synced:set_rot(mat4.rotate({0, 1, 0}, math.round(math.normalize(tick, 360)*360)))
    synced:move({0.1, 0, 0})
end