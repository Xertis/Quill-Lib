function block.count_neighbors(x1, y1, z1)
    local count = 0

    local directions = {
        {x=1, y=0, z=0},
        {x=-1, y=0, z=0},
        {x=0, y=1, z=0},
        {x=0, y=-1, z=0},
        {x=0, y=0, z=1},
        {x=0, y=0, z=-1}
    }

    for _, dir in ipairs(directions) do
        local x = x1 + dir.x
        local y = y1 + dir.y
        local z = z1 + dir.z

        if not table.has({0, -1}, block.get(x, y, z)) then
            count = count + 1
        end
    end

    return count
end