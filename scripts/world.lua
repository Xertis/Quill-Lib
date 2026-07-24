if vc.is_client() then return end

local observer = require "net/server/observer"
local Mesh = require "classes/mesh"

events.on("server:client_pipe_start", function (client)
    observer.process(client.player)
end)

function on_world_save()
    Mesh.save()
end

function on_world_open()
    Mesh.load()
end
