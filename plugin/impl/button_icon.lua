local constants = require("definitions/constants")
local geometry = require("impl/map_geometry")
local utils = require("impl/utils")
local HotkeyBadge = require("impl/hotkey_badge")
local components = require("impl/components")
local text = require("impl/text")
local buttonIcon = {}
buttonIcon.__index = buttonIcon

-- Explicit dimensions take precedence; size specifies width when source proportions are known.
function buttonIcon.Dimensions(icons)
    local source = icons.normal or icons
    local width = math.max(1, math.floor(icons.width or icons.size or 48))
    local height = icons.height
    local sourceWidth = source.imageWidth or icons.imageWidth
    local sourceHeight = source.imageHeight or icons.imageHeight

    if height == nil and sourceWidth and sourceHeight then
        height = width * sourceHeight / sourceWidth
    end

    return width, math.max(1, math.floor((height or width) + 0.5))
end

-- Convert Vector4 shadow colors to packed RGBA, leaving existing hex values unchanged.
local function shadowRGBA(color)
    if type(color) == "number" then 
        return color
    end

    local function byte(value)
        return math.floor(math.max(0, math.min(1, value)) * 255 + 0.5)
    end

    return (byte(color.x) << 24) | (byte(color.y) << 16) | (byte(color.z) << 8) | byte(color.w)
end

-- Choose a state's shadow color, suppressing shadows for disabled destinations.
local function getShadowColor(icons, highlighted, disabled)
    if disabled then 
        return 0x00000000
    end

    if highlighted then 
        return icons.shadowColorHovered or constants.defaultShadowColorHovered
    end

    return icons.shadowColor or constants.defaultShadowColor
end

-- Maintain a tinted, offset copy behind non-item icons for their current shadow state.
local function updateSpriteShadow(marker, image, icons, highlighted, disabled)
    if icons.shadowColor == nil and icons.shadowColorHovered == nil then
        return
    end

    if marker.shadowLayer == nil then
        marker.shadowLayer = ui.Layer.new(marker.artwork)
        marker.shadowLayer:SetSize(marker.artwork.width, marker.artwork.height)
        marker.shadowLayer.clickthrough = true
        marker.shadowLayer:MoveToBack()
    end

    local color = shadowRGBA(getShadowColor(icons, highlighted, disabled))
    marker.shadowLayer.hidden = (color & 0xFF) == 0
    if marker.shadowLayer.hidden then 
        return
    end

    local offset = highlighted and 2 or 1
    if marker.shadow == nil or marker.shadowImage ~= image or marker.shadowTint ~= color
        or marker.shadowOffset ~= offset then
        if marker.shadow ~= nil then marker.shadow:Destroy() end
        local options = utils.deepcopy(marker.bounds)
        options.x, options.y = options.x + offset, options.y + offset
        options.colour = color
        marker.shadow = prettyui.Sprite.new(marker.shadowLayer, image, options)
        marker.shadowImage, marker.shadowTint, marker.shadowOffset = image, color, offset
    end
end

-- Overlay a small lock on destinations that have no corresponding native menu option.
local function updateLock(marker, width, height, locked)
    if locked and marker.lock == nil then
        local lock = ui.Sprite.new(marker.layer)
        local lockSize = math.max(1, math.min(50, width, height))
        lock:SetSize(lockSize, lockSize)
        lock:SetPos(width - lockSize / 1.3, height - lockSize / 1.3)
        lock.spriteID = id.Sprite.RS_MOBILE_ICON_LOCK_ABILITY_BOOK
        lock.clickthrough = true
        lock.shadowRGBA = 0x000000FF
        marker.lock = lock
    end
    if marker.lock ~= nil then
        marker.lock.hidden = not locked
        if locked then marker.lock:MoveToFront() end
    end
end

-- Release explicit sprite wrappers and the native marker subtree.
local function destroyMarker(marker)
    if marker.shadow ~= nil then 
        pcall(function() marker.shadow:Destroy() end)
    end

    if marker.sprite ~= nil then 
        pcall(function() marker.sprite:Destroy() end)
    end

    if marker.hotkey ~= nil then
        pcall(function()
            marker.hotkey:Destroy()
        end)
    end

    pcall(function() marker.layer:Destroy() end)
end

-- Create an icon collection attached to the map viewport.
function buttonIcon.New(parent)
    return setmetatable({parent = parent, markers = {}}, buttonIcon)
end

-- Destroy every marker and discard cached rendering state.
function buttonIcon:Destroy()
    for _, marker in pairs(self.markers) do destroyMarker(marker) end
    self.markers = {}
end

-- Use the same artwork precedence for map markers and slot navigation controls.
function buttonIcon.Source(icons, highlighted, disabled, locked)
    local normal = icons.normal or icons

    if locked then
        return icons.locked or normal
    end

    if highlighted and not disabled then
        return icons.hovered or normal
    end

    return normal
end

-- Create or reuse a destination marker and apply its image, hover and disabled states.
function buttonIcon:GetMarker(name, icons, highlighted, disabled, locked)
    disabled = disabled or locked == true
    highlighted = highlighted and not disabled
    local marker = self.markers[name]
    local width, height = buttonIcon.Dimensions(icons)
    local source = buttonIcon.Source(icons, highlighted, disabled, locked)
    local objectID = source.objectID
    local kind = objectID ~= nil and "item" or "sprite"
    local image

    if objectID == nil then
        image = source.sprite
        if image == nil then
            image = source.image
            if image ~= nil and not image.loaded then image:Load() end
            if image == nil or not image.loaded then return nil end
        end
    end

    if marker ~= nil and (marker.kind ~= kind or marker.width ~= width or marker.height ~= height) then
        -- Rebuild artwork and its overlays when the component type or dimensions change.
        destroyMarker(marker)
        self.markers[name], marker = nil, nil
    end

    if marker == nil then
        -- Shadows extend right and down; grow clipping containers rather than shrinking artwork.
        local shadowPadding = kind == "sprite"
            and (icons.shadowColor ~= nil or icons.shadowColorHovered ~= nil) and 2 or 0
        local layer = ui.Layer.new(self.parent)
        layer:SetSize(width + shadowPadding, height + shadowPadding)
        layer.clickthrough = true
        local artwork = ui.Layer.new(layer)
        artwork:SetSize(width + shadowPadding, height + shadowPadding)
        artwork.clickthrough = true
        marker = {
            layer = layer,
            artwork = artwork,
            kind = kind,
            width = width,
            height = height,
        }

        if objectID ~= nil then
            local sprite = components.ItemSprite(artwork, objectID)
            sprite:SetSize(width, height)
            marker.itemSprite, marker.objectID = sprite, objectID
        else
            marker.bounds = {
                x = 0,
                y = 0,
                width = width,
                height = height,
            }
            marker.sprite = prettyui.Sprite.new(artwork, image, utils.deepcopy(marker.bounds))
            marker.image = image
        end

        self.markers[name] = marker
        marker.hotkey = HotkeyBadge.New(self.parent, text.Hotkey(name))
    end

    if marker.itemSprite ~= nil and marker.objectID ~= objectID then
        marker.itemSprite.associatedObjectID = objectID
        marker.objectID = objectID
        marker.highlighted, marker.disabled = nil, nil
    end

    local shadowColor = getShadowColor(icons, highlighted, disabled)
    if marker.itemSprite ~= nil
        and (marker.highlighted ~= highlighted or marker.shadowColor ~= shadowColor) then
        marker.itemSprite.outlineWidth = highlighted and 1 or 0
        if type(shadowColor) == "number" then
            marker.itemSprite.shadowRGBA = shadowColor
        else
            marker.itemSprite.shadowColour = shadowColor
        end
        marker.highlighted, marker.shadowColor = highlighted, shadowColor
    elseif marker.sprite ~= nil and marker.image ~= image then
        marker.sprite:SetSprite(image)
        marker.image = image
    end

    if marker.sprite ~= nil then
        updateSpriteShadow(marker, image, icons, highlighted, disabled)
    end

    if marker.disabled ~= disabled then
        if marker.itemSprite ~= nil then
            marker.itemSprite.colour = disabled
                and Vector4.new(0.45, 0.45, 0.45, 1.0) or Vector4.new(1.0, 1.0, 1.0, 1.0)
        else
            marker.artwork.alpha = disabled and 0.4 or 1.0
        end
        marker.disabled = disabled
    end

    updateLock(marker, width, height, locked and (icons.locked == nil or icons.showLockIcon == true))

    return marker
end

-- Position visible icons and hide markers for hidden, cropped-out or unavailable artwork.
function buttonIcon:Update(menu, hovered)
    for _, marker in pairs(self.markers) do 
        marker.layer.hidden = true 
        if marker.hotkey ~= nil then
            marker.hotkey:Hide()
        end
    end

    for _, row in ipairs(menu.rows) do
        local destination = row.destination
        local icons, point = destination.icons, destination.point

        if not destination.hidden and icons ~= nil and point ~= nil and geometry.Contains(menu.background, point) then
            local marker = self:GetMarker(row.name, icons, row.name == hovered, row.disabled, row.locked)

            if marker ~= nil then
                local x, y = geometry.Project(menu.background, point, self.parent.width, self.parent.height)
                marker.layer:SetPos(x - marker.width / 2, y - marker.height / 2)
                marker.layer.hidden = false
                marker.layer:MoveToFront()

                marker.hotkey:Update(marker.layer, {
                    width = marker.width,
                    disabled = row.disabled,
                    hidden = row.locked,
                })
            end
        end
    end

    if hovered ~= nil and self.markers[hovered] ~= nil then
        local marker = self.markers[hovered]
        marker.layer:MoveToFront()

        if marker.hotkey ~= nil then
            marker.hotkey:MoveToFront()
        end
    end
end

return buttonIcon
