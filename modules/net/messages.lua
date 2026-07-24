local messages = {}

local Message = NEUTRON.messages

messages.PhysStickSpawn = Message.new(PACK_ID, "phys_stick_spawn", {
    x = "int32",
    y = "uint8",
    z = "int32"
})

messages.MeshMoved = Message.new(PACK_ID, "mesh_moved", {
    mesh_id = "var",
    pos = "Vec3<float32>"
})

messages.MeshRotated = Message.new(PACK_ID, "mesh_rot", {
    mesh_id = "var",
    rot = "Vec3<float32>"
})

messages.MeshSpawn = Message.new(PACK_ID, "mesh_spawn", {
    mesh_id = "var",
    origin = "Vec3<float32>",
    -- Блоки: айди+состояние
    blocks = "Array<Pair<uint32, uint16>>"
})

messages.MeshPutBlock = Message.new(PACK_ID, "mesh_pb", {
    mesh_id = "var",
    unit_id = "uint32",

    id = "uint16",
    states = "uint16"
})

messages.MeshRemoveBlock = Message.new(PACK_ID, "mesh_rb", {
    mesh_id = "var",
    unit_id = "uint32"
})

messages.MeshUpdateBlock = Message.new(PACK_ID, "mesh_ub", {
    mesh_id = "var",
    unit_id = "uint32",
    states = "uint16"
})

messages.MeshUpdate = Message.new(PACK_ID, "mesh_um", {
    mesh_id = "var",

    -- unit_id: uint32, action: uint8, states: Nilable<Pair<uint16, Nilable<uint16>>> Первое это стейт, второе - айди
    dirty = "Array<Triple<uint32, uint8, Nilable<Pair<uint16, Nilable<uint16>>>>>"
})

messages.MeshUse = Message.new(PACK_ID, "mesh_use", {})

return messages
