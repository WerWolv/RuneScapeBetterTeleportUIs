local constants = require("definitions/constants")
local geometry = require("impl/map_geometry")
local SpriteLayers = require("impl/ui/sprite_layers")
local Model3D = require("impl/ui/model_3d")
local HotkeyBadge = require("impl/ui/hotkey_badge")
local components = require("impl/ui/components")
local text = require("impl/text")
local cleanup = require("impl/cleanup")

local buttonIcon = {}
buttonIcon.__index = buttonIcon
local anchors = {
    topLeft = { x = 0, y = 0 },
    topRight = { x = 1, y = 0 },
    bottomLeft = { x = 0, y = 1 },
    bottomRight = { x = 1, y = 1 },
}
local anchorPadding = 12
local hoverScale = 1.1
local pressHookID = "teleportMapsIconPress"
local pressHooks = { "ONCLICK", "ONHOLD", "ONRELEASE", "ONMOUSELEAVE" }

-- Explicit dimensions take precedence; size specifies width when source proportions are known.
function buttonIcon.Dimensions(icons, highlighted)
    local source = icons.normal or icons
    local normalWidth = math.max(1, math.floor(icons.width or icons.size or 48))
    local width = normalWidth
    if highlighted then
        width = math.max(1, math.floor((icons.hoveredSize or normalWidth * hoverScale) + 0.5))
    end
    local height = icons.height
    local sourceWidth = source.imageWidth or icons.imageWidth
    local sourceHeight = source.imageHeight or icons.imageHeight

    if height ~= nil then
        height = height * width / normalWidth
    elseif sourceWidth and sourceHeight then
        height = width * sourceHeight / sourceWidth
    end

    return width, math.max(1, math.floor((height or width) + 0.5))
end

function buttonIcon.IsAnchor(anchor)
    return anchors[anchor] ~= nil
end

-- Anchor centres are viewport-relative and fixed across hover states. A point on an
-- anchored entry is ignored; it is never a map location or part of the map crop.
function buttonIcon.Position(background, destination, width, height)
    if destination.anchor ~= nil then
        local anchor = anchors[destination.anchor]
        if anchor == nil then return nil end

        local iconWidth, iconHeight = buttonIcon.Dimensions(destination.icons)
        local hoverWidth, hoverHeight = buttonIcon.Dimensions(destination.icons, true)
        local insetX = math.min(width / 2, anchorPadding + math.max(iconWidth, hoverWidth) / 2)
        local insetY = math.min(height / 2, anchorPadding + math.max(iconHeight, hoverHeight) / 2)
        return anchor.x == 0 and insetX or width - insetX,
            anchor.y == 0 and insetY or height - insetY
    end

    if destination.point ~= nil then
        return geometry.Project(background, destination.point, width, height)
    end
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
        marker.shadowLayer = prettyui.NewComponent(ui.Layer, marker.artwork)
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

    if marker.shadow == nil then
        marker.shadow = SpriteLayers.New(marker.shadowLayer, image, marker.bounds)
    elseif marker.shadowImage ~= image then
        marker.shadow:SetSprite(image)
    end

    if marker.shadowImage ~= image or marker.shadowTint ~= color
        or marker.shadowOffset ~= offset or marker.shadowWidth ~= width or marker.shadowHeight ~= height then
        local root = marker.shadow.root
        root:SetPos(marker.bounds.x + offset, marker.bounds.y + offset)
        root:SetSize(width, height)
        marker.shadow:SetRGBA(color)

        marker.shadowImage, marker.shadowTint, marker.shadowOffset = image, color, offset
        marker.shadowWidth, marker.shadowHeight = width, height
    end
end

-- Overlay a small lock on missing destinations or explicitly marked disabled ones.
local function updateLock(marker, width, height, locked)
    if locked and marker.lock == nil then
        local lock = prettyui.NewComponent(ui.Sprite, marker.layer)
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

        if locked then
            marker.lock:MoveToFront()
        end
    end
end

-- Release explicit sprite wrappers and the native marker subtree.
local function destroyMarker(marker)
    cleanup.Release(marker, "model")
    cleanup.Release(marker, "shadow")
    cleanup.Release(marker, "sprite")
    cleanup.Release(marker, "hotkey")
    cleanup.Release(marker, "layer")
end

-- Create an icon collection attached to the map viewport.
function buttonIcon.New(parent)
    return setmetatable({
        parent = parent,
        markers = {},
        inputControls = {},
    }, buttonIcon)
end

-- Observe native presses without consuming or replacing their actions.
function buttonIcon:BindInput(rows)
    for _, row in ipairs(rows) do
        local control = row.click
        if control ~= nil then
            local function press()
                if not row.disabled and not row.locked then
                    self.pressedName = row.name
                end
                return true
            end
            local function release()
                if self.pressedName == row.name then
                    self.pressedName = nil
                end
                return true
            end
            self.inputControls[#self.inputControls + 1] = control
            control:Subscribe(ui.Hook.ONCLICK, pressHookID, press)
            control:Subscribe(ui.Hook.ONHOLD, pressHookID, press)
            control:Subscribe(ui.Hook.ONRELEASE, pressHookID, release)
            control:Subscribe(ui.Hook.ONMOUSELEAVE, pressHookID, release)
        end
    end
end

-- Destroy every marker and discard cached rendering state.
function buttonIcon:Destroy()
    local controls = self.inputControls
    self.inputControls, self.pressedName = {}, nil
    for _, control in ipairs(controls) do
        for _, hook in ipairs(pressHooks) do
            cleanup.Try("detach map icon press hook", function()
                control:Unsubscribe(ui.Hook[hook], pressHookID)
            end)
        end
    end

    for _, marker in pairs(self.markers) do
        destroyMarker(marker)
    end

    self.markers = {}
end

-- Use the same artwork precedence for map markers and slot navigation controls.
function buttonIcon.Source(icons, highlighted, disabled, locked)
    local normal = icons.normal or icons

    if locked then
        return icons.locked or normal, icons.dimWhenLocked ~= false
    end

    if disabled then
        return icons.disabled or normal, icons.disabled == nil
    end

    if highlighted then
        return icons.hovered or normal, false
    end

    return normal, false
end

-- Create or reuse a destination marker and apply its image, hover and disabled states.
function buttonIcon:GetMarker(name, icons, highlighted, disabled, locked, showLockWhenDisabled, hotkey, pressed)
    disabled = disabled or locked == true
    highlighted = highlighted and not disabled

    local marker = self.markers[name]
    local width, height = buttonIcon.Dimensions(icons, highlighted and not pressed)
    local source, dimmed = buttonIcon.Source(icons, highlighted, disabled, locked)
    local objectID = source.objectID
    local objectCount = source.objectCount or icons.objectCount or 1
    local kind = (source.modelID ~= nil or source.npcID ~= nil) and "model" or objectID ~= nil and "item" or "sprite"
    local image

    if kind == "sprite" then
        image = source.sprite

        if image == nil then
            image = source.image

            if not SpriteLayers.LoadImages(image) then
                return nil
            end
        end
    end

    if marker ~= nil and (marker.kind ~= kind or kind == "model" and marker.modelSource ~= source) then
        -- A new component type or model configuration needs a fresh subtree.
        destroyMarker(marker)
        self.markers[name], marker = nil, nil
    end

    if marker == nil then
        -- Shadows extend right and down; grow clipping containers rather than shrinking artwork.
        local padding = shadowPadding(icons, kind)
        local layer = prettyui.NewComponent(ui.Layer, self.parent, { categoryID = "auto" })
        layer:SetSize(width + padding, height + padding)
        layer.clickthrough = true

        local artwork = prettyui.NewComponent(ui.Layer, layer)
        artwork:SetSize(width + padding, height + padding)
        artwork.clickthrough = true

        marker = {
            layer = layer,
            artwork = artwork,
            kind = kind,
            width = width,
            height = height,
        }

        if kind == "model" then
            if source.npcID ~= nil then
                marker.model = Model3D.FromNPC(artwork, source.npcID, source.animID, source)
            else
                marker.model = Model3D.FromModel(artwork, source.modelID, source)
            end
            marker.model:SetSize(width, height)
            marker.modelSource = source
        elseif objectID ~= nil then
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
            marker.sprite = SpriteLayers.New(artwork, image, marker.bounds)
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

        if marker.model ~= nil then
            marker.model:SetSize(width, height)
        elseif marker.itemSprite ~= nil then
            marker.itemSprite:SetSize(width, height)
        else
            marker.sprite.root:SetSize(width, height)
            marker.bounds.width, marker.bounds.height = width, height

            if marker.shadowLayer ~= nil then
                marker.shadowLayer:SetSize(width + padding, height + padding)
            end
        end

        marker.width, marker.height = width, height

        if marker.lock ~= nil then
            marker.lock:Destroy()
            marker.lock = nil
        end
    end

    if marker.itemSprite ~= nil and (marker.objectID ~= objectID or marker.objectCount ~= objectCount) then
        marker.itemSprite.associatedObjectID = objectID
        marker.itemSprite.associatedObjectQuantity = objectCount
        marker.objectID, marker.objectCount = objectID, objectCount
        marker.highlighted, marker.dimmed = nil, nil
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

    if marker.dimmed ~= dimmed then
        if marker.model ~= nil then
            marker.model:SetAlpha(dimmed and 0.4 or 1)
        elseif marker.itemSprite ~= nil then
            marker.itemSprite.colour = dimmed
                and Vector4.new(0.45, 0.45, 0.45, 1.0) or Vector4.new(1.0, 1.0, 1.0, 1.0)
        else
            marker.sprite:SetAlpha(dimmed and 0.4 or 1.0)
        end

        marker.dimmed = dimmed
    end

    local showLock = (locked and (icons.locked == nil or icons.showLockIcon == true))
        or (disabled and showLockWhenDisabled == true)

    updateLock(marker, width, height, showLock)

    return marker
end

-- Position visible icons and hide markers for hidden, cropped-out or unavailable artwork.
function buttonIcon:Update(menu, hovered)
    self.generation = (self.generation or 0) + 1
    local generation = self.generation
    local width, height = self.parent.width, self.parent.height
    local reorder = self.hovered ~= hovered
    if self.pressedName ~= hovered then
        self.pressedName = nil
    end

    for _, row in ipairs(menu.rows) do
        local destination = row.destination
        local icons = destination.icons
        local x, y
        if not destination.hidden and icons ~= nil then
            x, y = buttonIcon.Position(menu.background, destination, width, height)
        end

        if x ~= nil then
            local marker = self:GetMarker(row.name, icons, row.name == hovered, row.disabled, row.locked,
                destination.showLockWhenDisabled, destination.hotkey, self.pressedName == row.name)

            if marker ~= nil then
                -- Let native layout keep the centre fixed during size changes.
                -- Compensate for the extra clipping space on the shadow's right/bottom.
                local padding = shadowPadding(icons, marker.kind)
                x, y = x + padding / 2, y + padding / 2
                if marker.centerX ~= x or marker.centerY ~= y then
                    marker.layer:SetPos(x, y, 0, 0, 0.5, 0.5)
                    marker.centerX, marker.centerY = x, y
                end

                if marker.visible ~= true then
                    marker.layer.hidden = false
                    reorder = true
                end

                marker.visible = true
                marker.generation = generation

                local options = marker.hotkeyOptions or { preserveOrder = true }
                marker.hotkeyOptions = options
                options.width, options.height = marker.width, marker.height
                options.offset, options.disabled = destination.hotkeyOffset, row.disabled
                options.hidden = row.locked or (icons.hotkeyOnHover and row.name ~= hovered)
                marker.hotkey:Update(marker.layer, options)
            end
        end
    end

    for _, marker in pairs(self.markers) do
        if marker.generation ~= generation and marker.visible ~= false then
            marker.layer.hidden = true
            marker.hotkey:Hide()
            marker.visible = false
        end
    end

    -- Reordering every marker and badge every Draw repeatedly shuffles the same
    -- native sibling list. Restore display order only when visibility/hover changes.
    if reorder then
        for _, row in ipairs(menu.rows) do
            local marker = self.markers[row.name]

            if marker ~= nil and marker.generation == generation then
                marker.layer:MoveToFront()
                marker.hotkey:MoveToFront()
            end
        end

        if hovered ~= nil and self.markers[hovered] ~= nil and self.markers[hovered].generation == generation then
            local marker = self.markers[hovered]
            marker.layer:MoveToFront()
            marker.hotkey:MoveToFront()
        end
    end

    self.hovered = hovered
end

return buttonIcon
