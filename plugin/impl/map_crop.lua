local geometry = require("impl/map_geometry")
local ButtonIcon = require("impl/ui/button_icon")
local HotkeyBadge = require("impl/ui/hotkey_badge")
local settings = require("impl/settings")
local text = require("impl/text")
local cropped = require("definitions/artwork_variants").Cropped

local mapCrop = {}
local padding = 60

-- Calculate the same source-image rectangle previously supplied to Cropped by hand.
local function teleportBounds(source, rows, minWidth)
    local bounds = geometry.Bounds(source)
    local left, top, right, bottom

    for _, row in ipairs(rows) do
        local destination = row.destination
        local point = destination.point

        if not destination.hidden and point ~= nil
            and geometry.Contains(source, point) then
            local width, height = 0, 0

            if destination.icons ~= nil then
                width, height = ButtonIcon.Dimensions(destination.icons)
            end

            local marginX = math.ceil(width / 2) + padding
            local marginY = math.ceil(height / 2) + padding
            local badgeRadius = 0
            local key = text.Hotkey(row.name or "")

            if key ~= nil and not row.locked and settings.Get("showTeleportHotkeys") then
                badgeRadius = math.ceil(HotkeyBadge.Size(key, width) / 2)
            end

            left = math.min(left or point.x, point.x - marginX)
            top = math.min(top or point.y, point.y - marginY - badgeRadius)
            right = math.max(right or point.x, point.x + marginX + badgeRadius)
            bottom = math.max(bottom or point.y, point.y + marginY)
        end
    end

    if left == nil then
        return bounds
    end

    left = math.max(bounds.x, left)
    top = math.max(bounds.y, top)
    right = math.min(bounds.x + bounds.width, right)
    bottom = math.min(bounds.y + bounds.height, bottom)

    -- Header clearance adds map area equally on the left and right.
    local width = math.min(bounds.width, math.max(right - left, minWidth or 0))
    local x = left - (width - (right - left)) / 2

    return {
        x = math.max(bounds.x, math.min(x, bounds.x + bounds.width - width)),
        y = top,
        width = width,
        height = bottom - top,
    }
end

-- Each open map owns its crop; shared backgrounds and their intrinsic regions stay reusable.
-- Set noBackgroundCrop = true on the menu definition to opt out of automatic zooming.
function mapCrop.Attach(menu)
    local source = menu.background
    local background = cropped(source, function()
        if menu.group.noBackgroundCrop then
            return geometry.Bounds(source)
        end

        return teleportBounds(source, menu.rows, menu.cropMinWidth)
    end)

    menu.background = background

    for _, row in ipairs(menu.rows) do
        if row.destination.background == source then
            row.destination.background = background
        end
    end
end

return mapCrop
