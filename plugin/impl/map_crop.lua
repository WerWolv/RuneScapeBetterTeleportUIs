local geometry = require("impl/map_geometry")
local ButtonIcon = require("impl/ui/button_icon")
local HotkeyBadge = require("impl/ui/hotkey_badge")
local settings = require("impl/settings")
local text = require("impl/text")

local mapCrop = {}
local padding = 30

local function cropped(background, crop)
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

-- Calculate the same source-image rectangle previously supplied to Cropped by hand.
local function teleportBounds(source, rows, minWidth, scale)
    local bounds = geometry.Bounds(source)
    scale = scale or 1
    local left, top, right, bottom

    for _, row in ipairs(rows) do
        local destination = row.destination
        local point = destination.point

        if not destination.hidden and point ~= nil
            and geometry.Contains(source, point, bounds) then
            local width, height = 0, 0

            if destination.icons ~= nil then
                width, height = ButtonIcon.Dimensions(destination.icons)
                local hoverWidth, hoverHeight = ButtonIcon.Dimensions(destination.icons, true)
                width, height = math.max(width, hoverWidth), math.max(height, hoverHeight)
            end

            local marginX = math.ceil(width / (2 * scale)) + padding
            local marginY = math.ceil(height / (2 * scale)) + padding
            local badgeRadius = 0
            local key = text.Hotkey(row.name or "")

            if key ~= nil and not row.locked and settings.Get("showTeleportHotkeys") then
                badgeRadius = math.ceil(HotkeyBadge.Size(key, width) / (2 * scale))
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

-- Icons use interface pixels. The full source's fitted scale is a conservative
-- lower bound: zooming into a smaller crop can only make its map scale larger.
function mapCrop.SetViewport(menu, width, height)
    if menu.cropSource == nil then
        return
    end

    -- Invalidate once per layout pass, rather than rescanning every destination
    -- for each Bounds/Contains/Project call while drawing the same map.
    menu.cropCache = nil
    local bounds = geometry.Bounds(menu.cropSource)
    menu.cropScale = math.min(math.max(1, width) / bounds.width, math.max(1, height) / bounds.height)
end

-- Each open map owns its crop; shared backgrounds and their intrinsic regions stay reusable.
-- Set noBackgroundCrop = true on the menu definition to opt out of automatic zooming.
function mapCrop.Attach(menu)
    local source = menu.background
    menu.cropSource = source
    local background = cropped(source, function()
        if menu.group.noBackgroundCrop then
            return geometry.Bounds(source)
        end

        local hotkeys = settings.Get("showTeleportHotkeys")
        local cache = menu.cropCache

        if cache == nil or cache.minWidth ~= menu.cropMinWidth or cache.scale ~= menu.cropScale
            or cache.hotkeys ~= hotkeys then
            cache = {
                minWidth = menu.cropMinWidth,
                scale = menu.cropScale,
                hotkeys = hotkeys,
                bounds = teleportBounds(source, menu.rows, menu.cropMinWidth, menu.cropScale),
            }
            menu.cropCache = cache
        end

        return cache.bounds
    end)

    menu.background = background

    for _, row in ipairs(menu.rows) do
        if row.destination.background == source then
            row.destination.background = background
        end
    end
end

return mapCrop
