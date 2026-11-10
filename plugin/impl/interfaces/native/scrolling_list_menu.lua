local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local components = require("impl/ui/components")
local cleanup = require("impl/cleanup")
local NativeLayout = require("impl/interfaces/native/native_layout")

local ScrollingListMenu = ModalChoiceMenu:Extend()

-- Auto-stacking native panels cannot hold arbitrary card/map rectangles. Passive
-- probes select the native row to place under the pointer, preserving its actions.
function ScrollingListMenu:GetRowProbe(entry)
    local session = self.session

    if session.rowProbeLayer == nil then
        session.rowProbeLayer = ui.Layer.new(session.content)
        session.rowProbeLayer:SetSize(0, 0, 1.0, 1.0)
        session.rowProbeLayer.clickthrough = true
        session.rowProbes = {}
        session.rowProbeRects = {}
    end

    if session.rowProbes[entry] == nil then
        local probe = ui.Layer.new(session.rowProbeLayer)
        probe.clickthrough = true
        probe.hidden = true
        session.rowProbes[entry] = probe
    end

    return session.rowProbes[entry]
end

function ScrollingListMenu:GetTooltipTarget(entry)
    return self:GetRowProbe(entry)
end

function ScrollingListMenu:LayoutRowContainers()
    -- LayoutRows owns these containers. Expanding the stacking panel here and
    -- shrinking it again there forces two native reflows on every frame.
end

local function layoutStackedRow(entry, active, width, height)
    NativeLayout.SetPos(entry.row, 0, 0)
    NativeLayout.SetSize(entry.row, width, height)

    local function layoutControl(control)
        NativeLayout.Set(control, "alpha", 0)
        NativeLayout.Set(control, "clickthrough", not active or control ~= entry.click)

        if control ~= entry.row then
            NativeLayout.SetPos(control, 0, 0)
            NativeLayout.SetSize(control, width, height)
        end
    end

    components.Walk(entry.row, layoutControl)
end

function ScrollingListMenu:LayoutRows(rectangles, width, height)
    local session = self.session
    local snapshot = session.menu.snapshot
    local contentWidth = session.content.width
    local origin = session.content.xyGlobal

    if session.rowProbeLayer ~= nil then
        if session.probeWidth ~= width or session.probeHeight ~= height then
            session.rowProbeLayer:SetSize(width, height)
            session.probeWidth, session.probeHeight = width, height
        end
    end

    for _, control in ipairs(snapshot.scrollContainers) do
        if control ~= session.content and control ~= snapshot.scrolling then
            NativeLayout.SetPos(control, 0, 0)
            NativeLayout.SetSize(control, width, height)
            NativeLayout.Set(control, "clickthrough", true)
        end

        if control ~= snapshot.scrolling and control.scrollable then
            NativeLayout.SetScrollSize(control, control == session.content and contentWidth or width, height)
            NativeLayout.SetScrollPos(control, 0, 0)
        end
    end

    if snapshot.scrollbar ~= nil then
        NativeLayout.Set(snapshot.scrollbar, "hidden", true)
    end

    for _, control in ipairs(snapshot.categoryArtwork or {}) do
        NativeLayout.Set(control, "hidden", true)
    end

    local selected

    for _, rectangle in ipairs(rectangles) do
        local entry = rectangle.entry
        local probe = self:GetRowProbe(entry)
        local hidden = entry.destination.hidden or entry.disabled
            or rectangle.width <= 0 or rectangle.height <= 0
        local x, y = math.floor(rectangle.x - origin.x), math.floor(rectangle.y - origin.y)
        local previous = session.rowProbeRects[entry]

        if previous == nil or previous.x ~= x or previous.y ~= y
            or previous.width ~= rectangle.width or previous.height ~= rectangle.height
            or previous.hidden ~= hidden then
            probe.hidden = hidden
            probe:SetPos(x, y)
            probe:SetSize(rectangle.width, rectangle.height)
            session.rowProbeRects[entry] = {
                x = x,
                y = y,
                width = rectangle.width,
                height = rectangle.height,
                hidden = hidden,
            }
        end

        if not hidden and probe.visibleGlobal and probe.isMouseOver then
            selected = rectangle
        end
    end

    if session.rowProbeLayer ~= nil and (session.probeWidth ~= width or session.probeHeight ~= height) then
        session.rowProbeLayer:SetSize(width, height)
        session.probeWidth, session.probeHeight = width, height
    end

    local scrolling = snapshot.scrolling

    if scrolling.type == ui.ComponentType.PANEL then
        NativeLayout.Set(scrolling, "spacing", 0)
    end

    local hitWidth, hitHeight = selected and selected.width or 0, selected and selected.height or 0

    local selectedEntry = selected and selected.entry
    local previous = session.stackedRowLayout

    if previous == nil then
        -- The native roster is fixed for this opening. Collapse it once, then
        -- touch only the previous/new action owner when hover or hitbox size changes.
        for _, entry in ipairs(session.rows) do
            local active = entry == selectedEntry
            layoutStackedRow(entry, active, active and hitWidth or 0, active and hitHeight or 0)
        end

        previous = {}
        session.stackedRowLayout = previous
    elseif previous.entry ~= selectedEntry or previous.width ~= hitWidth or previous.height ~= hitHeight then
        if previous.entry ~= nil and previous.entry ~= selectedEntry then
            layoutStackedRow(previous.entry, false, 0, 0)
        end

        if selectedEntry ~= nil then
            layoutStackedRow(selectedEntry, true, hitWidth, hitHeight)
        end
    end

    previous.entry, previous.width, previous.height = selectedEntry, hitWidth, hitHeight

    NativeLayout.SetPos(
        scrolling,
        selected and math.floor(selected.x - origin.x) or 0,
        selected and math.floor(selected.y - origin.y) or 0
    )
    NativeLayout.SetSize(scrolling, hitWidth, hitHeight)

    if scrolling.scrollable then
        NativeLayout.SetScrollSize(scrolling, hitWidth, hitHeight)
        NativeLayout.SetScrollPos(scrolling, 0, 0)
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
