local destinations = require("definitions/teleport_maps")
local constants = require("definitions/constants")
local modalMap = require("impl/modal_map")
local mapGeometry = require("impl/map_geometry")
local utils = require("impl/utils")
local userSettings = require("impl/settings")
local maxWidth = constants.maxWidth
local defaultShadowColor = constants.defaultShadowColor
local defaultShadowColorHovered = constants.defaultShadowColorHovered
local teleportMaps = {}

local preview
local imageHost
local previewImage
local markers = {}
local currentImage
local currentView
local selectedDestination
local activeDestinations
local hoveredDestination
local previewWidth, previewHeight = 0, 0
local lastImageError

-- Report an image error only when it differs from the last failure.
local function reportImageError(message)
    if message ~= lastImageError then
        print(message)
        lastImageError = message
    end
end

-- Lazily create the map layers inside the modal content.
local function ensurePreview(parent)
    if preview ~= nil then
        return true
    end

    if parent == nil then
        return false
    end

    preview = ui.Layer.new(parent)
    preview:SetSize(maxWidth, maxWidth)

    preview.hidden = true
    preview.clickthrough = true

    imageHost = ui.Layer.new(preview)
    imageHost:SetPos(0, 0)
    imageHost.clickthrough = true

    return true
end

-- Destroy plugin-owned artwork and release the modal session.
local function releaseModal()
    -- The client may already have destroyed the modal when it closes.
    if previewImage ~= nil then
        pcall(function() previewImage:Destroy() end)
    end

    for _, marker in pairs(markers) do
        if marker.shadow ~= nil then
            pcall(function() marker.shadow:Destroy() end)
        end
        if marker.sprite ~= nil then
            pcall(function() marker.sprite:Destroy() end)
        end
    end

    if preview ~= nil then
        pcall(function() preview:Destroy() end)
    end

    preview, imageHost, previewImage, currentImage = nil, nil, nil, nil
    currentView = nil
    markers = {}
    previewWidth, previewHeight = 0, 0
    modalMap.Release()
    activeDestinations, selectedDestination, hoveredDestination = nil, nil, nil
end

-- Resolve and draw the selected background, rebuilding only when its source or layout changes.
local function showPreview(name, parent)
    local background = activeDestinations[name].background
    -- Built-in sprites take precedence over disk resources and need no explicit loading.
    local image = background.sprites or background.sprite

    if image == nil then
        image = background.image
        if image == nil then
            reportImageError("Background resource missing for " .. name ..
                " (set image to a Plugin.resources reference, or use sprite/sprites; refresh resources with prf).")
            return false
        end
        if not image.loaded then
            local result = image:Load()
            if not image.loaded then
                reportImageError("Image load failed: " .. tostring(image.path) .. ": " .. tostring(result))
            end
        end
        if not image.loaded then
            return false
        end
    end

    if not ensurePreview(parent) then
        return false
    end

    lastImageError = nil
    -- Include crop coordinates in the cache key so panning a same-sized crop still redraws it.
    local crop = mapGeometry.Bounds(background)
    local view = table.concat({
        background.width, background.height,
        crop.x, crop.y, 
        crop.width, crop.height
    }, ":")

    local imageWidth, imageHeight = modalMap.Fit(background, maxWidth)
    local resized = previewWidth ~= imageWidth or previewHeight ~= imageHeight
    if resized then
        previewWidth, previewHeight = imageWidth, imageHeight
        preview:SetSize(imageWidth, imageHeight)
        imageHost:SetSize(imageWidth, imageHeight)
    end

    if previewImage ~= nil and (resized or currentImage ~= image or currentView ~= view) then
        previewImage:Destroy()
        previewImage = nil
    end

    if previewImage == nil and background.sprites ~= nil then
        local grid = background.sprites
        assert(type(grid) == "table" and #grid > 0, "Background sprites must contain rows")

        local columns = type(grid[1]) == "table" and #grid[1] or 0
        assert(columns > 0, "Each background sprite row must be a non-empty table")

        for _, row in ipairs(grid) do
            assert(type(row) == "table" and #row == columns, "Background sprite rows must have equal lengths")
            for _, spriteID in ipairs(row) do
                assert(type(spriteID) == "number", "Background tiles must be numeric sprite IDs")
            end
        end

        previewImage = ui.Layer.new(imageHost)
        previewImage:SetSize(imageWidth, imageHeight)
        previewImage.clickthrough = true

        -- Make sure backgrounds that consist of multiple sprites don't have visible gaps between them.
        for rowIndex, row in ipairs(grid) do
            for columnIndex, spriteID in ipairs(row) do
                local left, top, tileWidth, tileHeight = mapGeometry.Rectangle(background,
                    (columnIndex - 1) * background.width / columns,
                    (rowIndex - 1) * background.height / #grid,
                    background.width / columns, background.height / #grid,
                    imageWidth, imageHeight)
                local tile = ui.Sprite.new(previewImage)
                tile:SetPos(left, top)
                tile:SetSize(tileWidth, tileHeight)
                tile.spriteID = spriteID
                tile.clickthrough = true
            end
        end
    elseif previewImage == nil then
        if background.crop ~= nil then
            local viewport = ui.Layer.new(imageHost)
            viewport:SetSize(imageWidth, imageHeight)
            viewport.clickthrough = true

            local x, y, fullWidth, fullHeight = mapGeometry.Rectangle(
                background,
                0, 0, 
                background.width, background.height, 
                imageWidth, imageHeight
            )
            local sprite = prettyui.Sprite.new(viewport, image, {
                x = x, 
                y = y, 
                width = fullWidth, 
                height = fullHeight,
            })

            previewImage = {
                Destroy = function()
                    sprite:Destroy()
                    viewport:Destroy()
                end
            }
        else
            previewImage = prettyui.Sprite.new(imageHost, image, {
                width = imageWidth, 
                height = imageHeight,
            })
        end
    end

    currentImage = image
    currentView = view
    preview.hidden = false
    preview:MoveToFront()

    return true
end

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
        height = height
    }
end

-- Convert Vector4 shadow colors to packed RGBA, leaving existing hex values unchanged.
local function shadowRGBA(color)
    if type(color) == "number" then 
        return color
    end

    -- Convert one normalized color channel into a clamped byte.
    local function byte(value) 
        return math.floor(math.max(0, math.min(1, value)) * 255 + 0.5)     
    end

    return (byte(color.x) << 24) | (byte(color.y) << 16) | (byte(color.z) << 8) | byte(color.w)
end

-- Choose the normal or hovered shadow color, suppressing shadows for disabled destinations.
local function getShadowColor(icons, highlighted, disabled)
    if disabled then return 0x00000000 end
    if highlighted then return icons.shadowColorHovered or defaultShadowColorHovered end
    return icons.shadowColor or defaultShadowColor
end

-- Maintain a tinted, offset copy behind non-item icons for their current shadow state.
local function updateSpriteShadow(marker, image, icons, highlighted, disabled, size)
    if icons.shadowColor == nil and icons.shadowColorHovered == nil then
        return
    end

    if marker.shadowLayer == nil then
        marker.shadowLayer = ui.Layer.new(marker.layer)
        marker.shadowLayer:SetSize(size, size)
        marker.shadowLayer.clickthrough = true
        marker.shadowLayer:MoveToBack()
    end
    
    local color = shadowRGBA(getShadowColor(icons, highlighted, disabled))
    marker.shadowLayer.hidden = (color & 0xFF) == 0
    if marker.shadowLayer.hidden then return end

    local offset = highlighted and 2 or 1
    if marker.shadow == nil or marker.shadowImage ~= image or marker.shadowTint ~= color
        or marker.shadowOffset ~= offset then
        if marker.shadow ~= nil then 
            marker.shadow:Destroy()
        end

        local options = utils.deepcopy(marker.bounds)
        options.x = options.x + offset
        options.y = options.y + offset
        options.colour = color
        marker.shadow = prettyui.Sprite.new(marker.shadowLayer, image, options)

        marker.shadowImage, marker.shadowTint = image, color
        marker.shadowOffset = offset
    end
end

-- Show the original option's numeric prefix at the icon's top-right when enabled in settings.
local function updateHotkey(marker, name, size, disabled)
    local hotkey = name:match("^%s*(%d+)%.")
    if not userSettings.Get("showTeleportHotkeys") or hotkey == nil then
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

-- Create or reuse a destination marker and apply its image, hover and disabled states.
local function getMarker(name, icons, highlighted, disabled)
    highlighted = highlighted and not disabled
    local marker = markers[name]
    local size = icons.size or 48
    local normal = icons.normal or icons
    local source = highlighted and (icons.hovered or normal) or normal
    local objectID = source.objectID
    local kind = objectID ~= nil and "item" or "sprite"
    local image

    if objectID == nil then
        image = source.sprite
        if image == nil then
            image = source.image

            if image ~= nil and not image.loaded then
                image:Load()
            end
            
            if image == nil or not image.loaded then
                return nil
            end
        end
    end

    if marker ~= nil and marker.kind ~= kind then
        -- Switching between inventory items and ordinary sprites requires a new component type.
        if marker.shadow ~= nil then marker.shadow:Destroy() end
        if marker.sprite ~= nil then marker.sprite:Destroy() end

        marker.layer:Destroy()
        markers[name] = nil
        marker = nil
    end

    if marker == nil then
        local layer = ui.Layer.new(imageHost)
        layer:SetSize(size, size)
        layer.clickthrough = true
        marker = {layer = layer, kind = kind}

        if objectID ~= nil then
            local sprite = ui.Sprite.new(layer)
            sprite:SetSize(size, size)
            sprite.associatedObjectID = objectID
            sprite.associatedObjectQuantity = 1
            sprite.associatedObjectQuantityMode = ui.ObjectQuantityDisplayMode.NEVER
            sprite.clickthrough = true
            marker.itemSprite = sprite
            marker.objectID = objectID
        else
            marker.bounds = iconBounds(source, icons, size)
            marker.sprite = prettyui.Sprite.new(layer, image, utils.deepcopy(marker.bounds))
            marker.image = image
        end

        markers[name] = marker
    end

    if marker.itemSprite ~= nil and marker.objectID ~= objectID then
        marker.itemSprite.associatedObjectID = objectID
        marker.objectID = objectID
        -- Reapply styling after swapping the associated inventory item.
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
        marker.highlighted = highlighted
        marker.shadowColor = shadowColor
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
                and Vector4.new(0.45, 0.45, 0.45, 1.0)
                or Vector4.new(1.0, 1.0, 1.0, 1.0)
        else
            marker.layer.alpha = disabled and 0.4 or 1.0
        end
        marker.disabled = disabled
    end

    updateHotkey(marker, name, size, disabled)

    return marker
end

-- Position visible destination icons on the active map and hide unused or cropped-out markers.
local function updateMarkers(rows)
    for _, marker in pairs(markers) do
        marker.layer.hidden = true
    end

    if preview == nil or preview.hidden then
        return
    end

    local background = activeDestinations[selectedDestination].background
    for _, row in ipairs(rows) do
        local name = row.name
        local destination = activeDestinations[name]
        local icons, point = destination.icons, destination.point

        if not row.hidden and destination.background == background and icons ~= nil and point ~= nil
            and mapGeometry.Contains(background, point) then

            local marker = getMarker(name, icons, name == hoveredDestination, row.disabled)
            if marker ~= nil then
                local size = icons.size or 48

                local x, y = mapGeometry.Project(background, point, imageHost.width, imageHost.height)
                marker.layer:SetPos(
                    x - size / 2, y - size / 2)
                marker.layer.hidden = false
                marker.layer:MoveToFront()
            end
        end
    end

    if hoveredDestination ~= nil and markers[hoveredDestination] ~= nil then
        markers[hoveredDestination].layer:MoveToFront()
    end
end

local lastLayoutError

-- Match the current menu and update its map, hitboxes, markers and tooltip each frame.
local function draw()
    local ok, message = pcall(
        function()
            local menu = modalMap.ReadRows(destinations)
            if menu == nil then
                releaseModal()
                return
            end

            if not modalMap.Matches(menu) then
                -- Release the previous session before attaching to a different interface or option set.
                releaseModal()
                modalMap.Begin(menu)
                selectedDestination = menu.defaultDestination
            end

            activeDestinations = menu.destinations
            hoveredDestination = modalMap.Hovered(menu)
            selectedDestination = hoveredDestination or selectedDestination

            if not showPreview(selectedDestination, menu.content) then
                releaseModal()
                return
            end

            modalMap.Layout(previewWidth, previewHeight, imageHost, activeDestinations)
            updateMarkers(menu.rows)
            modalMap.UpdateTooltip(hoveredDestination)
            lastLayoutError = nil
        end
    )
    
    if not ok then
        -- Leave the original menu usable if any part of the custom layout fails.
        releaseModal()
        message = tostring(message)
        if message ~= lastLayoutError then
            print("Unable to embed teleport map: " .. message)
            lastLayoutError = message
        end
    end
end

-- Subscribe the renderer to the client's draw event.
function teleportMaps.Start()
    Event.Draw.Subscribe("destinationPreview", draw)
end

-- Stop rendering and remove plugin-owned UI when the plugin unloads.
function teleportMaps.Stop()
    Event.Draw.Unsubscribe("destinationPreview")
    releaseModal()
end

return teleportMaps
