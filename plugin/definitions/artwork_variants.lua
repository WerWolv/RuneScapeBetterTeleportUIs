local utils = require("impl/utils")
local variants = {}

-- Create a resized icon variant without modifying its shared definition.
function variants.Resize(icon, size)
    local result = utils.deepcopy(icon)
    result.size = size
    return result
end

-- Create an independent background variant with the requested crop rectangle.
function variants.Cropped(background, crop)
    local result = utils.deepcopy(background)
    result.crop = utils.deepcopy(crop)
    return result
end

return variants
