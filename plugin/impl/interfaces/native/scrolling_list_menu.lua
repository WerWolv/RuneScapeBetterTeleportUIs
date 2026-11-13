local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local components = require("impl/ui/components")
local cleanup = require("impl/cleanup")

local ScrollingListMenu = ModalChoiceMenu:Extend()

-- Auto-stacking native panels cannot hold arbitrary card/map rectangles. Passive
-- probes select the native row to place under the pointer, preserving its actions.
function ScrollingListMenu:GetRowProbe(entry)
    local session = self.session

    if session.rowProbeLayer == nil then
        session.rowProbeLayer = prettyui.NewComponent(ui.Layer, session.content, { categoryID = "auto" })
        session.rowProbeLayer:SetSize(0, 0, 1.0, 1.0)
        session.rowProbeLayer.clickthrough = true
        session.rowProbes = {}
    end

    if session.rowProbes[entry] == nil then
        local probe = prettyui.NewComponent(ui.Layer, session.rowProbeLayer)
        probe.clickthrough = true
        probe.hidden = true
        session.rowProbes[entry] = probe
    end

    return session.rowProbes[entry]
end

function ScrollingListMenu:GetTooltipTarget(entry)
    return self:GetRowProbe(entry)
end

-- The row trees are fixed for this opening. Cache discovery, not their input state.
function ScrollingListMenu:GetRowControls(entry)
    local session = self.session
    session.rowControls = session.rowControls or {}
    local controls = session.rowControls[entry]

    if controls == nil then
        controls = {}

        components.Walk(entry.row, function(control)
            controls[#controls + 1] = control
        end)

        session.rowControls[entry] = controls
    end

    return controls
end

-- Preserve the working per-frame setter sequence, including unchanged geometry.
function ScrollingListMenu:LayoutStackedRow(entry, active, width, height)
    entry.row:SetPos(0, 0)
    entry.row:SetSize(width, height)

    for _, control in ipairs(self:GetRowControls(entry)) do
        control.alpha = 0
        control.clickthrough = not active or control ~= entry.click

        if control ~= entry.row then
            control:SetPos(0, 0)
            control:SetSize(width, height)
        end
    end
end

function ScrollingListMenu:LayoutRows(rectangles, width, height)
    local session = self.session
    local snapshot = session.menu.snapshot
    local contentWidth = session.content.width
    local origin = session.content.xyGlobal

    if session.rowProbeLayer ~= nil then
        session.rowProbeLayer:SetSize(width, height)
    end

    for _, control in ipairs(snapshot.scrollContainers) do
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

    if snapshot.scrollbar ~= nil then
        snapshot.scrollbar.hidden = true
    end

    for _, control in ipairs(snapshot.categoryArtwork or {}) do
        control.hidden = true
    end

    local selected

    for _, rectangle in ipairs(rectangles) do
        local entry = rectangle.entry
        local probe = self:GetRowProbe(entry)
        probe.hidden = entry.destination.hidden or entry.disabled
            or rectangle.width <= 0 or rectangle.height <= 0
        probe.clickthrough = true
        probe:SetPos(math.floor(rectangle.x - origin.x), math.floor(rectangle.y - origin.y))
        probe:SetSize(rectangle.width, rectangle.height)

        if probe.visibleGlobal and probe.isMouseOver then
            selected = rectangle
        end
    end

    if session.rowProbeLayer ~= nil then
        session.rowProbeLayer:SetSize(width, height)
    end

    local scrolling = snapshot.scrolling

    if scrolling.type == ui.ComponentType.PANEL then
        scrolling.spacing = 0
    end

    local hitWidth, hitHeight = selected and selected.width or 0, selected and selected.height or 0

    for _, entry in ipairs(session.rows) do
        local active = selected ~= nil and selected.entry == entry
        self:LayoutStackedRow(entry, active, active and hitWidth or 0, active and hitHeight or 0)
    end

    -- A zero-sized container stops native shortcut processing for every row.
    -- Keep it traversable without giving any unhovered row a mouse hitbox.
    local containerWidth, containerHeight = math.max(1, hitWidth), math.max(1, hitHeight)

    scrolling:SetPos(
        selected and math.floor(selected.x - origin.x) or 0,
        selected and math.floor(selected.y - origin.y) or 0
    )
    scrolling:SetSize(containerWidth, containerHeight)

    if scrolling.scrollable then
        scrolling:SetScrollSize(containerWidth, containerHeight)
        scrolling:SetScrollPos(0, 0)
    end
end

function ScrollingListMenu:ReleaseInterface()
    if self.session == nil then
        return
    end

    self:ReleaseTooltips()
    cleanup.Release(self.session, "rowProbeLayer")
    ModalChoiceMenu.ReleaseInterface(self)
end

return ScrollingListMenu
