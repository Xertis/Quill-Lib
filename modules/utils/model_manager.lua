local module = {}

local models = {}

function module.reg_model(block_id, model)
    models[block_id] = model
end

function module.get_model(block_id)
    return models[block_id]
end

return module
