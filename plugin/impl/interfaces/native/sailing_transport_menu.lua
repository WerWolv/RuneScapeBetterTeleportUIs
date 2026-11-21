local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local NativeLayout = require("impl/interfaces/native/native_layout")
local NativeCloseButton = require("impl/interfaces/native/native_close_button")
local ContentLayer = require("impl/ui/content_layer")
local InputShield = require("impl/ui/input_shield")
local cleanup = require("impl/cleanup")
local components = require("impl/ui/components")

local SailingTransportMenu = ModalChoiceMenu:Extend()
SailingTransportMenu.interface = SailingTransportMenu
SailingTransportMenu.cacheNativeSnapshot = true
SailingTransportMenu.interfaceName = "SAILING_TRANSPORT_WORLD_MAP (" .. id.Interface.SAILING_TRANSPORT_WORLD_MAP .. ")"
SailingTransportMenu.nativeInterface = {
    trackedLayout = true,
    customWindow = true,
    id = id.Interface.SAILING_TRANSPORT_WORLD_MAP,
    prefix = "SAILING_TRANSPORT_WORLD_MAP__",
    close = "CLOSE_BUTTON",
    frame = {},
    lastStaticID = 37,
}

local tooltipHookID = "teleportMapsSailingTooltip"
local tooltipHooks = { ui.Hook.ONMOUSEOVER, ui.Hook.ONMOUSEREPEAT }

local function component(name)
    return ui.Interfaces:GetComponent(id.Component["SAILING_TRANSPORT_WORLD_MAP__" .. name])
end

-- The final menu declares the ports. Give its adapter those bindings before
-- registration, retaining native component order for stable row identities.
function SailingTransportMenu:New()
    local menu = ModalChoiceMenu.New(self)
    local interface = SailingTransportMenu:Extend()
    interface.interface = interface
    interface.bindings = {}

    for port in pairs(menu.definition.entries) do
        local componentID = id.Component["SAILING_TRANSPORT_WORLD_MAP__SAILING_TRANSPORT_GO_" .. port]
        assert(componentID ~= nil, "Unknown sailing port: " .. port)
        interface.bindings[#interface.bindings + 1] = { key = port, componentID = componentID }
    end

    table.sort(interface.bindings, function(a, b)
        return a.componentID < b.componentID
    end)

    menu.interface = interface
    return menu
end

function SailingTransportMenu:ReadInterface()
    local map = component("SAILING_TRANSPORT_WORLD_MAP")
    local window = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__MODAL_WINDOW)
    local content = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__MODAL_WINDOW_CONTENT)

    if map == nil or window == nil or not window.visibleGlobal then
        return nil
    end

    if content == nil or not content.visibleGlobal or map.parent ~= content or content.parent ~= window then
        self:ReportMatch({ "Not matched: unexpected sailing modal host hierarchy." })
        return nil
    end

    local rows, artwork = {}, {}

    local function addArtwork(name)
        local control = component(name)
        if control == nil then
            return false
        end

        artwork[#artwork + 1] = { name = name, control = control, parent = control.parent }
        return true
    end

    addArtwork("SAILING_TRANSPORT_WORLD_MAP")

    for index, binding in ipairs(self.bindings) do
        local port = binding.key
        local click = ui.Interfaces:GetComponent(binding.componentID)

        if click == nil or click.parent ~= content
            or not addArtwork("SAILING_TRANSPORT_" .. port .. "_MARKER")
            or not addArtwork("SAILING_TRANSPORT_" .. port) then
            self:ReportMatch({ "Not matched: missing sailing controls for " .. port .. "." })
            return nil
        end

        -- Keep the fixed native identities even while the client hides a port.
        rows[index] = {
            index = index,
            row = click,
            click = click,
            labels = { [port] = true },
        }
    end

    return {
        window = window,
        content = content,
        map = map,
        artwork = artwork,
        nativeRows = rows,
        closeButton = component("CLOSE_BUTTON"),
    }
end

function SailingTransportMenu:GetSnapshot()
    local snapshot = ModalChoiceMenu.GetSnapshot(self)
    if snapshot == nil then
        return nil
    end

    -- The shared host can survive after interface 95 closes or is replaced.
    local current = snapshot.content.parent == snapshot.window
        and component("SAILING_TRANSPORT_WORLD_MAP") == snapshot.map
        and snapshot.content.visibleGlobal
        and component("CLOSE_BUTTON") == snapshot.closeButton

    for index, binding in ipairs(self.bindings) do
        local row = snapshot.nativeRows[index]
        current = current and ui.Interfaces:GetComponent(binding.componentID) == row.click
            and row.click.parent == snapshot.content
    end

    for _, artwork in ipairs(snapshot.artwork) do
        current = current and component(artwork.name) == artwork.control and artwork.control.parent == artwork.parent
    end

    if not current then
        self:InvalidateSnapshot()
        return ModalChoiceMenu.GetSnapshot(self)
    end

    return snapshot
end

function SailingTransportMenu:Matches(snapshot)
    return self.session ~= nil and self.session.menu.snapshot == snapshot
end

-- Unlike nested choice dialogs, sailing uses the shared host as its window.
function SailingTransportMenu:GetLayoutHost(window)
    local content = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__MODAL_WINDOW_CONTENT)
    if content == nil or content.parent ~= window or not window.visibleGlobal then
        return nil
    end

    local containers = { window, content }
    for _, componentID in ipairs({
        id.Component.TOPLEVEL_V2__MODAL_WINDOW_BACKGROUND,
        id.Component.TOPLEVEL_V2__MODAL_WINDOW_BORDER,
        id.Component.TOPLEVEL_V2__MODAL_WINDOW_CONTENT_2,
    }) do
        local control = ui.Interfaces:GetComponent(componentID)
        if control ~= nil then
            containers[#containers + 1] = control
        end
    end

    -- PrettyUI supplies the frame; retain the native size as the layout budget.
    return content, containers, {
        content = content,
        width = 0,
        height = 0,
        contentWidth = window.width,
        contentHeight = window.height,
        left = 0,
        top = 0,
    }
end

function SailingTransportMenu:BeginInterface(placement)
    if ModalChoiceMenu.BeginInterface(self, placement) == false then
        return false
    end

    local session = self.session
    local origin = session.window.xyGlobal
    local position = session.windowPosition or { x = origin.x, y = origin.y }

    session.nativeClose = NativeCloseButton.New(session.menu.snapshot.closeButton)
    session.left, session.right, session.bottom = 8, 8, 8
    session.top = 32
    session.nativeLayout:Track(function()
        self:LayoutSailingHost()
    end)

    -- Own the window and its sibling drag/scroll overlays under a single mount.
    session.windowMount = ContentLayer.New(session.layoutParent)
    local parent = session.layoutParent.xyGlobal
    session.sailingWindow = prettyui.Window.new(session.windowMount.root, {
        title = session.menu.title,
        x = position.x - parent.x,
        y = position.y - parent.y,
        width = session.hostPadding.contentWidth,
        height = session.hostPadding.contentHeight,
        minWidth = 1,
        minHeight = 1,
        scrollable = false,
        resizable = false,
        respectInterfaceLock = false,
        destroyOnClose = false,
    })
    local window = session.sailingWindow
    window.titleText.rgb = config.Struct.TOPLEVEL_V2_DEFAULT_MAIN_MODAL_SKIN_DATA
        :GetParamValue(config.Param.TOPLEVEL_V2_WINDOW_TITLE_COLOUR)
    session.content = window.content

    -- Injected native interface roots cannot be reordered, even though their
    -- displayed parent is the modal content. Let input reach them underneath.
    components.Walk(window.root, function(control)
        control.clickthrough = true
    end)

    -- The native hitbox owns closing; PrettyUI supplies only the artwork.
    window.closeButton.enabled = false
    window.closeButton.clickthrough = true
    if session.close ~= nil then
        session.close.right = 8
        session.close.width, session.close.height = window.closeButton.width, window.closeButton.height
    end

    window:Show()
    session.inputShield = InputShield.New(window.root)
end

function SailingTransportMenu:UpdateTitle()
    -- PrettyUI owns the heading.
end

function SailingTransportMenu:GetUIToggleWindow()
    return self.session and self.session.sailingWindow and self.session.sailingWindow.root
end

function SailingTransportMenu:AttachTooltip(entry, target)
    ModalChoiceMenu.AttachTooltip(self, entry, target)

    local controls = self.session.nativeTooltipControls or {}
    self.session.nativeTooltipControls = controls
    controls[#controls + 1] = target

    for _, hook in ipairs(tooltipHooks) do
        target:Subscribe(hook, tooltipHookID, function()
            return false
        end)
    end
end

function SailingTransportMenu:LayoutRowContainers()
    -- GO layers are already direct children of the shared content. Expanding
    -- their ancestors as nested choice rows would overwrite the modal frame.
    for _, artwork in ipairs(self.session.menu.snapshot.artwork) do
        NativeLayout.Set(artwork.control, "hidden", true)
        NativeLayout.Set(artwork.control, "clickthrough", true)
    end
end

-- Native action owners cannot be reparented. Give their modal a viewport-sized
-- transparent input host so they can follow PrettyUI anywhere it is dragged.
function SailingTransportMenu:LayoutSailingHost()
    local session = self.session
    local viewport = assert(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__VIEWPORT))
    local origin, parent = viewport.xyGlobal, session.window.parent.xyGlobal

    NativeLayout.SetPos(session.window, origin.x - parent.x, origin.y - parent.y)
    NativeLayout.SetSize(session.window, viewport.width, viewport.height)
    NativeLayout.SetPos(session.layoutParent, 0, 0)
    NativeLayout.SetSize(session.layoutParent, 0, 0, 1.0, 1.0)
    NativeLayout.Set(session.window, "clickthrough", true)
    NativeLayout.Set(session.layoutParent, "clickthrough", true)

    for index = 3, #session.hostContainers do
        NativeLayout.Set(session.hostContainers[index], "hidden", true)
    end
end

function SailingTransportMenu:LayoutWindow(width, height)
    local session = self.session
    local window = session.sailingWindow
    self:LayoutSailingHost()

    local windowWidth = width + session.left + session.right
    local windowHeight = height + session.top + session.bottom
    local x = math.max(0, math.min(window.root.x, window.parent.width - windowWidth))
    local y = math.max(0, math.min(window.root.y, window.parent.height - windowHeight))
    local moved = x ~= window.root.x or y ~= window.root.y
    if moved then
        window.root:SetPos(x, y)
    end

    if moved or window.root.width ~= windowWidth or window.root.height ~= windowHeight then
        window:SetSize(windowWidth, windowHeight)
    end

    if session.nativeClose ~= nil then
        window.closeSprite.spriteID = session.nativeClose:Layout(window.closeButton)
            and id.Sprite.RS3_BTN_MODAL_WINDOW_1_CLOSE_OVR or id.Sprite.RS3_BTN_MODAL_WINDOW_1_CLOSE_NML
    end

    self:LayoutRowContainers()

    local position, previous = window.root.xyGlobal, session.appliedWindowPosition
    if previous == nil or previous.x ~= position.x or previous.y ~= position.y then
        session.windowPosition = { x = position.x, y = position.y }
        session.appliedWindowPosition = session.windowPosition
    end

    if window.dragFeedback == nil then
        self:SaveWindowPosition()
    end
end

function SailingTransportMenu:LayoutRows(rectangles, width, height)
    ModalChoiceMenu.LayoutRows(self, rectangles, width, height)

    local session = self.session
    local root = session.sailingWindow.root
    local origin, holes = root.xyGlobal, {}

    local function openHitbox(control)
        if control == nil or not control.visibleGlobal or control.width <= 0 or control.height <= 0 then
            return
        end

        local position = control.xyGlobal
        holes[#holes + 1] = {
            x = position.x - origin.x, y = position.y - origin.y,
            width = control.width, height = control.height,
        }
    end

    for _, row in ipairs(session.rows) do
        if not row.destination.hidden then
            openHitbox(row.click)
        end
    end

    openHitbox(session.close and session.close.control)
    session.inputShield:Layout(root.width, root.height, holes)
end

function SailingTransportMenu:ReleaseInterface()
    if self.session == nil then
        return
    end

    for _, control in ipairs(self.session.nativeTooltipControls or {}) do
        for _, hook in ipairs(tooltipHooks) do
            cleanup.Try("restore sailing hover tooltip", function()
                control:Unsubscribe(hook, tooltipHookID)
            end)
        end
    end

    self.session.nativeTooltipControls = nil
    cleanup.Release(self.session, "inputShield")
    cleanup.Release(self.session, "sailingWindow")
    cleanup.Release(self.session, "windowMount")
    ModalChoiceMenu.ReleaseInterface(self)
    cleanup.Release(self.session, "nativeClose", "Restore")
end

return SailingTransportMenu
