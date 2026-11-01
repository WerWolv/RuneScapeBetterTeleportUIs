local constants = require("definitions/constants")
local geometry = require("impl/map_geometry")
local utils = require("impl/utils")
local HotkeyBadge = require("impl/hotkey_badge")
local components = require("impl/components")
local text = require("impl/text")
local buttonIcon = {}
buttonIcon.__index = buttonIcon

-- Explicit dimensions take precedence; size specifies width when source proportions are known.
function buttonIcon.Dimensions(icons, highlighted)
    local source = icons.normal or icons
    local width = math.max(1, math.floor((highlighted and icons.hoveredSize) or icons.width or icons.size or 48))
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

local function shadowPadding(icons, kind)
    if kind == "sprite" and (icons.shadowColor ~= nil or icons.shadowColorHovered ~= nil) then
        return 2
    end
    return 0
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
    local width, height = marker.bounds.width, marker.bounds.height
    if marker.shadow == nil or marker.shadowImage ~= image or marker.shadowTint ~= color
        or marker.shadowOffset ~= offset or marker.shadowWidth ~= width or marker.shadowHeight ~= height then
        if marker.shadow == nil then
            marker.shadow = prettyui.Sprite.new(marker.shadowLayer, image, utils.deepcopy(marker.bounds))
        elseif marker.shadowImage ~= image then
            marker.shadow:SetSprite(image)
        end
        local root = marker.shadow.root
        root:SetPos(marker.bounds.x + offset, marker.bounds.y + offset)
        root:SetSize(width, height)
        root.rgba = color
        marker.shadowImage, marker.shadowTint, marker.shadowOffset = image, color, offset
        marker.shadowWidth, marker.shadowHeight = width, height
    end
end

-- Overlay a small lock on missing destinations or explicitly marked disabled ones.
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
function buttonIcon:GetMarker(name, icons, highlighted, disabled, locked, showLockWhenDisabled, hotkey)
    disabled = disabled or locked == true
    highlighted = highlighted and not disabled
    local marker = self.markers[name]
    local width, height = buttonIcon.Dimensions(icons, highlighted)
    local source = buttonIcon.Source(icons, highlighted, disabled, locked)
    local objectID = source.objectID
    local objectCount = source.objectCount or icons.objectCount or 1
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

    if marker ~= nil and marker.kind ~= kind then
        -- Only a different native component type needs a fresh subtree.
        destroyMarker(marker)
        self.markers[name], marker = nil, nil
    end

    if marker == nil then
        -- Shadows extend right and down; grow clipping containers rather than shrinking artwork.
        local padding = shadowPadding(icons, kind)
        local layer = ui.Layer.new(self.parent)
        layer:SetSize(width + padding, height + padding)
        layer.clickthrough = true
        local artwork = ui.Layer.new(layer)
        artwork:SetSize(width + padding, height + padding)
        artwork.clickthrough = true
        marker = {
            layer = layer,
            artwork = artwork,
            kind = kind,
            width = width,
            height = height,
        }

        if objectID ~= nil then
            local sprite = components.ItemSprite(artwork, objectID, objectCount)
            sprite:SetSize(width, height)
            marker.itemSprite, marker.objectID, marker.objectCount = sprite, objectID, objectCount
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
        marker.hotkey = HotkeyBadge.New(self.parent, hotkey or text.Hotkey(name))
    end

    -- Hover enlargement reuses the same controls instead of consuming dynamic IDs.
    if marker.width ~= width or marker.height ~= height then
        local padding = shadowPadding(icons, kind)
        marker.layer:SetSize(width + padding, height + padding)
        marker.artwork:SetSize(width + padding, height + padding)
        if marker.itemSprite ~= nil then
            marker.itemSprite:SetSize(width, height)
        else
            marker.sprite.root:SetSize(width, height)
            marker.bounds.width, marker.bounds.height = width, height
            if marker.shadowLayer ~= nil then marker.shadowLayer:SetSize(width + padding, height + padding) end
        end
        marker.width, marker.height = width, height
        if marker.lock ~= nil then marker.lock:Destroy(); marker.lock = nil end
    end

    if marker.itemSprite ~= nil and (marker.objectID ~= objectID or marker.objectCount ~= objectCount) then
        marker.itemSprite.associatedObjectID = objectID
        marker.itemSprite.associatedObjectQuantity = objectCount
        marker.objectID, marker.objectCount = objectID, objectCount
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

    local showLock = (locked and (icons.locked == nil or icons.showLockIcon == true))
        or (disabled and showLockWhenDisabled == true)
    updateLock(marker, width, height, showLock)

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
            local marker = self:GetMarker(row.name, icons, row.name == hovered, row.disabled, row.locked,
                destination.showLockWhenDisabled, destination.hotkey)

            if marker ~= nil then
                local x, y = geometry.Project(menu.background, point, self.parent.width, self.parent.height)
                marker.layer:SetPos(x - marker.width / 2, y - marker.height / 2)
                marker.layer.hidden = false
                marker.layer:MoveToFront()

                marker.hotkey:Update(marker.layer, {
                    width = marker.width,
                    height = marker.height,
                    offset = destination.hotkeyOffset,
                    disabled = row.disabled,
                    hidden = row.locked or (icons.hotkeyOnHover and row.name ~= hovered),
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
