local constants = require("definitions/constants")
local geometry = require("impl/map_geometry")
local utils = require("impl/utils")
local userSettings = require("impl/settings")
local buttonIcon = {}
buttonIcon.__index = buttonIcon

-- Fit an icon into its square marker while preserving proportions and shadow space.
local function iconBounds(source, icons, size)
    local inset = (icons.shadowColor ~= nil or icons.shadowColorHovered ~= nil) and 2 or 0
    local available = math.max(1, size - inset * 2)
    local width, height = available, available
    local sourceWidth = source.imageWidth or icons.imageWidth
    local sourceHeight = source.imageHeight or icons.imageHeight

    if sourceWidth and sourceHeight then
        local scale = math.min(available / sourceWidth, available / sourceHeight)
        width = math.max(1, math.floor(sourceWidth * scale))
        height = math.max(1, math.floor(sourceHeight * scale))
    end

    return {
        x = math.floor((size - width) / 2), 
        y = math.floor((size - height) / 2),
        width = width, 
        height = height,
    }
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
local function updateSpriteShadow(marker, image, icons, highlighted, disabled, size)
    if icons.shadowColor == nil and icons.shadowColorHovered == nil then
        return
    end

    if marker.shadowLayer == nil then
        marker.shadowLayer = ui.Layer.new(marker.artwork)
        marker.shadowLayer:SetSize(size, size)
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

-- Show the original option's numeric prefix at the icon's top-right when enabled in settings.
local function updateHotkey(marker, name, size, disabled, locked)
    local hotkey = name:match("^%s*(%d+)%.")
    if locked or not userSettings.Get("showTeleportHotkeys") or hotkey == nil then
        if marker.hotkey ~= nil then marker.hotkey.hidden = true end
        return
    end

    if marker.hotkey == nil then
        local badge = ui.Layer.new(marker.layer)
        badge.clickthrough = true

        local background = ui.Rectangle.new(badge)
        background:SetSize(0, 0, 1.0, 1.0)
        background.fill = true
        background.rgba = 0x17120FCC
        background.clickthrough = true

        local text = ui.Text.new(badge)
        text:SetSize(0, 0, 1.0, 1.0)
        text.font = id.Font.MUSEO_SANS_13PT_BOLD
        text:AlignTo(ui.AlignMode.CENTRE)
        text.isShadowed = true
        text.maxLines = 1
        text.clickthrough = true

        marker.hotkey, marker.hotkeyText = badge, text
    end

    local width = math.min(size, 8 + #hotkey * 8)
    marker.hotkey:SetSize(width, 18)
    marker.hotkey:SetPos(size - width, 0)
    marker.hotkeyText.content = hotkey
    marker.hotkeyText.rgba = disabled and 0x9D978AFF or 0xFFE3A3FF
    marker.hotkey.hidden = false
    marker.hotkey:MoveToFront()
end

-- Overlay a small lock on destinations that have no corresponding native menu option.
local function updateLock(marker, size, locked)
    if locked and marker.lock == nil then
        local lock = ui.Sprite.new(marker.layer)
        local lockSize = math.max(1, math.min(50, math.floor(size)))
        lock:SetSize(lockSize, lockSize)
        lock:SetPos(size - lockSize / 1.3, size - lockSize / 1.3)
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

-- Create or reuse a destination marker and apply its image, hover and disabled states.
function buttonIcon:GetMarker(name, icons, highlighted, disabled, locked)
    disabled = disabled or locked == true
    highlighted = highlighted and not disabled
    local marker = self.markers[name]
    local size = icons.size or 48
    local normal = icons.normal or icons
    local source = locked and (icons.locked or normal)
        or (highlighted and (icons.hovered or normal) or normal)
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

    if marker ~= nil and marker.kind ~= kind then
        -- Inventory items and ordinary sprites require different native component types.
        destroyMarker(marker)
        self.markers[name], marker = nil, nil
    end

    if marker == nil then
        local layer = ui.Layer.new(self.parent)
        layer:SetSize(size, size)
        layer.clickthrough = true
        local artwork = ui.Layer.new(layer)
        artwork:SetSize(size, size)
        artwork.clickthrough = true
        marker = {layer = layer, artwork = artwork, kind = kind}

        if objectID ~= nil then
            local sprite = ui.Sprite.new(artwork)
            sprite:SetSize(size, size)
            sprite.associatedObjectID = objectID
            sprite.associatedObjectQuantity = 1
            sprite.associatedObjectQuantityMode = ui.ObjectQuantityDisplayMode.NEVER
            sprite.clickthrough = true
            marker.itemSprite, marker.objectID = sprite, objectID
        else
            marker.bounds = iconBounds(source, icons, size)
            marker.sprite = prettyui.Sprite.new(artwork, image, utils.deepcopy(marker.bounds))
            marker.image = image
        end

        self.markers[name] = marker
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
        updateSpriteShadow(marker, image, icons, highlighted, disabled, size)
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

    updateHotkey(marker, name, size, disabled, locked)
    updateLock(marker, size, locked and icons.locked == nil)

    return marker
end

-- Position visible icons and hide markers for hidden, cropped-out or unavailable artwork.
function buttonIcon:Update(menu, hovered)
    for _, marker in pairs(self.markers) do 
        marker.layer.hidden = true 
    end

    for _, row in ipairs(menu.rows) do
        local destination = row.destination
        local icons, point = destination.icons, destination.point

        if not destination.hidden and icons ~= nil and point ~= nil and geometry.Contains(menu.background, point) then
            local marker = self:GetMarker(row.name, icons, row.name == hovered, row.disabled, row.locked)

            if marker ~= nil then
                local size = icons.size or 48
                local x, y = geometry.Project(menu.background, point, self.parent.width, self.parent.height)
                marker.layer:SetPos(x - size / 2, y - size / 2)
                marker.layer.hidden = false
                marker.layer:MoveToFront()
            end
        end
    end

    if hovered ~= nil and self.markers[hovered] ~= nil then
        self.markers[hovered].layer:MoveToFront()
    end
end

return buttonIcon
