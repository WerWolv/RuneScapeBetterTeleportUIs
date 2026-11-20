local geometry = require("impl/map_geometry")
local mapCrop = require("impl/map_crop")
local BackgroundView = require("impl/ui/background_view")
local ButtonIcon = require("impl/ui/button_icon")
local constants = require("definitions/constants")
local cleanup = require("impl/cleanup")
local NativeLayout = require("impl/interfaces/native/native_layout")

local MapMenu = {}
local hitboxScale = 0.75

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
function MapMenu:CalculateLayout()
    local session = self.session

    self:UpdateTitle()

    local header = self:HeaderLayout()
    local minWidth = math.max(1, header.width - session.left - session.right)

    session.menu.cropMinWidth = nil

    local availableWidth = session.layoutWidth or session.layoutParent.width
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

    return {
        width = width,
        height = math.max(1, math.floor(crop.height * scale)),

        -- Reserve header space without stretching narrow map artwork.
        contentWidth = math.max(width, math.min(math.ceil(minWidth), math.floor(maxWidth))),
    }
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

    local vignette = self.backgroundView.vignette

    if vignette ~= nil then
        vignette:MoveToFront()
    end

    self:UpdateTooltips(hovered)
end

function MapMenu:ReleaseVisuals()
    self:ReleaseTooltips()
    cleanup.Release(self, "iconView")
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
