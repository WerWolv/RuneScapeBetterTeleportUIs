local destinations = require("definitions/teleport_maps")
local settings = require("definitions/constants")
local modalMap = require("impl/modal_map")
local mapGeometry = require("impl/map_geometry")
local userSettings = require("impl/settings")
local maxWidth = settings.maxWidth
local defaultShadowColor = settings.defaultShadowColor
local defaultShadowColorHovered = settings.defaultShadowColorHovered
local teleportMaps = {}

local function cleanText(text)
    return (text or "")
        :gsub("<[^>]*>", "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

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
    modalMap.Restore()
    activeDestinations = nil
end

local function showPreview(name, parent)
    local background = activeDestinations[name].background
    local image = background.sprites or background.sprite

    if image == nil then
        local backgrounds = Plugin.resources.backgrounds
        image = background.image and
            ((backgrounds and backgrounds[background.image]) or Plugin.resources[background.image])
        if image == nil then
            local message = "Image resource not found: " .. tostring(background.image) ..
                ".png (set image, sprite, or sprites; refresh PNG resources with prf)."
            if lastImageError ~= message then
                print(message)
                lastImageError = message
            end
            return false
        end
        if not image.loaded then
            local result = image:Load()
            if not image.loaded then
                local message = "Image load failed: " .. background.image .. ": " .. tostring(result)
                if lastImageError ~= message then
                    print(message)
                    lastImageError = message
                end
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
    local crop = mapGeometry.Bounds(background)
    local view = table.concat({
        background.width, background.height,
        crop.x, crop.y, 
        crop.width, crop.height
    }, ":")

    local imageWidth, imageHeight = modalMap.Fit(background, maxWidth)
    local width, height = imageWidth, imageHeight

    if previewWidth ~= width or previewHeight ~= height then
        previewWidth, previewHeight = width, height
        preview:SetSize(width, height)
        imageHost:SetSize(imageWidth, imageHeight)

        if previewImage ~= nil then
            previewImage:Destroy()
            previewImage = nil
        end
    end

    if previewImage ~= nil and (currentImage ~= image or currentView ~= view) then
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

local function findIconResource(root, name)
    if root == nil or name == nil then 
        return nil 
    end

    local resource = root
    for part in name:gmatch("[^/]+") do
        resource = resource[part]
        if resource == nil then return nil end
    end

    return resource
end

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

local function shadowRGBA(color)
    if type(color) == "number" then 
        return color
    end

    local function byte(value) 
        return math.floor(math.max(0, math.min(1, value)) * 255 + 0.5)     
    end

    return (byte(color.x) << 24) | (byte(color.y) << 16) | (byte(color.z) << 8) | byte(color.w)
end

local function getShadowColor(icons, highlighted, disabled)
    if disabled then return 0x00000000 end
    if highlighted then return icons.shadowColorHovered or defaultShadowColorHovered end
    return icons.shadowColor or defaultShadowColor
end

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

        local bounds = marker.bounds
        marker.shadow = prettyui.Sprite.new(marker.shadowLayer, image, {
            x = bounds.x + offset, 
            y = bounds.y + offset,
            width = bounds.width, 
            height = bounds.height, 
            colour = color,
        })

        marker.shadowImage, marker.shadowTint = image, color
        marker.shadowOffset = offset
    end
end

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
            local resourceName = source.image or (highlighted and source.highlighted or source.dimmed)
            image = findIconResource(Plugin.resources.icons, resourceName) or findIconResource(Plugin.resources, resourceName)

            if image ~= nil and not image.loaded then
                image:Load()
            end
            
            if image == nil or not image.loaded then
                return nil
            end
        end
    end

    if marker ~= nil and marker.kind ~= kind then
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
            marker.sprite = prettyui.Sprite.new(layer, image, marker.bounds)
            marker.image = image
        end

        markers[name] = marker
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

local collectionTypes = {
    [ui.ComponentType.LAYER] = true,
    [ui.ComponentType.PANEL] = true,
    [ui.ComponentType.GRID] = true,
    [ui.ComponentType.PAGED_LAYER] = true,
    [ui.ComponentType.PAGED_CAROUSEL] = true,
    [ui.ComponentType.GROUP_BOX] = true,
}

local function collectLabels(component, labels, visited)
    local key = table.concat({
        component.interfaceID,
        component.staticID,
        component.categoryID,
        component.dynamicID,
    }, ":")

    if visited[key] or not component.visibleGlobal then
        return
    end
    visited[key] = true

    local text
    if component.type == ui.ComponentType.LABEL then
        text = component.content
    elseif component.type == ui.ComponentType.BUTTON then
        text = component.label
    end

    text = cleanText(text)
    if text ~= "" then
        labels[text] = true
    end

    if collectionTypes[component.type] then
        local function visit(child)
            collectLabels(child, labels, visited)
            return false
        end

        component:IterateStaticComponents(visit)
        component:IterateDynamicComponents(visit)
    end
end

local lastLayoutError

local function draw()
    local ok, message = pcall(
        function()
            local menu = modalMap.ReadRows(collectLabels, destinations)
            if menu == nil then
                releaseModal()
                selectedDestination, hoveredDestination = nil, nil
                return
            end

            if not modalMap.Matches(menu) then
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
        releaseModal()
        message = tostring(message)
        if message ~= lastLayoutError then
            print("Unable to embed teleport map: " .. message)
            lastLayoutError = message
        end
    end
end

function teleportMaps.Start()
    Event.Draw.Subscribe("destinationPreview", draw)
end

function teleportMaps.Stop()
    Event.Draw.Unsubscribe("destinationPreview")
    releaseModal()
end

return teleportMaps
