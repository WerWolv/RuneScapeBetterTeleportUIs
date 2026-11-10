local BackgroundView = require("impl/ui/background_view")
local HotkeyBadge = require("impl/ui/hotkey_badge")
local components = require("impl/ui/components")
local geometry = require("impl/map_geometry")
local backgrounds = require("definitions/backgrounds")
local teleportTooltip = require("impl/ui/teleport_tooltip")
local TextFieldAutofocus = require("impl/ui/text_field_autofocus")
local ScrollInput = require("impl/ui/scroll_input")
local settings = require("impl/settings")
local text = require("impl/text")
local cleanup = require("impl/cleanup")

local View = {}
View.__index = View

local markerWidth, markerHeight = 44, 48
local iconSize, hoveredIconSize = 32, 34
local selectedOutlineWidth = 3
local markerTopPadding = selectedOutlineWidth + (hoveredIconSize - iconSize) / 2
-- Anchor badges to the normal icon's top-right corner within the fixed marker.
local markerHotkeyOffset = {
    x = iconSize / 2,
    y = markerTopPadding - (markerHeight + markerTopPadding) / 2,
}
local listRowHeight, compactListRowHeight, listRowGap = 44, 26, 2

function View.New(parent, tooltipLayer)
    local root = ui.Layer.new(parent)
    root.clickthrough = true

    return setmetatable({
        root = root,
        tooltipLayer = tooltipLayer,
        items = {},
        contexts = {},
    }, View)
end

function View:Build()
    self.background = BackgroundView.New(self.root)
    self.search = prettyui.TextField.new(self.root, {
        placeholder = "Search destinations or codes...",
        height = 28,
        maxLength = 80,
        contentMargin = ui.Margin.new(32, 3, 8, 0),
    })
    self.searchIcon = ui.Sprite.new(self.root)
    self.searchIcon.spriteID = id.Sprite.AIF_SEARCH_ICON_0
    self.searchIcon:SetSize(24, 24)
    self.searchIcon.clickthrough = true
    self.heading = components.CenteredLabel(self.root, id.Font.MUSEO_SANS_13PT_BOLD)
    self.heading.content = "Other destinations"
    self.separators = {}

    for _, colour in ipairs({ 0x24180FFF, 0x3D2B1BFF }) do
        local line = ui.Rectangle.new(self.root)
        line.fill = true
        line.rgba = colour
        line.clickthrough = true
        self.separators[#self.separators + 1] = line
    end

    self.list = prettyui.SimpleView.new(self.root, {
        width = 240,
        height = 200,
        layout = {
            padding = 0,
            startY = 0,
            rowGap = 0,
        },
    })
    -- The list provides scrolling/artwork; native log controls own row clicks.
    self.list.root.clickthrough = true
    self.list.viewport.clickthrough = true
    self.list.content.clickthrough = true
    self.onScrollWheel = ScrollInput.For(self.list)
end

function View:UpdateSearchAutoFocus(listener)
    if not settings.Get("autoFocusFairyRingSearch") then
        cleanup.Release(self, "searchInput")
    elseif self.searchInput == nil and listener ~= nil then
        self.searchInput = TextFieldAutofocus:New(self.search, listener, {
            hookID = "teleportMapsSearchInput",
            font = config.Font.MUSEO_SANS_15PT_REGULAR,
            forwardKey = function(_, character)
                return character ~= nil and character >= 49 and character <= 57
            end,
        })
        self.searchInput:Attach()
    end
end

function View:Layout(x, y, layout, sidebarTop)
    self.root:SetPos(x, y)
    self.root:SetSize(layout.width + layout.sidebarWidth, layout.height)
    self.background:Show(backgrounds.runescapeSurface, layout.width, layout.mapHeight)
    self.background.layer:MoveToBack()
    self.search.root:SetPos(layout.width + 12, sidebarTop)
    self.search.root:SetSize(layout.sidebarWidth - 24, 28)
    self.searchIcon:SetPos(layout.width + 16, sidebarTop + 2)
    self.heading:SetPos(layout.width + 12, sidebarTop + 36)
    self.heading:SetSize(layout.sidebarWidth - 24, 22)
    local listTop = sidebarTop + 62

    for index, line in ipairs(self.separators) do
        line:SetPos(layout.width + 12, listTop - 4 + index)
        line:SetSize(layout.sidebarWidth - 24, 1)
    end

    self.list.root:SetPos(layout.width + 12, listTop)
    self.list:SetSize(layout.sidebarWidth - 24, math.max(1, layout.height - listTop - 8))
    self.layout = layout
end

local function destroyItem(item)
    cleanup.Release(item, "tooltip")
    cleanup.Release(item, "hotkey")
    cleanup.Release(item, "shadow")
    cleanup.Release(item, "icon")
    cleanup.Release(item, "target")
end

function View:TargetPosition(target)
    if target.parent == self.list.content then
        local origin = self.list.viewport.xyGlobal
        return origin.x + self.list.content.x + target.x,
            origin.y + self.list.content.y + target.y - (self.list.scrollY or 0)
    end

    local position = target.xyGlobal
    return position.x, position.y
end

function View:CreateItem(row)
    local parent = row.point and self.root or self.list.content
    local target = ui.Layer.new(parent)
    target.clickthrough = true
    local item = {
        target = target,
        mapped = row.point ~= nil,
    }
    self.items[row.key] = item

    if item.mapped then
        item.shadow = components.ItemSprite(target, id.Obj.INVENT_FAIRY_RING)
        item.shadow.rgb = 0x000000
        item.icon = components.ItemSprite(target, id.Obj.INVENT_FAIRY_RING)
    else
        item.selection = ui.Rectangle.new(target)
        item.selection.fill = true
        item.selection.clickthrough = true
        item.name = components.CenteredLabel(target, id.Font.MUSEO_SANS_13PT_REGULAR)
        item.name:AlignTo(ui.AlignMode.TOPLEFT)
        item.name.rgba = 0xD6CFC5FF
    end

    item.label = components.CenteredLabel(target, id.Font.MUSEO_SANS_13PT_BOLD)

    if not item.mapped then
        item.label:AlignTo(ui.AlignMode.TOPLEFT)
    end

    item.hotkey = HotkeyBadge.New(item.mapped and parent or target, row.shortcut)

    if not self.contexts[parent] then
        prettyui.Tooltip.registerContext(parent, self.tooltipLayer, function(control)
            local x, y = self:TargetPosition(control)
            local origin = self.tooltipLayer.xyGlobal

            return x - origin.x, y - origin.y
        end)
        self.contexts[parent] = true
    end

    item.tooltip = teleportTooltip.Attach(target, parent, row.name,
        row.code ~= "" and ("<sprite=133>  Code: " .. row.code) or nil)
    target.clickthrough = true

    if not item.mapped then
        ScrollInput.Bind(target, self.onScrollWheel)
    end

    return item
end

local function matches(row, query, codeQuery, exactCode)
    if query == "" then
        return true
    end

    for _, code in ipairs(row.codes) do
        if code == codeQuery or not exactCode and code:sub(1, #codeQuery) == codeQuery then
            return true
        end
    end

    return not exactCode and text.FuzzyScore(row.text, query, settings.Get("fuzzyFairyRingSearch")) ~= nil
end

function View:LayoutMarker(item, showCodes)
    local row = item.row
    local x, y = geometry.Project(backgrounds.runescapeSurface, row.point, self.layout.width, self.layout.mapHeight)

    if item.markerX == x and item.markerY == y and item.showCodes == showCodes then
        return
    end

    item.markerX, item.markerY, item.showCodes = x, y, showCodes

    -- Extend the clipping parent upward without moving the artwork or code.
    item.target:SetPos(math.floor(x - markerWidth / 2), math.floor(y - 18 - markerTopPadding))
    item.target:SetSize(markerWidth, markerHeight + markerTopPadding)
    item.label:SetPos(0, 31 + markerTopPadding)
    item.label:SetSize(markerWidth, 17)
    item.label.content = row.code
    item.label.hidden = not showCodes
end

function View:LayoutListRow(item, index, showCodes)
    local target, row = item.target, item.row
    local height = showCodes and listRowHeight or compactListRowHeight
    local width = math.max(1, self.list.viewport.width)
    local showHotkey = row.shortcut ~= nil and row.shortcut ~= "" and settings.Get("showTeleportHotkeys")
    local badgeSpace = showHotkey and HotkeyBadge.Size(row.shortcut, width) + 8 or 0

    if item.listIndex == index and item.listWidth == width and item.showCodes == showCodes
        and item.badgeSpace == badgeSpace and item.listName == row.name and item.listCode == row.code then
        return
    end

    item.listIndex, item.listWidth, item.showCodes = index, width, showCodes
    item.badgeSpace, item.listName, item.listCode = badgeSpace, row.name, row.code

    target:SetPos(0, index * (height + listRowGap))
    target:SetSize(width, height)
    item.label:SetPos(10, 5)
    item.label:SetSize(math.max(1, target.width - 10 - math.max(20, badgeSpace)), 17)
    item.label.content = row.code:gsub("(%a)(%a)(%a)", "%1 %2 %3"):gsub("%-", "      ")
    item.label.hidden = not showCodes
    item.name:SetPos(10, showCodes and 23 or 4)
    item.name:SetSize(math.max(1, target.width - 10 - math.max(10, badgeSpace)), 18)
    item.name.content = row.name
    item.selection:SetSize(target.width, target.height)
    item.stripe = index % 2 == 0 and 0x25211CE6 or 0x302B25E6
end

function View:UpdateItem(item, selectedName)
    local row = item.row
    local shortcut = row.shortcut or ""

    if item.hotkey.label.content ~= shortcut then
        item.hotkey.label.content = shortcut
    end

    local selected = text.Trim(row.location) == selectedName

    -- Changing item-sprite outlineWidth invalidates its rendered icon. Do not
    -- regenerate every fairy-ring sprite on every frame for an unchanged selection.
    if item.icon ~= nil and item.selected ~= selected then
        item.icon.outlineWidth = selected and selectedOutlineWidth or 0
    end
    item.selected = selected

    local alpha = item.matches and 1 or 0.2

    if item.alpha == alpha then
        return
    end

    item.alpha = alpha

    if item.icon ~= nil then
        item.shadow.alpha = alpha
        item.icon.alpha = alpha
    end

    if item.name ~= nil then
        item.name.alpha = alpha
    end

    item.label.alpha = alpha
end

-- Only fully visible list rows receive native hitboxes. Compute clipping in
-- viewport space because native absolute coordinates can omit scroll offsets.
function View:GetHovered(ordered)
    for index = #ordered, 1, -1 do
        local item = ordered[index]
        local target = item.target
        local visible = true

        if not item.mapped then
            local y = target.y - (self.list.scrollY or 0)
            visible = y >= 0 and y + target.height <= self.list.viewport.height
        end

        if visible and target.visibleGlobal and target.isMouseOver then
            return item
        end
    end
end

function View:Update(rows, selectedName)
    local showCodes = settings.Get("showFairyRingMapCodes")
    local query = text.Trim(self.search:GetText()):lower()
    local codeQuery = query:gsub("[%s%-]", "")
    local exactCode = false

    for _, row in ipairs(rows) do
        for _, code in ipairs(row.codes) do
            if code == codeQuery then
                exactCode = true
            end
        end
    end

    local seen, ordered, listIndex = {}, {}, 0

    for _, row in ipairs(rows) do
        local item = self.items[row.key] or self:CreateItem(row)
        seen[row.key] = true
        item.row = row
        item.matches = matches(row, query, codeQuery, exactCode)

        if item.mapped then
            self:LayoutMarker(item, showCodes)
        else
            self:LayoutListRow(item, listIndex, showCodes)
            listIndex = listIndex + 1
        end

        self:UpdateItem(item, selectedName)
        ordered[#ordered + 1] = item
    end

    for key, item in pairs(self.items) do
        if not seen[key] then
            destroyItem(item)
            self.items[key] = nil
        end
    end

    local rowHeight = showCodes and listRowHeight or compactListRowHeight
    self.list:SetContentHeight(listIndex * (rowHeight + listRowGap))

    local hovered = self:GetHovered(ordered)

    for _, item in ipairs(ordered) do
        if item.mapped then
            -- Grow artwork only; native hitboxes and labels stay stationary.
            local size = (item == hovered or item.selected) and hoveredIconSize or iconSize
            local x, y = (markerWidth - size) / 2, markerTopPadding + (iconSize - size) / 2

            if item.iconSize ~= size then
                item.shadow:SetPos(x + 1, y + 1)
                item.shadow:SetSize(size, size)
                item.icon:SetPos(x, y)
                item.icon:SetSize(size, size)
                item.iconSize = size
            end
        else
            item.selection.rgba = item.selected and 0x66512EFF or item == hovered and 0x484036FF or item.stripe
        end

        item.hotkey:Update(item.target, {
            disabled = false,
            inset = not item.mapped and 4 or nil,
            offset = item.mapped and markerHotkeyOffset or nil,
        })
        item.hotkey:SetAlpha(item.matches and 1 or 0.2)

        if item == hovered then
            item.tooltip:Show()
        else
            item.tooltip:Hide()
        end
    end

    return hovered
end

function View:TargetRectangle(item)
    local target = item.target
    local x, y = self:TargetPosition(target)
    return x, y, target.width, target.height
end

function View:Destroy()
    cleanup.Release(self, "searchInput")

    for _, item in pairs(self.items) do
        destroyItem(item)
    end

    for parent in pairs(self.contexts) do
        cleanup.Try("unregister Fairy Ring tooltip context", function()
            prettyui.Tooltip.unregisterContext(parent)
        end)
    end

    cleanup.Release(self, "search")
    cleanup.Release(self, "list")
    cleanup.Release(self, "background")
    cleanup.Release(self, "root")
end

return View
