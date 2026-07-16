if vc.is_client() then return end

local observer = require "net/server/observer"
local Mesh = require "classes/mesh"

events.on("server:client_pipe_start", function (client)
    observer.process(client.player)
end)

local block_api = require "api/block"

block_api.register(block.index("base:wooden_door"), {
    on_interact = function(space, pos, player)
        local inc = 1
        if space.get_user_bits(pos, 0, 1) > 0 then
            inc = 3
            space.set_user_bits(pos, 0, 1, 0)
        else
            space.set_user_bits(pos, 0, 1, 1)
        end
        space.set_rotation(pos, (space.get_rotation(pos) + inc) % 4)

        print(space.get_rotation(pos), space.get_rotation(), "победа мб")
    end
})

function on_world_save()
    Mesh.save()
end

function on_world_open()
    Mesh.load()
end
