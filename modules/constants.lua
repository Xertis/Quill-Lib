ROTATIONS = {}
ROTATIONS.pipe = {
    [0] = {
        rotation = mat4.rotate({0, 1, 0}, 180),
    },
    [1] = {
        rotation = mat4.rotate({0, 1, 0}, 90),
    },
    [2] = {
        rotation = mat4.rotate({0, 1, 0}, 0),
    },
    [3] = {
        rotation = mat4.rotate({0, 1, 0}, 270),
    },
    [4] = {
        rotation = mat4.mul(
            mat4.rotate({0, 1, 0}, 180),
            mat4.rotate({1, 0, 0}, 90)
        ),
    },
    [5] = {
        rotation = mat4.mul(
            mat4.rotate({0, 1, 0}, 180),
            mat4.rotate({1, 0, 0}, 270)
        ),
    }
}

ROTATIONS.pane = {
    [0] = {
        rotation = mat4.mul(
            mat4.rotate({0, 1, 0}, 180),
            mat4.rotate({1, 0, 0}, 90)
        ),
    },
    [1] = {
        rotation = mat4.mul(
            mat4.rotate({0, 1, 0}, 270),
            mat4.rotate({1, 0, 0}, 90)
        ),
    },
    [2] = {
        rotation = mat4.rotate({1, 0, 0}, 90),
    },
    [3] = {
        rotation = mat4.mul(
            mat4.rotate({0, 1, 0}, 90),
            mat4.rotate({1, 0, 0}, 90)
        ),
    },
}

ROTATIONS.none = {
    [0] = {
        rotation = mat4.rotate({1, 0, 0}, 90),
    },
}