local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local components = require("impl/ui/components")
local geometry = require("impl/map_geometry")
local ButtonIcon = require("impl/ui/button_icon")
local utils = require("impl/utils")
local TeleportCategories = require("impl/teleport_categories")
local TitledFrame = require("impl/ui/titled_frame")
local settings = require("impl/settings")
local text = require("impl/text")
local ScrollInput = require("impl/ui/scroll_input")
local cleanup = require("impl/cleanup")

local CategoryMap = {}
local Filters = {}
Filters.__index = Filters

local sidebarWidth = 208
local searchHeight = 28
local searchIconSize, searchIconInset = 24, 4

local function sprite(parent, spriteID)
    local control = ui.Sprite.new(parent)
    control.spriteID = spriteID
    control.clickthrough = true

    return control
end

-- Establish ownership before constructing widgets, so partial failures can be released.
function Filters.New(parent, categories, rows)
    local root = ui.Layer.new(parent)
    root.clickthrough = false
    local destinations = {}
    for _, row in ipairs(rows) do
        if not row.destination.hidden then
            destinations[#destinations + 1] = row.destination
        end
    end

    return setmetatable({
        root = root,
        entries = {},
        definition = categories,
        categories = TeleportCategories.New(categories, destinations),
    }, Filters)
end

function Filters:Build(rows)
    local edge = sprite(self.root, id.Sprite.RS3_MODAL_WINDOW_1_SIDE_TILE)
    edge:SetSize(5, 0, 0, 1.0)
    edge.isTiling = true

    -- Let the native window's texture show through the sidebar.
    self.view = prettyui.SimpleView.new(self.root, {
        width = sidebarWidth,
        height = 240,
        layout = { padding = 12, startY = 12, rowGap = 10 },
    })
    self.onScrollWheel = ScrollInput.For(self.view)

    self.search = self.view:AddTextField({
        placeholder = "Search...",
        maxLength = 80,
        height = searchHeight,
        contentMargin = ui.Margin.new(searchIconInset * 2 + searchIconSize, 3, 8, 0),
    })

    local searchIcon = sprite(self.view.content, id.Sprite.AIF_SEARCH_ICON_0)
    searchIcon:SetSize(searchIconSize, searchIconSize)
    searchIcon:SetPos(
        self.search.root.x + searchIconInset,
        self.search.root.y + (searchHeight - searchIconSize) / 2
    )

    local separatorOptions = {
        x = 12, width = -24, widthAnchor = 1, marginTop = -40, marginBottom = -15,
    }
    self.separator = self.view:AddDivider(separatorOptions)

    self.categories:Update(settings.Get(self.definition.setting))

    self.categoryPanel = TitledFrame.New(self.view.content, "Settings")
    -- This panel sits outside PrettyUI's flow, so apply the divider's bottom margin explicitly.
    self.categoryPanel:SetPos(12,
        self.separator.root.y + self.separator.root.height + separatorOptions.marginBottom + 4)
    self.categoryHeading = prettyui.Text.title(self.categoryPanel, {
        text = "Categories", x = 12, y = 40, width = -24, widthAnchor = 1, height = 10,
    })
    ScrollInput.Bind(self.categoryHeading, self.onScrollWheel)
    self:BuildCategoryButtons()

    for _, row in ipairs(rows) do
        self.entries[#self.entries + 1] = {
            destination = row.destination,
            hidden = row.destination.hidden,
            names = {
                row.name,
                row.destination.nameOverride or row.name,
                text.Clean(row.destination.description),
            },
        }
    end
end

function Filters:BuildCategoryButtons()
    if self.categoryButtons ~= nil then
        self.categoryButtons:Destroy()
    end

    self.categoryButtons = prettyui.RadioButton.new(self.categoryPanel, self.categories.choices, {
        x = 12,
        y = self.categoryHeading.y + self.categoryHeading.height + 8,
        width = -24,
        widthAnchor = 1,
        selectedValue = self.categories.selected,
        onChange = function(_, key)
            self.categories:Select(key)
        end,
    })
    ScrollInput.Bind(self.categoryButtons.root, self.onScrollWheel)

    for _, item in ipairs(self.categoryButtons.items) do
        item.label.font = id.Font.MUSEO_SANS_13PT_REGULAR
    end

    self:LayoutCategories()
end

function Filters:LayoutCategories()
    local panelHeight = math.max(self.categoryButtons.root.y + self.categoryButtons.root.height + 12,
        self.view.root.height - self.categoryPanel.y - 12)
    self.categoryPanel:SetSize(-24, panelHeight, 1.0, 0)
    self.view:SetContentHeight(self.categoryPanel.y + panelHeight + 12)
end

-- Filtering changes presentation only; native rows and their shortcut bindings stay intact.
function Filters:Update()
    local query = text.Trim(self.search:GetText()):lower()
    local categoriesChanged, choicesChanged = self.categories:Update(settings.Get(self.definition.setting))
    local selected = self.categories.selected
    local changed = categoriesChanged or query ~= self.query or selected ~= self.selected

    if choicesChanged then
        self:BuildCategoryButtons()
    end

    if not changed then
        return
    end

    self.categoryButtons:SetSelectedValue(selected, false)

    for _, entry in ipairs(self.entries) do
        local destination = entry.destination
        destination.hidden = entry.hidden or not self.categories:Includes(destination)
        destination.searchMatch = text.FuzzyScore(entry.names, query, false) ~= nil
    end

    self.query = query
    self.selected = selected
end

function Filters:Layout(x, width, height)
    self.root:SetPos(x, 0)
    self.root:SetSize(width, height)

    if self.width ~= width or self.height ~= height then
        self.view:SetSize(width, height)
        self:LayoutCategories()
        self.width, self.height = width, height
    end

    self.root:MoveToFront()
end

function Filters:Destroy()
    cleanup.Release(self, "categoryButtons")
    cleanup.Release(self, "view")
    cleanup.Release(self, "root")
end

-- Native rows collapse and move on every selection; attach after stable probes exist.
function CategoryMap:GetTooltipTarget()
    return nil
end

-- Reserve sidebar space in the movable host, bounded by the viewport on small screens.
function CategoryMap:UpdateLayoutHost(session, sizeMultiplier)
    ModalChoiceMenu.UpdateLayoutHost(self, session, sizeMultiplier)

    local frame = session.hostContainers[1]
    local viewport = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__VIEWPORT)
    local width = math.min(frame.width + sidebarWidth, viewport.width)

    frame:SetSize(width, frame.height)
    session.hostResized = true
end

function CategoryMap:CalculateLayout()
    local layout = ModalChoiceMenu.CalculateLayout(self)
    local session = self.session
    local availableWidth = session.layoutParent.width - session.left - session.right - 16
    local panelWidth = math.min(sidebarWidth, math.floor(availableWidth * 0.4))
    local width = math.max(1, math.min(layout.width, availableWidth - panelWidth))

    layout.height = math.max(1, math.floor(layout.height * width / layout.width))
    layout.width = width
    layout.panelWidth = panelWidth

    return layout
end

function CategoryMap:BeginVisuals()
    for _, entry in ipairs(self.session.rows) do
        local destination = entry.destination

        destination.icons = utils.deepcopy(destination.icons)
        if entry.native.spriteID ~= nil then
            destination.icons.sprite = entry.native.spriteID
        end
        destination.hotkey = entry.native.shortcut
        destination.hotkeyOffset = { x = 10, y = -10 }
    end

    ModalChoiceMenu.BeginVisuals(self)
    self.session.pointerTargets = {}

    for index, entry in ipairs(self.session.rows) do
        local target = ui.Layer.new(self.backgroundView.layer)

        target.clickthrough = true
        target.hidden = true
        self.session.pointerTargets[index] = target

        if not entry.destination.hidden then
            self:AttachTooltip(entry, target)
        end

        -- PrettyUI enables input on attachment; the native row must keep the action.
        target.clickthrough = true
    end

    self.filters = Filters.New(self.session.content, self.categoryDefinition, self.session.rows)
    self.filters:Build(self.session.rows)
end

-- Native hit testing handles the client's mouse/UI coordinate conversion.
-- Passive probes keep the unhovered icon bounds as the artwork grows around them.
function CategoryMap:FindPointerRow(width, height)
    for index, entry in ipairs(self.session.rows) do
        local target = self.session.pointerTargets[index]
        local x, y = geometry.Project(self.session.menu.background, entry.destination.point, width, height)

        target.hidden = entry.destination.hidden or entry.disabled or x == nil

        if not target.hidden then
            local w, h = ButtonIcon.Dimensions(entry.destination.icons)

            target:SetPos(math.floor(x - w / 2), math.floor(y - h / 2))
            target:SetSize(w, h)
        end
    end

    -- Match marker draw order if icon bounds overlap.
    for index = #self.session.rows, 1, -1 do
        local target = self.session.pointerTargets[index]

        if target.visibleGlobal and target.isMouseOver then
            return self.session.rows[index], target
        end
    end
end

function CategoryMap:GetHovered()
    local row = self.session.pointerRow

    return row ~= nil and row.click.visibleGlobal and row.name or nil
end

function CategoryMap:ApplyLayout(layout)
    local session = self.session
    local width, height = layout.width, layout.height
    local contentWidth = width + layout.panelWidth

    self.filters:Update()
    self:LayoutWindow(contentWidth, height)

    -- Every list wrapper shares the map's local origin. Avoid converting native
    -- dynamic rows through xyGlobal while their ancestors are being relaid out.
    for _, control in ipairs(session.menu.snapshot.scrollContainers) do
        if control ~= session.content then
            control:SetPos(0, 0)
            control:SetSize(width, height)
            control.clickthrough = true
        end

        if control.scrollable then
            control:SetScrollSize(control == session.content and contentWidth or width, height)
            control:SetScrollPos(0, 0)
        end
    end

    local scrollbar = session.menu.snapshot.scrollbar

    if scrollbar ~= nil then
        scrollbar.hidden = true
    end

    for _, control in ipairs(session.menu.snapshot.categoryArtwork or {}) do
        control.hidden = true
    end

    self.backgroundView:Show(session.menu.background, width, height, self.definition.vignette)

    local selected, target = self:FindPointerRow(width, height)
    local hitWidth, hitHeight = target and target.width or 0, target and target.height or 0
    local scrolling = session.menu.snapshot.scrolling

    -- A panel always stacks its children. Zero-sized rows and zero spacing put
    -- the sole active row at its origin, regardless of destination/list order.
    -- Keep rows present for discovery and native keyboard shortcut handlers.
    if scrolling.type == ui.ComponentType.PANEL then
        scrolling.spacing = 0
    end

    for _, entry in ipairs(session.rows) do
        self:LayoutRow(
            entry, 0, 0,
            entry == selected and hitWidth or 0,
            entry == selected and hitHeight or 0
        )
    end

    -- Move the wrapper (whose parent is a free-positioned Layer), not its rows.
    scrolling:SetPos(target and target.position.x or 0, target and target.position.y or 0)
    scrolling:SetSize(hitWidth, hitHeight)

    if scrolling.scrollable then
        scrolling:SetScrollSize(hitWidth, hitHeight)
        scrolling:SetScrollPos(0, 0)
    end

    session.pointerRow = selected
    self.filters:Layout(width, layout.panelWidth, height)
end

-- Keep the native action owner, but remove the old full-width row's input footprint.
function CategoryMap:LayoutRow(entry, x, y, width, height)
    entry.row:SetPos(math.floor(x), math.floor(y))
    entry.row:SetSize(width, height)

    components.Walk(entry.row, function(control)
        control.alpha = 0
        control.clickthrough = width == 0 or height == 0 or control ~= entry.click

        if control ~= entry.row then
            control:SetPos(0, 0)
            control:SetSize(width, height)
        end
    end)
end

-- Search emphasizes matches without removing destinations or changing native input.
function CategoryMap:UpdateVisuals(layout, hovered)
    ModalChoiceMenu.UpdateVisuals(self, layout, hovered)

    for _, entry in ipairs(self.session.rows) do
        local marker = self.iconView.markers[entry.name]

        if marker ~= nil then
            local alpha = entry.destination.searchMatch == false and 0.2 or 1.0

            -- Set opacity on drawable controls; native layers do not fade their children.
            local drawable = marker.itemSprite or marker.sprite.root
            drawable.alpha = (entry.disabled and 0.4 or 1.0) * alpha

            if marker.shadow ~= nil then
                marker.shadow.root.alpha = (marker.shadowTint & 0xFF) / 255 * alpha
            end

            if marker.hotkey ~= nil then
                marker.hotkey:SetAlpha((entry.disabled and 0.6 or 1.0) * alpha)
            end
        end
    end
end

function CategoryMap:ReleaseVisuals()
    cleanup.Release(self, "filters")

    ModalChoiceMenu.ReleaseVisuals(self)
end

-- Compose presentation onto a native interface without changing its discovery/matching.
return {
    Create = function(interface, key, categories)
        local class = interface:Extend(key)
        for name, method in pairs(CategoryMap) do
            class[name] = method
        end
        class.categoryDefinition = categories
        return class
    end,
}
