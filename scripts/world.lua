require "constants"
require "std/min"

local animation_player = require "animations/animation_player"
local mp = require "not_utils:main".multiplayer
local mode = mp.mode

if mode == "server" then
    require "init/server"
elseif mode == "client" then
    require "init/client"
else
    require "init/server"
    require "init/client"
end

require "init/general"

function on_world_tick()
    animation_player.tick()
end