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
    SAVED_DATA.texture_order = texture_order
end

do -- setup visuals
    local id = block.index(blockid)
    local textures = block.get_textures(id)

    for i=0, 5 do
        local indx = tostring(i)
        rig:set_texture("$" .. indx, "blocks:"..textures[texture_order[i+1]])
    end
end

local players_near = {}

function on_sensor_enter(index, oid)
    local other_entity = entities.get(oid)
    local pid = other_entity:get_player()
    if not pid or pid == -1 then
        return
    end
    players_near[pid] = true
end

function on_sensor_exit(index, oid)
    local other_entity = entities.get(oid)
    local pid = other_entity:get_player()
    if not pid or pid == -1 then
        return
    end
    players_near[pid] = nil
    _G["$PLAYER_ON"] = false
end

function on_render()
    local self_pos = tsf:get_pos()
    for pid, _ in pairs(players_near) do
        _G["$PLAYER_ON"] = true

        local player_pos = {player.get_pos(pid)}
        local vel = {player.get_vel(pid)}
        local dx = player_pos[1] - self_pos[1]
        local dy = player_pos[2] - self_pos[2]
        local dz = player_pos[3] - self_pos[3]
        local abs_dx = math.abs(dx)
        local abs_dy = math.abs(dy)
        local abs_dz = math.abs(dz)

        if abs_dy >= abs_dx and abs_dy >= abs_dz then
            if dy > 0 and abs_dy < 1.5 then
                player.set_pos(pid, player_pos[1], self_pos[2] + 1.4, player_pos[3])
                player.set_vel(pid, vel[1], math.max(0, vel[2]), vel[3])
            elseif dy < 0 and abs_dy < 1.4 then
                player.set_pos(pid, player_pos[1], self_pos[2] - 1.3, player_pos[3])
                player.set_vel(pid, vel[1], math.min(0, vel[2]), vel[3])
            end
        elseif abs_dx >= abs_dz then
            if abs_dx < 0.9 then
                local dir = dx > 0 and 1 or -1
                player.set_pos(pid, self_pos[1] + dir * 0.81, player_pos[2], player_pos[3])
                player.set_vel(pid, dir * math.abs(vel[1]), vel[2], vel[3])
            end
        else
            if abs_dz < 0.9 then
                local dir = dz > 0 and 1 or -1
                player.set_pos(pid, player_pos[1], player_pos[2], self_pos[3] + dir * 0.81)
                player.set_vel(pid, vel[1], vel[2], dir * math.abs(vel[3]))
            end
        end
    end
end