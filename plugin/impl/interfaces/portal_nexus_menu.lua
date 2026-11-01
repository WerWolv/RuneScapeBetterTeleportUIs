local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local components = require("impl/components")
local text = require("impl/text")
local geometry = require("impl/map_geometry")
local ButtonIcon = require("impl/button_icon")
local utils = require("impl/utils")

local PortalNexusMenu = ModalChoiceMenu:Extend()
PortalNexusMenu.interface = PortalNexusMenu
PortalNexusMenu.interfaceName = "PORTAL_NEXUS (" .. id.Interface.CONSTRUCTION_HOUSE_FURNITURE_PORTAL_NEXUS .. ")"
PortalNexusMenu.nativeInterface = {
    id = id.Interface.CONSTRUCTION_HOUSE_FURNITURE_PORTAL_NEXUS,
    prefix = "CONSTRUCTION_HOUSE_FURNITURE_PORTAL_NEXUS__",
    window = "MAINMODAL_WINDOW",
    content = "MAINMODAL_WINDOW_CONTENT",
    titleParent = "MAINMODAL_WINDOW_BORDER",
    close = "MAINMODAL_WINDOW_CLOSE_BUTTON",
    frame = {
        "MAINMODAL_WINDOW_BACKGROUND",
        "MAINMODAL_WINDOW_BORDER",
    },
    lastStaticID = 8,
}

local function component(name)
    return ui.Interfaces:GetComponent(id.Component["CONSTRUCTION_HOUSE_FURNITURE_PORTAL_NEXUS__" .. name])
end

local function hasTeleportAction(control)
    local ops = control.opConfig

    if ops ~= nil then
        for index = 1, ops.numOpNames do
            if text.Clean(ops:GetOpName(index)):lower():find("teleport", 1, true) then
                return true
            end
        end
    end

    return false
end

-- Rows have a background, shortcut label, spell sprite and destination label.
-- Inspect their roles rather than assuming that dynamic IDs encode a destination.
local function readRow(row)
    local labels, sprites = {}, {}
    local click = hasTeleportAction(row) and row or nil

    components.Walk(row, function(control)
        if control == row then
            return
        end

        if control.parent ~= row then
            return false
        end

        if click == nil and hasTeleportAction(control) then
            click = control
        end

        if control.type == ui.ComponentType.LABEL then
            labels[#labels + 1] = control
        elseif control.type == ui.ComponentType.SPRITE then
            sprites[#sprites + 1] = control
        end

        return false
    end)

    if #labels ~= 2 or #sprites ~= 1 then
        return nil
    end

    table.sort(labels, function(a, b)
        return a.dynamicID < b.dynamicID
    end)

    local shortcut = text.Clean(labels[1].content):gsub("%.$", "")
    local name = text.Clean(labels[2].content)

    if name == "" or sprites[1].spriteID < 0 then
        return nil
    end

    return {
        row = row,
        click = click or row,
        labels = { [name] = true },
        shortcut = shortcut,
        spriteID = sprites[1].spriteID,
    }
end

function PortalNexusMenu:ReadInterface()
    local window = component("MAINMODAL_WINDOW")

    if window == nil or not window.visibleGlobal then
        return nil
    end

    local content = component("MAINMODAL_WINDOW_CONTENT")
    local active = component("ACTIVE_LAYER")
    local contents = component("ACTIVE_CONTENTS")
    local scrolling = component("ACTIVE_SCROLLING")

    if content == nil or content.parent ~= window
        or active == nil or active.parent ~= content
        or contents == nil or contents.parent ~= active
        or scrolling == nil or scrolling.parent ~= contents then
        return nil
    end

    local rows, seen, malformed = {}, {}, false

    scrolling:IterateDynamicComponents(function(row)
        local key = components.Key(row)

        if row.parent == scrolling and not row.hidden and not seen[key] then
            seen[key] = true

            local entry = readRow(row)

            if entry == nil then
                malformed = true
            else
                rows[#rows + 1] = entry
            end
        end

        return false
    end)

    if malformed or #rows == 0 then
        return nil
    end

    -- Each native row has its own category; their root dynamic IDs are all zero.
    table.sort(rows, function(a, b)
        if a.row.categoryID ~= b.row.categoryID then
            return a.row.categoryID < b.row.categoryID
        end

        return a.row.dynamicID < b.row.dynamicID
    end)

    for index, row in ipairs(rows) do
        row.index = index
    end

    return {
        window = window,
        content = content,
        nativeRows = rows,
        closeButton = component("MAINMODAL_WINDOW_CLOSE_BUTTON"),
        scrolling = scrolling,
        scrollContainers = { content, active, contents, scrolling },
    }
end

-- A recycled row can keep its name while its native shortcut or artwork changes.
function PortalNexusMenu:Matches(snapshot)
    if not ModalChoiceMenu.Matches(self, snapshot) then
        return false
    end

    for index, row in ipairs(snapshot.nativeRows) do
        local previous = self.session.menu.snapshot.nativeRows[index]

        if row.shortcut ~= previous.shortcut or row.spriteID ~= previous.spriteID then
            return false
        end
    end

    return true
end

-- Native rows collapse and move on every selection; attach after stable probes exist.
function PortalNexusMenu:GetTooltipTarget()
    return nil
end

function PortalNexusMenu:BeginVisuals()
    for _, entry in ipairs(self.session.rows) do
        local destination = entry.destination

        destination.icons = utils.deepcopy(destination.icons)
        destination.icons.sprite = entry.native.spriteID
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
end

-- Native hit testing handles the client's mouse/UI coordinate conversion.
-- Passive probes keep the unhovered icon bounds as the artwork grows around them.
function PortalNexusMenu:FindPointerRow(width, height)
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

function PortalNexusMenu:GetHovered()
    local row = self.session.pointerRow

    return row ~= nil and row.click.visibleGlobal and row.name or nil
end

function PortalNexusMenu:ApplyLayout(layout)
    local session = self.session
    local width, height = layout.width, layout.height

    self:LayoutWindow(width, height)

    -- Every list wrapper shares the map's local origin. Avoid converting native
    -- dynamic rows through xyGlobal while their ancestors are being relaid out.
    for _, control in ipairs(session.menu.snapshot.scrollContainers) do
        if control ~= session.content then
            control:SetPos(0, 0)
            control:SetSize(width, height)
            control.clickthrough = true
        end

        if control.scrollable then
            control:SetScrollSize(width, height)
            control:SetScrollPos(0, 0)
        end
    end

    local scrollbar = component("ACTIVE_SCROLLBAR")

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
end

-- Keep the native action owner, but remove the old full-width row's input footprint.
function PortalNexusMenu:LayoutRow(entry, x, y, width, height)
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

return PortalNexusMenu
