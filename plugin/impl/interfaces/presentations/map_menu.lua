local geometry = require("impl/map_geometry")
local mapCrop = require("impl/map_crop")
local BackgroundView = require("impl/ui/background_view")
local ButtonIcon = require("impl/ui/button_icon")
local constants = require("definitions/constants")
local cleanup = require("impl/cleanup")

local MapMenu = {}
local hitboxScale = 0.75

function MapMenu:ValidateDestination(definition, background)
    local entryBackground = definition.background or self.definition.background
    local icons = definition.icons or self.definition.icons

    if definition.point == nil or icons == nil or entryBackground == nil then
        return false, "needs point, icons and background (including group defaults)"
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
    local rectangles = {}

    for _, entry in ipairs(session.rows) do
        local destination = entry.destination
        local hitWidth, hitHeight = 0, 0
        local x, y

        if not destination.hidden then
            local iconWidth, iconHeight = ButtonIcon.Dimensions(destination.icons)

            hitWidth = math.max(1, math.floor(iconWidth * hitboxScale))
            hitHeight = math.max(1, math.floor(iconHeight * hitboxScale))
            x, y = geometry.Project(destination.background, destination.point, width, height)
        end

        if x == nil then
            x, y, hitWidth, hitHeight = 0, 0, 0, 0
        else
            x, y = x - hitWidth / 2, y - hitHeight / 2
        end

        rectangles[#rectangles + 1] = {
            entry = entry, x = imagePosition.x + x, y = imagePosition.y + y,
            width = hitWidth, height = hitHeight,
        }
    end
    self:LayoutRows(rectangles, width, height)
end

function MapMenu:GetHovered()
    local menu = self.session.menu

    for _, entry in ipairs(menu.rows) do
        local destination = entry.destination

        if not entry.locked and not destination.hidden and entry.click.visibleGlobal and entry.click.isMouseOver
            and geometry.Contains(menu.background, destination.point) then
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
end

-- The adapter owns discovery, availability, native geometry and restoration.
-- Presentation owns validation, layout and passive artwork; menus supply Define().
function MapMenu.Create(interface, key)
    local class = interface:Extend(key)
    for name, method in pairs(MapMenu) do
        if name ~= "Create" then class[name] = method end
    end
    return class
end

return MapMenu
