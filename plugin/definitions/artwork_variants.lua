local utils = require("impl/utils")
local settings = require("impl/settings")
local geometry = require("impl/map_geometry")
local variants = {}

-- Create a resized icon variant without modifying its shared definition.
function variants.Resize(icon, size)
    local result = utils.deepcopy(icon)
    result.size = size
    return result
end

-- Accept either an explicit rectangle or a function that calculates one.
function variants.Cropped(background, crop)
    local result = {}
    for key, value in pairs(background) do
        result[key] = value
    end

    result.crop = function()
        if settings.Get("cropBackgroundMaps") then
            if type(crop) == "function" then
                return crop()
            end
            return crop
        end
        return geometry.Bounds(background)
    end

    return result
end

return variants
