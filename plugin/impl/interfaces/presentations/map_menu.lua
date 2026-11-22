local geometry = require("impl/map_geometry")
local mapCrop = require("impl/map_crop")
local BackgroundView = require("impl/ui/background_view")
local ButtonIcon = require("impl/ui/button_icon")
local constants = require("definitions/constants")
local cleanup = require("impl/cleanup")
local NativeLayout = require("impl/interfaces/native/native_layout")
local MapLabels = require("impl/ui/map_labels")
local settings = require("impl/settings")
local HotkeyBadge = require("impl/ui/hotkey_badge")
local text = require("impl/text")
local labelSettings = require("impl/map_label_settings")

local MapMenu = {}
local hitboxScale = 0.75

function MapMenu:GetHighlightKey(row)
    return row.destination.highlightKey
        or (text.Clean(self:GetDisplayName(row)):gsub("^%d+%.%s*", ""):gsub("%.$", ""))
end

function MapMenu:MatchesHighlightKey(row, key)
    if self:GetHighlightKey(row) == key or row.entryKey == key then return true end
    if type(key) ~= "string" and type(key) ~= "number" then return false end

    local requested = text.Trim(tostring(key)):lower()
    local name = text.Clean(self:GetDisplayName(row)):gsub("^%d+%.%s*", ""):gsub("%.$", "")
    local shortcut = row.destination.hotkey or (row.native and row.native.shortcut) or text.Hotkey(row.name)
    return requested == name:lower()
        or (not row.locked and shortcut ~= nil and requested == text.Trim(tostring(shortcut)):lower())
end

function MapMenu:BeginHighlight(key)
    local row, reason = self:FindHighlightTarget(key)
    if row == nil then return nil, reason end
    row.highlightCount = (row.highlightCount or 0) + 1
    return { target = row }
end

function MapMenu:EndHighlight(state)
    state.target.highlightCount = state.target.highlightCount - 1
end

function MapMenu:ValidateDestination(definition, background)
    local entryBackground = definition.background or self.definition.background
    local icons = definition.icons or self.definition.icons

    if definition.anchor ~= nil and not ButtonIcon.IsAnchor(definition.anchor) then
        return false, "needs a topLeft, topRight, bottomLeft or bottomRight anchor"
    end

    if (definition.point == nil and definition.anchor == nil) or icons == nil or entryBackground == nil then
        return false, "needs point or anchor, icons and background (including group defaults)"
    end

    if background ~= nil and entryBackground ~= background then
        return false, "uses a different background from the other visible entries"
    end

    return true
end

function MapMenu:BeginVisuals()
    mapCrop.Attach(self.session.menu)
    self.backgroundView = BackgroundView.New(self.session.content)
    self.iconView = ButtonIcon.New(self.backgroundView.layer)
    self.nameLabels = MapLabels.New(self.backgroundView.layer)
    self.iconView:BindInput(self.session.menu.rows)
    self.tooltipProbes = {}
    for index, row in ipairs(self.session.menu.rows) do
        self.tooltipProbes[row.name] = {
            target = self.session.tooltips[row.name] and self:GetTooltipTarget(row, index) or nil,
            description = self:GetDescription(row),
            title = self:GetDisplayName(row),
        }
    end
end

-- Supply the header's minimum width to the crop, then scale uniformly within the host.
function MapMenu:CalculateLayout(reservedWidth)
    local session = self.session

    self:UpdateTitle()

    local header = self:HeaderLayout()
    local minWidth = math.max(1, header.width - session.left - session.right)

    session.menu.cropMinWidth = nil

    local availableWidth = (session.layoutWidth or session.layoutParent.width) - (reservedWidth or 0)
    local availableHeight = session.layoutHeight or session.layoutParent.height
    local maxWidth = math.min(
        math.max(constants.maxWidth * self:GetSizeMultiplier(), minWidth),
        availableWidth - session.left - session.right - 16
    )
    local maxHeight = availableHeight - session.top - session.bottom - 16
    mapCrop.SetViewport(session.menu, maxWidth, maxHeight)
    local crop = geometry.Bounds(session.menu.background)
    local scale = math.min(
        maxWidth / crop.width,
        maxHeight / crop.height
    )

    session.menu.cropMinWidth = math.ceil(minWidth / scale)
    crop = geometry.Bounds(session.menu.background)
    scale = math.min(scale, maxWidth / crop.width)

    local width = math.max(1, math.floor(crop.width * scale))

    local result = {
        width = width,
        height = math.max(1, math.floor(crop.height * scale)),

        -- Reserve header space without stretching narrow map artwork.
        contentWidth = math.max(width, math.min(math.ceil(minWidth), math.floor(maxWidth))),
    }
    return self:ExpandNameLabelCrop(result, reservedWidth or 0)
end

-- Test unused source-image space at the current zoom before hiding edge labels.
-- Start from the normal crop every frame so filters/settings cannot accumulate growth.
function MapMenu:TryExpandNameLabelCrop(layout, reservedWidth, allowWrap, uniformOnly)
    local menu, session = self.session.menu, self.session
    local source = menu.cropSource
    if source == nil then return layout, true end
    local crop = geometry.Bounds(menu.background)
    local items, obstacles = self:NameLabelItems(layout, menu.background)
    local positions, measured = self.nameLabels:Plan(items, obstacles, layout.width, layout.height, nil, allowWrap, uniformOnly)
    local function count(placed, entries)
        if not placed then return 0 end
        local total = 0
        for index = 1, #entries do
            if placed[index] then total = total + 1 end
        end
        return total
    end
    local visible = count(positions, measured)
    if visible == #measured then return layout, true end

    local viewport = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__VIEWPORT)
    local padding = session.hostPadding or {}
    local maxWidth = viewport and viewport.width - (padding.width or 0) - session.left - session.right
        - reservedWidth - 16 or layout.width
    local maxHeight = viewport and viewport.height - (padding.height or 0) - session.top - session.bottom - 16
        or layout.height
    local sx, sy = layout.width / crop.width, layout.height / crop.height
    local extraWidth, extraHeight = math.max(0, maxWidth - layout.width), math.max(0, maxHeight - layout.height)
    local margins = {
        left = math.min(crop.x * sx, extraWidth),
        right = math.min((source.width - crop.x - crop.width) * sx, extraWidth),
        top = math.min(crop.y * sy, extraHeight),
        bottom = math.min((source.height - crop.y - crop.height) * sy, extraHeight),
    }
    if margins.left + margins.right + margins.top + margins.bottom == 0 then return layout end
    local edgePadding = MapLabels.expansionPadding
    for side, amount in pairs(margins) do
        margins[side] = amount - edgePadding
    end
    positions = self.nameLabels:Plan(items, obstacles, layout.width, layout.height, margins, allowWrap, uniformOnly)
    if count(positions, measured) <= visible then return layout end

    local growth = { left = 0, right = 0, top = 0, bottom = 0 }
    for index = 1, #measured do
        local rect = positions[index]
        if rect then
            growth.left = math.max(growth.left, edgePadding - rect.x)
            growth.top = math.max(growth.top, edgePadding - rect.y)
            growth.right = math.max(growth.right, rect.x + rect.width + edgePadding - layout.width)
            growth.bottom = math.max(growth.bottom, rect.y + rect.height + edgePadding - layout.height)
        end
    end
    -- Allow for conversion to whole source pixels and reprojected icon rounding.
    for side, amount in pairs(growth) do
        if amount > 0 then growth[side] = amount + math.max(sx, sy) + 2 end
    end
    local expanded, width, height = mapCrop.Grow(source, crop, layout.width, layout.height, growth, maxWidth, maxHeight)
    local background = { width = source.width, height = source.height, crop = expanded }
    local proposed = { width = width, height = height }
    items, obstacles = self:NameLabelItems(proposed, background)
    local inset = { left = -edgePadding, right = -edgePadding, top = -edgePadding, bottom = -edgePadding }
    local nextPositions, nextMeasured = self.nameLabels:Plan(items, obstacles, width, height, inset, allowWrap, uniformOnly)
    if count(nextPositions, nextMeasured) > visible then
        menu.labelCrop = expanded
        layout.width, layout.height = width, height
        layout.contentWidth = math.max(layout.contentWidth or 0, width)
        return layout, true
    end
    return layout
end

function MapMenu:ExpandNameLabelCrop(layout, reservedWidth)
    if not labelSettings.Enabled(self.definition) then return layout end
    -- Expand while labels still share one direction. Only then allow individual
    -- moves, and finally word wrapping if the single-line layouts still fail.
    for _, stage in ipairs({ { false, true }, { false, false }, { true, false } }) do
        local done
        layout, done = self:TryExpandNameLabelCrop(layout, reservedWidth, stage[1], stage[2])
        if done then break end
    end
    return layout
end

function MapMenu:ApplyLayout(layout)
    local session = self.session
    local width, height = layout.width, layout.height

    self.backgroundView:Show(session.menu.background, width, height, self.definition.vignette)

    local contentWidth = layout.contentWidth or width

    self:LayoutWindow(contentWidth, height)
    self.backgroundView.layer:SetPos(math.floor((contentWidth - width) / 2), 0)

    local imagePosition = self.backgroundView.layer.xyGlobal
    local rectangles = session.rowRectangles or {}
    session.rowRectangles = rectangles

    for index, entry in ipairs(session.rows) do
        local destination = entry.destination
        local hitWidth, hitHeight = 0, 0
        local x, y

        if not destination.hidden then
            local iconWidth, iconHeight = ButtonIcon.Dimensions(destination.icons)

            hitWidth = math.max(1, math.floor(iconWidth * hitboxScale))
            hitHeight = math.max(1, math.floor(iconHeight * hitboxScale))
            x, y = ButtonIcon.Position(session.menu.background, destination, width, height)
        end

        if x == nil then
            x, y, hitWidth, hitHeight = 0, 0, 0, 0
        else
            x, y = x - hitWidth / 2, y - hitHeight / 2
        end

        local rectangle = rectangles[index] or { entry = entry }
        rectangle.x, rectangle.y = imagePosition.x + x, imagePosition.y + y
        rectangle.width, rectangle.height = hitWidth, hitHeight
        rectangles[index] = rectangle
    end

    self:LayoutRows(rectangles, width, height)
    self:LayoutTooltipProbes(layout)
end

-- Unavailable destinations use passive hover targets, including entries with no native row.
function MapMenu:LayoutTooltipProbes(layout)
    for index, row in ipairs(self.session.menu.rows) do
        local destination = row.destination
        local probe = self.tooltipProbes[row.name]
        local unavailable = row.disabled or row.locked
        local x, y
        if not destination.hidden then
            x, y = ButtonIcon.Position(self.session.menu.background, destination, layout.width, layout.height)
        end
        local visible = x ~= nil

        if unavailable and visible then
            if probe.control == nil then
                probe.control = prettyui.NewComponent(ui.Layer, self.backgroundView.layer)
                probe.control.enabled = true
            end
            local width, height = ButtonIcon.Dimensions(destination.icons)
            width, height = math.max(1, math.floor(width * hitboxScale)), math.max(1, math.floor(height * hitboxScale))
            x, y = math.floor(x - width / 2), math.floor(y - height / 2)
            if probe.x ~= x or probe.y ~= y then
                probe.control:SetPos(x, y)
                probe.x, probe.y = x, y
            end
            if probe.width ~= width or probe.height ~= height then
                probe.control:SetSize(width, height)
                probe.width, probe.height = width, height
            end
        end

        local target
        if visible then
            if unavailable then
                target = probe.control
            else
                target = self:GetTooltipTarget(row, index)
            end
        end
        local description, title = self:GetDescription(row), self:GetDisplayName(row)
        if probe.target ~= target or probe.description ~= description or probe.title ~= title then
            local tooltip = self.session.tooltips[row.name]
            if tooltip ~= nil then
                tooltip:Destroy()
                self.session.tooltips[row.name] = nil
            end
            if target ~= nil then
                self:AttachTooltip(row, target)
            end
            probe.target, probe.description, probe.title = target, description, title
        end

        if probe.control ~= nil then
            probe.control.hidden = not unavailable or not visible
            probe.control.clickthrough = not unavailable
        end
        -- Tooltip teardown can restore clickthrough; apply it after switching targets.
        if row.click ~= nil and (unavailable or probe.control ~= nil) then
            NativeLayout.Set(row.click, "clickthrough", unavailable == true)
        end
    end
end

function MapMenu:GetHovered()
    local menu = self.session.menu

    for _, entry in ipairs(menu.rows) do
        local destination = entry.destination
        local probe = self.tooltipProbes[entry.name]
        local target = (entry.disabled or entry.locked) and probe and probe.control or entry.click

        if target ~= nil and not target.hidden and not destination.hidden and target.visibleGlobal and target.isMouseOver
            and (ButtonIcon.IsAnchor(destination.anchor)
                or (destination.point ~= nil and geometry.Contains(menu.background, destination.point))) then
            return entry.name
        end
    end
end

function MapMenu:UpdateVisuals(layout, hovered)
    self.iconView:Update(self.session.menu, hovered)
    self:UpdateNameLabels(layout)

    local vignette = self.backgroundView.vignette

    if vignette ~= nil then
        vignette:MoveToFront()
    end

    self:UpdateTooltips(hovered)
end

function MapMenu:NameLabelItems(layout, background, visibleOnly)
    local items, obstacles = {}, {}
    for _, row in ipairs(self.session.menu.rows) do
        local marker = self.iconView.markers[row.name]
        local destination = row.destination
        local x, y
        if not destination.hidden and (not visibleOnly or marker ~= nil and marker.visible) then
            x, y = ButtonIcon.Position(background, destination, layout.width, layout.height)
        end
        if x ~= nil then
            local width, height = ButtonIcon.Dimensions(destination.icons)
            local normalWidth, normalHeight = width, height
            local hoverWidth, hoverHeight = ButtonIcon.Dimensions(destination.icons, true, true)
            -- Reserve maximum artwork bounds so hover, press and API highlights never move names.
            width, height = math.max(width, hoverWidth), math.max(height, hoverHeight)
            local bounds = { x = x - width / 2, y = y - height / 2, width = width, height = height }
            if destination.icons.showName == false then
                obstacles[#obstacles + 1] = bounds
            else
                items[#items + 1] = {
                    key = row.name, name = self:GetDisplayName(row),
                    anchor = bounds,
                    alpha = (marker and marker.dimmed and 0.4 or 1)
                        * (destination.searchMatch == false and 0.2 or 1) * (marker and marker.focusAlpha or 1),
                }
            end
            local key = destination.hotkey or text.Hotkey(row.name)
            if settings.Get("showTeleportHotkeys") and not row.locked and key ~= nil and tostring(key) ~= "" then
                local size = HotkeyBadge.Size(key, normalWidth)
                local offset = destination.hotkeyOffset
                obstacles[#obstacles + 1] = {
                    x = x - size / 2 + (offset and (offset.x or 0) or normalWidth / 2),
                    y = y - size / 2 + (offset and (offset.y or 0) or -normalHeight / 2),
                    width = size, height = size,
                }
            end
        end
    end
    return items, obstacles
end

function MapMenu:UpdateNameLabels(layout)
    if not labelSettings.Enabled(self.definition) then
        self.nameLabels:Hide()
        return
    end
    local items, obstacles = self:NameLabelItems(layout, self.session.menu.background, true)
    self.nameLabels:Update(items, obstacles, layout.width, layout.height,
        self.session.menu.labelCrop and MapLabels.expansionPadding or 0)
end

function MapMenu:ReleaseVisuals()
    self:ReleaseTooltips()
    cleanup.Release(self, "iconView")
    cleanup.Release(self, "nameLabels")
    cleanup.Release(self, "backgroundView")
    self.tooltipProbes = nil
end

-- The adapter owns discovery, availability, native geometry and restoration.
-- Presentation owns validation, layout and passive artwork; menus supply Define().
function MapMenu.Create(interface, key)
    local class = interface:Extend(key)
    for name, method in pairs(MapMenu) do
        if name ~= "Create" then
            class[name] = method
        end
    end
    return class
end

return MapMenu
