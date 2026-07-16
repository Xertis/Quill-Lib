-- local Mesh = require "classes/mesh"
-- local messages = require "net/messages"
-- local observer = require "net/server/observer"
-- local sandbox = NEUTRON.sandbox
-- local next_id = 0

-- local MESHES = {}

-- local Wrapped = {}
-- Wrapped.__index = Wrapped

-- function Wrapped.new(blocks, origin)
--     local self = setmetatable({}, Wrapped)
--     local id = next_id

--     self.id = id
--     self.mesh = Mesh.new(id, {}, origin)
--     self.old_states = {}

--     next_id = next_id + 1

--     messages.MeshSpawn:echo({ mesh_id = id, origin = origin })

--     MESHES[id] = self
--     return self
-- end

-- function Wrapped:put_block(local_pos, id, states)
--     self.mesh:put_block(id, local_pos)
--     messages.MeshPutBlock:echo({
--         mesh_id = self.id,
--         block = {
--             local_pos = {
--                 x = local_pos[1],
--                 y = local_pos[2],
--                 z = local_pos[3]
--             },
--             id = id
--         }
--     })
-- end

-- function Wrapped:remove_block(local_pos)
--     self.mesh:remove_block(local_pos)
--     messages.MeshDespawnBlock:echo({
--         mesh_id = self.id,
--         local_pos = {
--             x = local_pos[1],
--             y = local_pos[2],
--             z = local_pos[3]
--         }
--     })
-- end

-- local function send(mesh_id, dirty, x, z)
--     for ident, player in pairs(sandbox.players.get_all()) do
--         if not sandbox.players.chunk_is_loaded(player, x, z) then
--             goto continue
--         end

--         local client = sandbox.players.get_client(player)
--         messages.MeshUpdate:tell(client, {
--             mesh_id = mesh_id,
--             dirty = dirty
--         })

--         ::continue::
--     end
-- end

-- function Wrapped.tick()
--     for _, wrap in pairs(MESHES) do
--         local dirty = {}
--         local old_states = wrap.old_states
--         local blocks = wrap.mesh.blocks

--         for unit_id, block in pairs(blocks) do
--             local logic = block.logic
--             local state = logic.get_states()

--             if state ~= old_states[unit_id] then
--                 dirty[#dirty + 1] = { unit_id, state }
--                 old_states[unit_id] = state
--             end
--         end

--         if #dirty ~= 0 then
--             local origin = wrap.mesh.origin
--             local cx, cz = math.floor(origin[1] / 16), math.floor(origin[3] / 16)

--             send(wrap.id, dirty, cx, cz)
--         end
--     end
-- end

-- return Wrapped
