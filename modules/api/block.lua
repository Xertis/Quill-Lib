local module = {}
local reg_blocks = {}

--[[
Ивенты:
on_placed(x, y, z, player)
on_broken(x, y, z, player)
on_interact(x, y, z, player)
]]

function module.register(id, m)
    reg_blocks[id] = m
end

function module.require(id)
    return reg_blocks[id] or {}
end

return module
