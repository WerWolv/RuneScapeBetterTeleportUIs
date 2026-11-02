local PortalNexusMenu = require("impl/interfaces/portal_nexus_menu")
local backgrounds = require("definitions/backgrounds")
local descriptions = require("definitions/descriptions")
local components = require("impl/components")
local geometry = require("impl/map_geometry")
local ButtonIcon = require("impl/button_icon")
local utils = require("impl/utils")
local categories = require("definitions/nexus_categories")
local TeleportCategories = require("impl/teleport_categories")
local TitledFrame = require("impl/titled_frame")
local settings = require("impl/settings")
local text = require("impl/text")

local TeleportNexus = PortalNexusMenu:Extend("teleportNexus")

-- Destinations can belong to several category filters.
local function destination(x, y, ...)
    local memberships = { ... }

    if #memberships == 0 then
        memberships = { "standard" }
    end

    return {
        point = { x = x, y = y },
        categories = memberships,
    }
end

function TeleportNexus:Define()
    local entries = {
        ["South Feldip Hills"]          = destination(115, 275),
        ["Varrock"]                     = destination(351, 105),
        ["Grand Exchange"]              = destination(333, 92),
        ["North-East Varrock"]          = destination(362, 80),
        ["Lumbridge"]                   = destination(340, 170),
        ["Falador"]                     = destination(272, 117),
        ["Camelot"]                     = destination(211, 82),
        ["Seers' Village"]              = destination(185, 81),
        ["Ardougne"]                    = destination(167, 139),
        ["Watchtower"]                  = destination(158, 177),
        ["Yanille"]                     = destination(180, 181),
        ["Trollheim"]                   = destination(265, 33),
        ["God Wars Dungeon"]            = destination(270, 12),
        ["The Heart of Gielinor"]       = destination(380, 272),
        ["Ape Atoll"]                   = destination(207, 295),
        ["Paddewwa"]                    = destination(310, 80, "ancient"),
        ["Senntisten"]                  = destination(379, 110, "ancient"),
        ["Kharyrll"]                    = destination(423, 87, "ancient"),
        ["Lassar"]                      = destination(282, 91, "ancient"),
        ["Dareeyak"]                    = destination(296, 47, "ancient"),
        ["Carrallangar"]                = destination(348, 44, "ancient"),
        ["Annakarl"]                    = destination(386, 16, "ancient"),
        ["Ghorrock"]                    = destination(294, 16, "ancient"),
        ["Moonclan"]                    = destination(20, 18, "lunar"),
        ["Ourania"]                     = destination(128, 157, "lunar"),
        ["South Falador"]               = destination(285, 148, "lunar"),
        ["Waterbirth"]                  = destination(155, 15, "lunar"),
        ["Barbarian"]                   = destination(147, 69, "lunar"),
        ["North Ardougne"]              = destination(164, 118, "lunar"),
        ["Khazard"]                     = destination(185, 158, "lunar"),
        ["Fishing Guild"]               = destination(170, 95, "lunar"),
        ["Catherby"]                    = destination(229, 104, "lunar"),
        ["Ice Plateau"]                 = destination(316, 16, "lunar"),
        ["Trollheim Farm"]              = destination(250, 49, "lunar"),
        ["Taverley"]                    = destination(257, 97),
        ["Western Kharazi Jungle"]      = destination(234, 248, "lunar"),
        ["Mountain Camp"]               = destination(229, 29, "lunar"),
        ["North-western Anachronia"]    = destination(482, 32),
        ["Eastern Anachronia"]          = destination(519, 50),
        ["Northern Lost Grove"]         = destination(15, 180),
        ["Wendlewick"]                  = destination(533, 133),
        ["Marigold Farm"]               = destination(545, 165),
        ["Mazcab"]                      = destination(310, 265),
    }

    -- Use canonical names for saved assignments, independently of native aliases.
    for name, entry in pairs(entries) do
        entry.categoryKey = name
    end

    local aliases = {
        ["The Heart"]                           = "The Heart of Gielinor",
        ["North-east Varrock"]                  = "North-East Varrock",
        ["North-Western Anachronia"]            = "North-western Anachronia",
        ["Wendlewick Farm"]                     = "Marigold Farm",
        ["Paddewwa (Edgeville)"]                = "Paddewwa",
        ["Senntisten (Varrock Dig Site)"]       = "Senntisten",
        ["Kharyrll (Canifis)"]                  = "Kharyrll",
        ["Lassar (Ice Mountain)"]               = "Lassar",
        ["Dareeyak (Western Wilderness)"]       = "Dareeyak",
        ["Carrallangar (Graveyard of Shadows)"] = "Carrallangar",
        ["Annakarl (Demonic Ruins)"]            = "Annakarl",
        ["Ghorrock (Ice Plateau)"]              = "Ghorrock",
        ["Moonclan (Lunar Isle)"]               = "Moonclan",
        ["Ourania (ZMI Altar)"]                 = "Ourania",
    }

    for alias, name in pairs(aliases) do
        local entry = entries[name]
        local location = alias:match("%((.-)%)$")

        if location ~= nil then
            entry.nameOverride = name
            entry.description = descriptions.Location(location)
        end

        entries[alias] = entry
    end

    return {
        title = "Portal Nexus",
        background = backgrounds.runescapeSurface,
        noBackgroundCrop = true,
        sizeMultiplier = 1.75,

        icons = {
            size = 32,
            hoveredSize = 36,
            shadowColor = 0x00000099,
            shadowColorHovered = 0x000000CC,
        },

        entries = entries,
    }
end

local spells = {
    ["South Feldip Hills"]       = "MAGIC_TELEPORT_MOBILISING_ARMIES",
    ["Varrock"]                  = "MAGIC_TELEPORT_VARROCK",
    ["Grand Exchange"]           = "MAGIC_TELEPORT_VARROCK",
    ["North-East Varrock"]       = "MAGIC_TELEPORT_VARROCK",
    ["Lumbridge"]                = "MAGIC_TELEPORT_LUMBRIDGE",
    ["Falador"]                  = "MAGIC_TELEPORT_FALADOR",
    ["Camelot"]                  = "MAGIC_TELEPORT_CAMELOT",
    ["Seers' Village"]           = "MAGIC_TELEPORT_CAMELOT",
    ["Ardougne"]                 = "MAGIC_TELEPORT_ARDOUGNE",
    ["Watchtower"]               = "MAGIC_TELEPORT_WATCHTOWER",
    ["Yanille"]                  = "MAGIC_TELEPORT_WATCHTOWER",
    ["Trollheim"]                = "MAGIC_TELEPORT_TROLLHEIM",
    ["God Wars Dungeon"]         = "MAGIC_TELEPORT_GODWARS",
    ["The Heart of Gielinor"]    = "MAGIC_TELEPORT_GODWARS2",
    ["Ape Atoll"]                = "MAGIC_TELEPORT_APE_ATOLL",
    ["Paddewwa"]                 = "MAGIC_TELEPORT_EDGEVILLE",
    ["Senntisten"]               = "MAGIC_TELEPORT_DIGSITE",
    ["Kharyrll"]                 = "MAGIC_TELEPORT_CANFIS",
    ["Lassar"]                   = "MAGIC_TELEPORT_ICE_MOUNTAIN",
    ["Dareeyak"]                 = "MAGIC_TELEPORT_WESTERN_RUINS",
    ["Carrallangar"]             = "MAGIC_TELEPORT_WILDY_GRAVEYARD",
    ["Annakarl"]                 = "MAGIC_TELEPORT_DEMONIC_RUINS",
    ["Ghorrock"]                 = "MAGIC_TELEPORT_ICE_PLATEAU_ANCIENT",
    ["Moonclan"]                 = "MAGIC_TELEPORT_MOONCLAN",
    ["Ourania"]                  = "MAGIC_TELEPORT_ZMI",
    ["South Falador"]            = "MAGIC_TELEPORT_SOUTH_FALADOR",
    ["Waterbirth"]               = "MAGIC_TELEPORT_WATERBIRTH",
    ["Barbarian"]                = "MAGIC_TELEPORT_BARBARIAN",
    ["North Ardougne"]           = "MAGIC_NORTH_ARDOUGNE",
    ["Khazard"]                  = "MAGIC_TELEPORT_KHAZARD",
    ["Fishing Guild"]            = "MAGIC_TELEPORT_FISHING_GUILD",
    ["Catherby"]                 = "MAGIC_TELEPORT_CATHERBY",
    ["Ice Plateau"]              = "MAGIC_TELEPORT_ICE_PLATEAU_LUNAR",
    ["Trollheim Farm"]           = "MAGIC_TELEPORT_TROLLHEIM_FARM",
    ["Taverley"]                 = "MAGIC_TELEPORT_TAVERLEY",
    ["Western Kharazi Jungle"]   = "MAGIC_TELEPORT_KHARAZI_JUNGLE_WEST",
    ["Mountain Camp"]            = "MAGIC_TELEPORT_MOUNTAIN_CAMP",
    ["North-western Anachronia"] = "MAGIC_TELEPORT_ANACHRONIA_NORTH_WEST",
    ["Eastern Anachronia"]       = "MAGIC_TELEPORT_ANACHRONIA_EAST",
    ["Northern Lost Grove"]      = "MAGIC_TELEPORT_LOST_GROVE_NORTH",
    ["Wendlewick"]               = "MAGIC_TELEPORT_WENDLEWICK",
    ["Marigold Farm"]            = "MAGIC_TELEPORT_WENDLEWICK",
    ["Mazcab"]                   = "MAGIC_TELEPORT_MAZCAB",
}

-- Spell configs provide artwork even when the native Nexus is closed or lacks a destination.
function TeleportNexus:GetCategoryIcon(destination)
    local spell = config.Struct[assert(spells[destination.categoryKey])]
    local sprite = spell:GetParamValue(config.Param.COMBATV2_ABILITY_ICON)

    return { sprite = type(sprite) == "number" and sprite or sprite.id }
end

local NexusFilters = {}
NexusFilters.__index = NexusFilters

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
function NexusFilters.New(parent)
    local root = ui.Layer.new(parent)
    root.clickthrough = false

    return setmetatable({
        root = root,
        entries = {},
        categories = TeleportCategories.New(categories),
    }, NexusFilters)
end

function NexusFilters:Build(rows)
    local edge = sprite(self.root, id.Sprite.RS3_MODAL_WINDOW_1_SIDE_TILE)
    edge:SetSize(5, 0, 0, 1.0)
    edge.isTiling = true

    -- Let the native window's texture show through the sidebar.
    self.view = prettyui.SimpleView.new(self.root, {
        width = sidebarWidth,
        height = 240,
        layout = { padding = 12, startY = 12, rowGap = 10 },
    })

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

    self.categories:Update(settings.Get(categories.setting))

    self.categoryPanel = TitledFrame.New(self.view.content, "Settings")
    -- This panel sits outside PrettyUI's flow, so apply the divider's bottom margin explicitly.
    self.categoryPanel:SetPos(12,
        self.separator.root.y + self.separator.root.height + separatorOptions.marginBottom + 4)
    self.categoryHeading = prettyui.Text.title(self.categoryPanel, {
        text = "Categories", x = 12, y = 40, width = -24, widthAnchor = 1, height = 10,
        _onScrollWheel = self.view._onScrollWheel,
    })
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

function NexusFilters:BuildCategoryButtons()
    if self.categoryButtons ~= nil then
        self.categoryButtons:Destroy()
    end

    self.categoryButtons = prettyui.RadioButton.new(self.categoryPanel, self.categories.choices, {
        x = 12,
        y = self.categoryHeading.y + self.categoryHeading.height + 8,
        width = -24,
        widthAnchor = 1,
        selectedValue = self.categories.selected,
        _onScrollWheel = self.view._onScrollWheel,
        onChange = function(_, key)
            self.categories:Select(key)
        end,
    })

    self:LayoutCategories()
end

function NexusFilters:LayoutCategories()
    local panelHeight = math.max(self.categoryButtons.root.y + self.categoryButtons.root.height + 12,
        self.view.root.height - self.categoryPanel.y - 12)
    self.categoryPanel:SetSize(-24, panelHeight, 1.0, 0)
    self.view:SetContentHeight(self.categoryPanel.y + panelHeight + 12)
end

-- Filtering changes presentation only; native rows and their shortcut bindings stay intact.
function NexusFilters:Update()
    local query = text.Trim(self.search:GetText()):lower()
    local categoriesChanged, choicesChanged = self.categories:Update(settings.Get(categories.setting))
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

function NexusFilters:Layout(x, width, height)
    self.root:SetPos(x, 0)
    self.root:SetSize(width, height)

    if self.width ~= width or self.height ~= height then
        self.view:SetSize(width, height)
        self:LayoutCategories()
        self.width, self.height = width, height
    end

    self.root:MoveToFront()
end

function NexusFilters:Destroy()
    if self.categoryButtons ~= nil then
        pcall(function() self.categoryButtons:Destroy() end)
    end

    if self.view ~= nil then
        pcall(function() self.view:Destroy() end)
    end

    pcall(function() self.root:Destroy() end)
end

-- Native rows collapse and move on every selection; attach after stable probes exist.
function TeleportNexus:GetTooltipTarget()
    return nil
end

-- Reserve sidebar space in the movable host, bounded by the viewport on small screens.
function TeleportNexus:UpdateLayoutHost(session, sizeMultiplier)
    PortalNexusMenu.UpdateLayoutHost(self, session, sizeMultiplier)

    local frame = session.hostContainers[1]
    local viewport = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__VIEWPORT)
    local width = math.min(frame.width + sidebarWidth, viewport.width)

    frame:SetSize(width, frame.height)
    session.hostResized = true
end

function TeleportNexus:CalculateLayout()
    local layout = PortalNexusMenu.CalculateLayout(self)
    local session = self.session
    local availableWidth = session.layoutParent.width - session.left - session.right - 16
    local panelWidth = math.min(sidebarWidth, math.floor(availableWidth * 0.4))
    local width = math.max(1, math.min(layout.width, availableWidth - panelWidth))

    layout.height = math.max(1, math.floor(layout.height * width / layout.width))
    layout.width = width
    layout.panelWidth = panelWidth

    return layout
end

function TeleportNexus:BeginVisuals()
    for _, entry in ipairs(self.session.rows) do
        local destination = entry.destination

        destination.icons = utils.deepcopy(destination.icons)
        destination.icons.sprite = entry.native.spriteID
        destination.hotkey = entry.native.shortcut
        destination.hotkeyOffset = { x = 10, y = -10 }
    end

    PortalNexusMenu.BeginVisuals(self)
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

    self.filters = NexusFilters.New(self.session.content)
    self.filters:Build(self.session.rows)
end

-- Native hit testing handles the client's mouse/UI coordinate conversion.
-- Passive probes keep the unhovered icon bounds as the artwork grows around them.
function TeleportNexus:FindPointerRow(width, height)
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

function TeleportNexus:GetHovered()
    local row = self.session.pointerRow

    return row ~= nil and row.click.visibleGlobal and row.name or nil
end

function TeleportNexus:ApplyLayout(layout)
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

    -- Move the panel (whose parent is a free-positioned Layer), not its rows.
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
function TeleportNexus:LayoutRow(entry, x, y, width, height)
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
function TeleportNexus:UpdateVisuals(layout, hovered)
    PortalNexusMenu.UpdateVisuals(self, layout, hovered)

    for _, entry in ipairs(self.session.rows) do
        local marker = self.iconView.markers[entry.name]

        if marker ~= nil then
            local alpha = entry.destination.searchMatch == false and 0.2 or 1.0

            -- Set opacity on drawable controls; native layers do not fade their children.
            marker.sprite.root.alpha = (entry.disabled and 0.4 or 1.0) * alpha

            if marker.shadow ~= nil then
                marker.shadow.root.alpha = (marker.shadowTint & 0xFF) / 255 * alpha
            end

            if marker.hotkey ~= nil then
                marker.hotkey:SetAlpha((entry.disabled and 0.6 or 1.0) * alpha)
            end
        end
    end
end

function TeleportNexus:ReleaseVisuals()
    if self.filters ~= nil then
        self.filters:Destroy()
        self.filters = nil
    end

    PortalNexusMenu.ReleaseVisuals(self)
end

return TeleportNexus
