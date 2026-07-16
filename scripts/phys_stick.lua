local messages = require "net/messages"

function on_use_on_block(x, y, z, pid, normal)
    messages.PhysStickSpawn:send({
        x = x, y = y, z = z
    })
end
