local utils = require("impl/utils")
local settings = require("impl/settings")
local variants = {}

-- Create a resized icon variant without modifying its shared definition.
function variants.Resize(icon, size)
    local result = utils.deepcopy(icon)
    result.size = size
    return result
end

-- Resolve optional cropping at layout time so settings changes apply to open maps.
function variants.Cropped(background, crop)
    local result = utils.deepcopy(background)
    local bounds = utils.deepcopy(crop)

    result.crop = function()
        if settings.Get("cropBackgroundMaps") then
            return bounds
        end
    end

    return result
end

return variants
