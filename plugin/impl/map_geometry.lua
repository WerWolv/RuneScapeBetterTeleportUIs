local geometry = {}

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function geometry.Bounds(background)
    assert(
        finite(background.width) and finite(background.height) and
        background.width > 0 and background.height > 0, 
        "Background dimensions must be positive numbers"
    )

    local crop = background.crop or {x = 0, y = 0, width = background.width, height = background.height}
    assert(
        type(crop) == "table" and
        finite(crop.x) and
        finite(crop.y) and
        finite(crop.width) and
        finite(crop.height), 
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

function geometry.Contains(background, point)
    local crop = geometry.Bounds(background)

    return point.x >= crop.x                   and
           point.y >= crop.y                   and
           point.x <= crop.x + crop.width  - 1 and
           point.y <= crop.y + crop.height - 1
end

-- Points remain in the full map's coordinate space, even when it is cropped.
function geometry.Project(background, point, width, height)
    local crop = geometry.Bounds(background)
    if not geometry.Contains(background, point) then return nil end

    return math.floor((point.x - crop.x) / math.max(1, crop.width - 1) * (width - 1) + 0.5),
        math.floor((point.y - crop.y) / math.max(1, crop.height - 1) * (height - 1) + 0.5)
end

-- Shared edges are rounded identically to avoid seams between adjacent tiles.
function geometry.Rectangle(background, x, y, width, height, viewWidth, viewHeight)
    local crop   = geometry.Bounds(background)
    local left   = math.floor((x - crop.x) * viewWidth / crop.width)
    local top    = math.floor((y - crop.y) * viewHeight / crop.height)
    local right  = math.floor((x + width - crop.x) * viewWidth / crop.width)
    local bottom = math.floor((y + height - crop.y) * viewHeight / crop.height)

    return left, top, right - left, bottom - top
end

return geometry
