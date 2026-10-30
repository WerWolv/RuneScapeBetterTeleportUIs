local utils = require("impl/utils")
local geometry = {}

-- Validate and return the crop rectangle, defaulting to the full background.
function geometry.Bounds(background)
    assert(
        utils.IsFinite(background.width) and utils.IsFinite(background.height) and
        background.width > 0 and background.height > 0, 
        "Background dimensions must be positive numbers"
    )

    local crop = background.crop

    if type(crop) == "function" then
        crop = crop()
    end

    crop = crop or {x = 0, y = 0, width = background.width, height = background.height}

    assert(
        type(crop) == "table" and
        utils.IsFinite(crop.x) and
        utils.IsFinite(crop.y) and
        utils.IsFinite(crop.width) and
        utils.IsFinite(crop.height),
        "Crop requires numeric x, y, width and height"
    )

    assert(
        crop.x >= 0 and crop.y >= 0 and
        crop.width > 0 and crop.height > 0 and 
        crop.x + crop.width <= background.width and
        crop.y + crop.height <= background.height,
        "Crop must be a positive rectangle inside the full background"
    )
    
    return crop
end

-- Check whether a full-map pixel lies inside the crop's inclusive pixel bounds.
local function contains(crop, point)
    return point.x >= crop.x                   and
           point.y >= crop.y                   and
           point.x <= crop.x + crop.width  - 1 and
           point.y <= crop.y + crop.height - 1
end

-- Report whether a destination is visible within the background's crop.
function geometry.Contains(background, point)
    return contains(geometry.Bounds(background), point)
end

-- Convert a full-map point into displayed coordinates, returning nil outside the crop.
function geometry.Project(background, point, width, height)
    local crop = geometry.Bounds(background)
    if not contains(crop, point) then return nil end

    return math.floor((point.x - crop.x) / math.max(1, crop.width - 1) * (width - 1) + 0.5),
        math.floor((point.y - crop.y) / math.max(1, crop.height - 1) * (height - 1) + 0.5)
end

-- Scale a map rectangle into the viewport using shared rounded edges to avoid tile seams.
function geometry.Rectangle(background, x, y, width, height, viewWidth, viewHeight)
    local crop   = geometry.Bounds(background)
    local left   = math.floor((x - crop.x) * viewWidth / crop.width)
    local top    = math.floor((y - crop.y) * viewHeight / crop.height)
    local right  = math.floor((x + width - crop.x) * viewWidth / crop.width)
    local bottom = math.floor((y + height - crop.y) * viewHeight / crop.height)

    return left, top, right - left, bottom - top
end

return geometry
