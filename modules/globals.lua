CHUNK_SIZE = 16

BLOCK_PUSHED = 0
BLOCK_REMOVED = 1
BLOCK_UPDATED = 2
PHYS_BLOCK_ID = entities.def_index("meshup:phys_block")

MESHES_SAVING_FILE = pack.data_file(PACK_ID, "data.bjson")


ROTATION_MATRICES = {}
ROTATION_MATRICES.pipe = {
    [0] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 90),
        mat4.rotate({ 0, 1, 0 }, 0)
    ),
    [1] = mat4.mul(
        mat4.rotate({ 0, 0, 1 }, 90),
        mat4.rotate({ 0, 1, 0 }, 270)
    ),
    [2] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 270),
        mat4.rotate({ 0, 1, 0 }, 180)
    ),
    [3] = mat4.mul(
        mat4.rotate({ 0, 0, 1 }, 270),
        mat4.rotate({ 0, 1, 0 }, 90)
    ),
    [4] = mat4.mul(
        mat4.rotate({ 0, 0, 1 }, 0),
        mat4.rotate({ 0, 1, 0 }, 0)
    ),
    [5] = mat4.mul(
        mat4.rotate({ 0, 0, 1 }, 180),
        mat4.rotate({ 0, 1, 0 }, 180)
    ),
}

ROTATION_MATRICES.pane = {
    [0] = mat4.mul(
        mat4.rotate({ 0, 0, 1 }, 0),
        mat4.rotate({ 0, 1, 0 }, 0)
    ),
    [1] = mat4.mul(
        mat4.rotate({ 0, 0, 1 }, 0),
        mat4.rotate({ 0, 1, 0 }, 90)
    ),
    [2] = mat4.mul(
        mat4.rotate({ 0, 0, 1 }, 0),
        mat4.rotate({ 0, 1, 0 }, 180)
    ),
    [3] = mat4.mul(
        mat4.rotate({ 0, 0, 1 }, 0),
        mat4.rotate({ 0, 1, 0 }, 270)
    ),
}

ROTATION_MATRICES.stairs = {
    [0] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 0),
        mat4.rotate({ 0, 1, 0 }, 0)
    ),
    [1] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 0),
        mat4.rotate({ 0, 1, 0 }, 90)
    ),
    [2] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 0),
        mat4.rotate({ 0, 1, 0 }, 180)
    ),
    [3] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 0),
        mat4.rotate({ 0, 1, 0 }, 270)
    ),
    [4] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 180),
        mat4.rotate({ 0, 1, 0 }, 180)
    ),
    [5] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 180),
        mat4.rotate({ 0, 1, 0 }, 90)
    ),
    [6] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 180),
        mat4.rotate({ 0, 1, 0 }, 0)
    ),
    [7] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 180),
        mat4.rotate({ 0, 1, 0 }, 270)
    ),
}

ROTATION_MATRICES.none = {
    [0] = mat4.mul(
        mat4.rotate({ 1, 0, 0 }, 0),
        mat4.rotate({ 0, 1, 0 }, 0)
    ),
}

ROTATION_FACES = {}

ROTATION_FACES.none = {
    [0] = "+X"
}

ROTATION_FACES.pane = {
    [0] = "-Z",
    [1] = "-X",
    [2] = "+Z",
    [3] = "+X"
}

ROTATION_FACES.pipe = {
    [0] = "-Z",
    [1] = "+X",
    [2] = "+Z",
    [3] = "-X",
    [4] = "-Y",
    [5] = "+Y"
}

ROTATION_FACES.stairs = {
    [0] = "-Z",
    [1] = "-X",
    [2] = "+Z",
    [3] = "+X",
    [4] = "-Z",
    [5] = "-X",
    [6] = "+Z",
    [7] = "+X",
}
