local utils = {}

function utils.IsFinite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy

    if orig_type == 'table' then
        copy = {}

        for orig_key, orig_value in next, orig, nil do
            copy[utils.DeepCopy(orig_key)] = utils.DeepCopy(orig_value)
        end

        setmetatable(copy, utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end

    return copy
end

function utils.Resize(icon, size)
    local result = utils.DeepCopy(icon)
    result.size = size
    return result
end

return utils
