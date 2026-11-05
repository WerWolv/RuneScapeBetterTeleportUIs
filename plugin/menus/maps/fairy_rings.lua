local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local FairyRingMenu = require("impl/interfaces/fairy_ring_menu")
local FairyRingWheels = require("menus/enhancements/fairy_rings/fairy_ring_wheels")
local FairyRingMapLayout = require("menus/enhancements/fairy_rings/fairy_ring_map_layout")
local native = require("impl/interfaces/native_helpers")
local FairyRingMapView = require("menus/enhancements/fairy_rings/fairy_ring_map")
local backgrounds = require("definitions/backgrounds")
local destinations = require("menus/enhancements/fairy_rings/fairy_ring_destinations")
local cleanup = require("impl/cleanup")
local text = require("impl/text")

local FairyRings = ModalChoiceMenu:Extend("fairyRings")
FairyRings.interface = FairyRings
FairyRings.interfaceName = FairyRingMenu.interfaceName
FairyRings.nativeInterface = {
    id = id.Interface.FAIRYRINGS,
    prefix = "FAIRYRINGS__",
    window = "MAINMODAL_WINDOW",
    content = "MAINMODAL_WINDOW_CONTENT",
    titleParent = "MAINMODAL_WINDOW_BORDER",
    close = "MAINMODAL_WINDOW_CLOSE_BUTTON",
    frame = { "MAINMODAL_WINDOW_BACKGROUND", "MAINMODAL_WINDOW_BORDER" },
    lastStaticID = 72,
}

local component = FairyRingMenu.Component

function FairyRings:Define()
    local definition = FairyRingMenu.Define(self)
    definition.background = backgrounds.runescapeSurface
    definition.noBackgroundCrop = true
    definition.sizeMultiplier = 1.75

    return definition
end

-- Wheel identities remain the stable interface match while the client rebuilds
-- or sorts the log. Destination rows are restored and rediscovered each pass.
FairyRings.ValidateDestination = FairyRingMenu.ValidateDestination

function FairyRings:ReadInterface()
    local snapshot = FairyRingMenu.ReadInterface(self)

    if snapshot == nil or component("COMBINATIONS") == nil or snapshot.logContent == nil then
        return nil
    end

    local host = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__FULLMODAL_WINDOW)
    local hostContent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__FULLMODAL_WINDOW_CONTENT)

    -- Direct/favourite teleports can leave visible native children for a frame
    -- after detaching the full-modal. That is a closing interface, not a new map.
    if host == nil or hostContent == nil or snapshot.window.parent ~= hostContent
        or hostContent.parent ~= host or not host.visibleGlobal then
        return nil
    end

    snapshot.layoutHost, snapshot.layoutContent = host, hostContent
    snapshot.closeButton = component("MAINMODAL_WINDOW_CLOSE_BUTTON")

    return snapshot
end

function FairyRings:Matches(snapshot)
    local previous = self.session and self.session.menu.snapshot

    return FairyRingMenu.Matches(self, snapshot)
        and previous.layoutHost == snapshot.layoutHost
        and previous.layoutContent == snapshot.layoutContent
end

function FairyRings:GetLayoutHost(window)
    return native.ReadLayoutHost(
        window,
        id.Component.TOPLEVEL_V2__FULLMODAL_WINDOW,
        id.Component.TOPLEVEL_V2__FULLMODAL_WINDOW_CONTENT,
        "Fairy Rings full-modal", true
    )
end

function FairyRings:GetTooltipTarget()
    -- Destination tooltips belong to the passive map probes, not the wheels.
    return nil
end

function FairyRings:BeginInterface(placement)
    if ModalChoiceMenu.BeginInterface(self, placement) == false then
        return false
    end

    local session = self.session
    session.rows = {}
    session.cursorOverrides = {}
    self.mapLayout = FairyRingMapLayout.New(session)
end

function FairyRings:GetTransitionState()
    -- The raised frame inset is measured afresh rather than carried into itself.
    return nil
end

function FairyRings:BeginVisuals()
    self.view = FairyRingMapView.New(self.session.content, self.session.tooltipLayer)
    self.view:Build()
end

function FairyRings:CalculateLayout()
    local session, mapLayout = self.session, self.mapLayout
    local availableWidth = session.layoutWidth - session.left - session.right - 16
    local availableHeight = session.layoutHeight - session.top - session.bottom - 16
    local width = math.max(1, math.min(980, availableWidth - mapLayout.sidebarWidth,
        availableHeight * 560 / 320))
    local mapHeight = math.max(1, math.floor(width * 320 / 560))

    return {
        width = math.floor(width),
        mapHeight = mapHeight,
        height = math.max(1, math.min(availableHeight, math.max(mapHeight, mapLayout.wheelHeight + 170))),
        sidebarWidth = mapLayout.sidebarWidth,
    }
end

function FairyRings:ApplyLayout(layout)
    local session = self.session
    local rows = self.mapLayout:ReadRows()

    for _, row in ipairs(rows) do
        row.code = table.concat(row.codes, "-"):upper()
        row.key = row.code .. ":" .. row.location
        row.point = #row.codes == 1 and destinations[row.code] or nil
    end

    self:LayoutWindow(layout.width + layout.sidebarWidth, layout.height)

    local sidebarTop = self.mapLayout:Layout(layout)
    self.view:Layout(session.left, session.top, layout, sidebarTop)

    local selected = component("COMBINATION_DESTINATION")
    local selectedName = selected and text.Trim(text.StripFormatting(selected.content)):lower() or ""
    local hovered = self.view:Update(rows, selectedName)

    self.mapLayout:UpdatePointer(self.view, hovered)
    FairyRingWheels.Update(self.session)
end

function FairyRings:UpdateVisuals()
    self.view:UpdateSearchAutoFocus(self.session.menu.snapshot.keyboardListener)
end

function FairyRings:GetHovered()
    -- The matched rows are the native wheels, not geographic destinations.
    -- The map view arbitrates its own passive destination probes.
    return nil
end

function FairyRings:ReleaseVisuals()
    cleanup.Release(self, "view")
end

function FairyRings:ReleaseInterface()
    if self.mapLayout ~= nil then
        self.mapLayout:RestoreRows()
    end

    ModalChoiceMenu.ReleaseInterface(self)
    FairyRingWheels.Restore(self.session)
    cleanup.Release(self, "mapLayout")
end

return FairyRings
