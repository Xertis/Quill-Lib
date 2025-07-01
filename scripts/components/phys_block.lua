local tsf = entity.transform
local body = entity.rigidbody
local rig = entity.skeleton

local blockid = ARGS.block
local texture_order = ARGS.texture_order or {4, 1, 3, 2, 5, 6}
local blockstates = ARGS.states or 0
if SAVED_DATA.block then
    blockid = SAVED_DATA.block
    blockstates = SAVED_DATA.states or 0
    texture_order = SAVED_DATA.texture_order or {4, 1, 3, 2, 5, 6}
else
    SAVED_DATA.block = blockid
    SAVED_DATA.states = blockstates
    SAVED_DATA.texture_order = SAVED_DATA.texture_order
end

do -- setup visuals
    local id = block.index(blockid)
    local textures = block.get_textures(id)

    for i=0, 5 do
        local indx = tostring(i)
        rig:set_texture("$" .. indx, "blocks:"..textures[texture_order[i+1]])
    end
end