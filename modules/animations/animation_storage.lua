local module = {}

local Animations = {}

function module.load_animation(file_content)
    local animation_json = json.parse(file_content)

    local animation_name = table.keys(animation_json.animations)[1]
    local animation = animation_json.animations[animation_name]

    local bone_name = table.keys(animation.bones)[1]
    local bone = animation.bones[bone_name]

    Animations[animation_name] = {
        name = animation_name,
        length = animation.animation_length,
        animation = bone
    }

    return animation_name
end

function module.get_animation(name)
    return Animations[name]
end

return module