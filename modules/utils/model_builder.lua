local DEFAULT_SIZE = { 1, 1, 1 }
local FACE_ORDER = { "east", "west", "bottom", "top", "south", "north" }

local function fnum(x)
    if x == math.floor(x) then return string.format("%d", x) end
    return tostring(x)
end

local function vec(t)
    local parts = {}
    for i, v in ipairs(t) do parts[i] = fnum(v) end
    return "(" .. table.concat(parts, ",") .. ")"
end

local function shift(p, pivot)
    return { p[1] - pivot[1], p[2] - pivot[2], p[3] - pivot[3] }
end

local function bbox_center(boxes)
    local minx, miny, minz = math.huge, math.huge, math.huge
    local maxx, maxy, maxz = -math.huge, -math.huge, -math.huge
    for _, hb in ipairs(boxes) do
        local x, y, z, w, h, l = hb[1], hb[2], hb[3], hb[4], hb[5], hb[6]
        if x < minx then minx = x end
        if y < miny then miny = y end
        if z < minz then minz = z end
        if x + w > maxx then maxx = x + w end
        if y + h > maxy then maxy = y + h end
        if z + l > maxz then maxz = z + l end
    end
    return { (minx + maxx) / 2, (miny + maxy) / 2, (minz + maxz) / 2 }
end

local function build_box(from, to, texture, texture_faces, pivot)
    from = shift(from, pivot)
    to = shift(to, pivot)
    local lines = { string.format("@box from %s to %s {", vec(from), vec(to)) }
    if texture_faces then
        for i, face in ipairs(FACE_ORDER) do
            local tex = texture_faces[i]
            if tex then
                table.insert(lines, string.format('    @part tags (%s) texture "blocks:%s" region (0,0,1,1)', face, tex))
            end
        end
    elseif texture then
        table.insert(lines,
            string.format('    @part tags (top,bottom,north,south,east,west) texture "blocks:%s" region (0,0,1,1)',
                texture))
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

local function build_x(hb, texture, pivot)
    local x, y, z, w, h, l = hb[1], hb[2], hb[3], hb[4], hb[5], hb[6]
    local tex = texture and string.format('"blocks:%s"', texture) or '"$0"'
    local p1 = shift({ x, y, z }, pivot)
    local p2 = shift({ x + w, y, z }, pivot)
    local p1b = { p1[1] + w, p1[2], p1[3] + l }
    local p2b = { p2[1] - w, p2[2], p2[3] + l }
    local lines = {
        string.format('@rect from %s right (%s,0,%s) up (0,%s,0) texture %s region (0,0,1,1)', vec(p1), fnum(w), fnum(l),
            fnum(h), tex),
        string.format('@rect from %s right (%s,0,%s) up (0,%s,0) texture %s region (0,0,1,1)', vec(p1b), fnum(-w),
            fnum(-l), fnum(h), tex),
        string.format('@rect from %s right (%s,0,%s) up (0,%s,0) texture %s region (0,0,1,1)', vec(p2), fnum(-w), fnum(l),
            fnum(h), tex),
        string.format('@rect from %s right (%s,0,%s) up (0,%s,0) texture %s region (0,0,1,1)', vec(p2b), fnum(w),
            fnum(-l), fnum(h), tex)
    }
    return table.concat(lines, "\n")
end

local module = {}

function module.build(block)
    if block["model-name"] then return nil end
    local model = block.model or "block"
    if model == "none" then return "" end

    local texture = block.texture
    local texture_faces = block["texture-faces"]
    if texture and texture_faces then return nil end

    local size = block.size or DEFAULT_SIZE

    if model == "block" then
        local pivot = bbox_center({ { 0, 0, 0, size[1], size[2], size[3] } })
        return build_box({ 0, 0, 0 }, size, texture, texture_faces, pivot)
    end

    if model == "X" then
        local hb = block.hitbox or { 0, 0, 0, size[1], size[2], size[3] }
        local pivot = bbox_center({ hb })
        return build_x(hb, texture, pivot)
    end

    if model == "aabb" then
        local hitboxes = block.hitboxes or { block.hitbox or { 0, 0, 0, size[1], size[2], size[3] } }
        local pivot = bbox_center(hitboxes)
        local parts = {}
        for _, hb in ipairs(hitboxes) do
            local x, y, z, w, h, l = hb[1], hb[2], hb[3], hb[4], hb[5], hb[6]
            table.insert(parts, build_box({ x, y, z }, { x + w, y + h, z + l }, texture, texture_faces, pivot))
        end
        return table.concat(parts, "\n")
    end

    return nil
end

return module
