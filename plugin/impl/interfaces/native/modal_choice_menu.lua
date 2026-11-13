local TeleportMenu = require("impl/teleport_menu")
local nativeHelpers = require("impl/interfaces/native/native_helpers")
local NativeLayout = require("impl/interfaces/native/native_layout")
local NativeDragOutline = require("impl/interfaces/native/native_drag_outline")
local WindowDrag = require("impl/interfaces/native/window_drag")
local cleanup = require("impl/cleanup")
local teleportTooltip = require("impl/ui/teleport_tooltip")
local MenuUIToggle = require("impl/ui/menu_ui_toggle")
local components = require("impl/ui/components")
local ContentLayer = require("impl/ui/content_layer")
local text = require("impl/text")
local utils = require("impl/utils")
local settings = require("impl/settings")

local ModalChoiceMenu = TeleportMenu:Extend()
ModalChoiceMenu.interface = ModalChoiceMenu
ModalChoiceMenu.interfaceName = "MODAL_CHOICE (" .. id.Interface.MODAL_CHOICE .. ")"
ModalChoiceMenu.supportsOriginalUI = true
ModalChoiceMenu.nativeInterface = {
    trackedLayout = true,
    id = id.Interface.MODAL_CHOICE,
    prefix = "MODAL_CHOICE__",
    window = "MODAL_DIALOG_WINDOW",
    content = "MODAL_DIALOG_WINDOW_CONTENT",
    title = "TITLE",
    close = "MODAL_DIALOG_WINDOW_CLOSE_BUTTON",
    frame = { "MODAL_DIALOG_WINDOW_BACKGROUND", "MODAL_DIALOG_WINDOW_BORDER" },
    optionCount = 10,
    lastStaticID = 45,
}

local knownTitles = setmetatable({}, { __mode = "k" })
local frameInset = 5
local modalHost

-- Gather visible text without visiting a native component twice.
function ModalChoiceMenu:ReadOptionLabels(root, index)
    local labels = {}

    components.Walk(root, function(control)
        if not control.visibleGlobal then
            return false
        end

        local label

        if control.type == ui.ComponentType.LABEL then
            label = control.content
        elseif control.type == ui.ComponentType.BUTTON then
            label = control.label
        end

        label = text.Clean(label)

        if label ~= "" then
            labels[label] = true
        end
    end)

    return labels
end

-- Look up a named component in this menu's native interface.
local function component(menu, name)
    if name == nil then
        return nil
    end

    local componentID = id.Component[menu.interface.nativeInterface.prefix .. name]

    return componentID and ui.Interfaces:GetComponent(componentID) or nil
end

-- Some choice dialogs create their heading dynamically inside the border.
local function titleComponent(menu)
    local native = menu.interface.nativeInterface
    local title = component(menu, native.title)
    local parent = component(menu, native.titleParent)

    if title == nil and parent ~= nil then
        components.Walk(parent, function(control)
            if title == nil and control.type == ui.ComponentType.LABEL
                and control.dynamicID >= 0 and control.visibleGlobal then
                title = control
            end
        end)
    end

    return title
end

local function isWithin(control, parent)
    while control ~= nil and control ~= parent do
        control = control.parent
    end

    return control ~= nil
end

-- Read the interface once for all registered choice-menu candidates.
function ModalChoiceMenu:ReadInterface()
    local native = self.interface.nativeInterface
    local window = component(self, native.window)
    local content = component(self, native.content)

    if window == nil or not window.visibleGlobal then
        self:ReportMatch(nil)

        return nil
    end

    if content == nil or not isWithin(content, window) then
        self:ReportMatch({ "Not matched: missing " .. native.content .. " inside " .. native.window .. "." })

        return nil
    end

    local options = native.options and component(self, native.options) or window

    if options == nil or (native.options ~= nil and options.parent ~= content) then
        self:ReportMatch({ "Not matched: missing OPTIONS inside " .. native.content .. "." })

        return nil
    end

    local rows = {}

    for index = 1, native.optionCount do
        local row = component(self, "OPTION_" .. index)
        local click = native.directButtons and row or component(self, "OPTION_CLICK_" .. index)

        if row ~= nil and row.visibleGlobal then
            if click == nil then
                self:ReportMatch({ "Not matched: visible OPTION_" .. index .. " has no OPTION_CLICK_" .. index .. "." })

                return nil
            end

            local labels = self.interface:ReadOptionLabels(row, index)

            if not isWithin(click, row) then
                self:ReportMatch({
                    "Not matched: OPTION_CLICK_" .. index .. " is not a child of OPTION_" .. index .. ".",
                })

                return nil
            end

            if not isWithin(row, options) then
                self:ReportMatch({
                    "Not matched: OPTION_" .. index .. " is outside " .. (native.options or native.window) .. ".",
                })

                return nil
            end

            rows[#rows + 1] = {
                row = row,
                click = click,
                labels = labels,
                index = index,
            }
        end
    end

    if #rows == 0 then
        self:ReportMatch({ "Not matched: no visible option rows were found." })

        return nil
    end

    local title = titleComponent(self)
    local prompt = title ~= nil and title.type == ui.ComponentType.LABEL and text.Clean(title.content) or nil

    return {
        window = window,
        content = content,
        nativeRows = rows,
        prompt = prompt,
        closeButton = component(self, native.close),
    }
end

-- Treat controls as unavailable only when invisible or all named actions are explicitly hidden.
function ModalChoiceMenu:IsDisabled(row)
    local control = row.click

    if not control.visibleGlobal then
        return true
    end

    local ok, disabled = pcall(function()
        local ops = control.opConfig

        if ops == nil then
            return false
        end

        local hasNamedAction = false

        for index = 1, ops.numOpNames do
            local name = ops:GetOpName(index)

            if name ~= nil and name ~= "" then
                hasNamedAction = true

                if not ops:TestOpIsHidden(index) then
                    return false
                end
            end
        end

        return hasNamedAction
    end)

    return ok and disabled or false
end

-- Resolve a cached heading against the currently loaded interface.
local function currentTitle(interfaceID, title)
    if title.categoryID >= 0 and title.dynamicID >= 0 then
        return ui.Interfaces:GetComponent(interfaceID, title.staticID, title.categoryID, title.dynamicID)
    end

    return ui.Interfaces:GetComponent(interfaceID, title.staticID)
end

-- Replace generic headings while remembering renamed controls across menu sessions.
function ModalChoiceMenu:UpdateTitle()
    local session = self.session
    local native = self.interface.nativeInterface

    -- The identified heading may use a menu-specific prompt such as "Teleport to where?".
    if session.title ~= nil then
        NativeLayout.Set(session.title.control, "content", session.menu.title)

        if native.titleFont ~= nil then
            NativeLayout.Set(session.title.control, "font", native.titleFont)
        end

        knownTitles[session.title.control] = true
    end

    if session.titlesScanned then
        local valid = true

        for _, title in ipairs(session.titles) do
            local control = currentTitle(native.id, title)

            if control ~= title.control then
                valid = false
                break
            end

            if title.header then
                NativeLayout.Set(control, "header", session.menu.title)
            else
                NativeLayout.Set(control, "content", session.menu.title)
            end
        end

        if valid then
            return
        end

        session.titles = {}
    end

    local visited = {}

    local function inspect(control)
        if control.interfaceID ~= native.id then
            return false
        end

        local header = control.type == ui.ComponentType.GROUP_BOX

        if control.type == ui.ComponentType.LABEL or header then
            local label = header and control.headerText.content or control.content

            if label ~= nil and label ~= "" and control.visibleGlobal then
                local normalized = text.Clean(label):gsub("%s+", " "):upper()

                if normalized:match("^SELECT AN OPTION[%.:!]?$") or knownTitles[control] then
                    knownTitles[control] = true

                    if header then
                        NativeLayout.Set(control, "header", session.menu.title)
                    else
                        NativeLayout.Set(control, "content", session.menu.title)
                    end

                    session.titles[#session.titles + 1] = {
                        control = control,
                        header = header,
                        staticID = control.staticID,
                        categoryID = control.categoryID,
                        dynamicID = control.dynamicID,
                    }
                end
            end
        end
    end

    -- Generic headings can live outside the named TITLE component.
    for staticID = 0, native.lastStaticID do
        local control = ui.Interfaces:GetComponent(native.id, staticID)

        if control ~= nil then
            components.Walk(control, inspect, visited)
        end
    end

    session.titlesScanned = true
end

-- Preserve placement across pages without retaining native controls or plugin-owned artwork.
function ModalChoiceMenu:GetTransitionState(nextMenu, match)
    local session = self.session

    if session == nil or self.interface ~= nextMenu.interface or session.parent ~= match.window.parent then
        return nil
    end

    local relatedPage = self.pageGroup ~= nil and self.pageGroup == nextMenu.pageGroup
    local sameMenu = self == nextMenu and session.window == match.window

    if not relatedPage and not sameMenu then
        return nil
    end

    return {
        left = session.left,
        top = session.top,
        right = session.right,
        bottom = session.bottom,
        windowPosition = session.windowPosition,
    }
end

-- Capture the native modal host before resizing, including its outer-frame padding.
function ModalChoiceMenu:GetLayoutHost(window)
    local content, containers, padding = nativeHelpers.ReadLayoutHost(
        window,
        id.Component.TOPLEVEL_V2__MODAL_WINDOW,
        id.Component.TOPLEVEL_V2__MODAL_WINDOW_CONTENT,
        "modal"
    )

    modalHost = padding

    return content, containers, padding
end

-- CHOICE_V2 shares the native size baseline, even while an enlarged modal is open.
function ModalChoiceMenu:GetModalHostSize()
    local content = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__MODAL_WINDOW_CONTENT)

    if content ~= nil and modalHost ~= nil and components.Key(content) == components.Key(modalHost.content) then
        return modalHost.contentWidth, modalHost.contentHeight
    end

    return content and content.width or 512, content and content.height or 334
end

function ModalChoiceMenu:GetLayoutBudget(session, sizeMultiplier)
    local padding = session.hostPadding

    return nativeHelpers.FitLayoutHost(session, padding.contentWidth, padding.contentHeight, sizeMultiplier)
end

-- Measure without resizing native controls. Only the final fitted rectangle is
-- applied, so native drag/layout callbacks never see a temporary oversized host.
function ModalChoiceMenu:UpdateLayoutHost(session, sizeMultiplier)
    session.layoutWidth, session.layoutHeight = self.interface:GetLayoutBudget(session, sizeMultiplier)
end

-- Measure native margins or reuse the current page group's placement before attaching tooltips.
function ModalChoiceMenu:BeginInterface(placement)
    local session = self.session
    local native = self.interface.nativeInterface
    local menu = session.menu
    local window, content = menu.window, menu.content

    session.layoutParent, session.hostContainers, session.hostPadding = self.interface:GetLayoutHost(window)

    if session.layoutParent == nil then
        return false
    end

    -- Include headings outside the window, which UpdateTitle can also modify.
    local controls, visited = {}, {}

    local function capture(control)
        if control.interfaceID ~= native.id then
            return false
        end

        controls[#controls + 1] = control
    end

    components.Walk(window, capture, visited)

    for staticID = 0, native.lastStaticID do
        local control = ui.Interfaces:GetComponent(native.id, staticID)

        if control ~= nil then
            components.Walk(control, capture, visited)
        end
    end

    for _, control in ipairs(session.hostContainers) do
        controls[#controls + 1] = control
    end

    session.nativeLayout = NativeLayout.FromControls(controls)

    if not native.independentDrag then
        session.dragOutline = NativeDragOutline.New(session.hostContainers[1])
    end

    local windowPos, contentPos = window.xyGlobal, content.xyGlobal

    session.window, session.content = window, content
    session.parent = window.parent

    -- Presentations fill the frame interior rather than retaining the native text list's padding.
    session.left = frameInset
    session.top = math.max(32, contentPos.y - windowPos.y)
    session.right = frameInset
    session.bottom = frameInset

    if placement ~= nil then
        session.left, session.top = placement.left, placement.top
        session.right, session.bottom = placement.right, placement.bottom
    end

    session.rows, session.titles, session.tooltips, session.tooltipContexts = {}, {}, {}, {}
    session.frame = {}

    -- Frame artwork can be inset from the window bounds, especially the background fill.
    for _, name in ipairs(native.frame) do
        local control = component(self, name)

        if control ~= nil then
            local position = control.xyGlobal

            session.frame[#session.frame + 1] = {
                control = control,
                left = position.x - windowPos.x,
                top = position.y - windowPos.y,
                right = windowPos.x + window.width - position.x - control.width,
                bottom = windowPos.y + window.height - position.y - control.height,
            }
        end
    end

    for _, row in ipairs(menu.rows) do
        if not row.locked then
            session.rows[#session.rows + 1] = row
        end
    end

    local close = component(self, native.close)

    if close ~= nil then
        local position = close.xyGlobal

        session.close = {
            control = close,
            right = windowPos.x + window.width - position.x - close.width,
            top = position.y - windowPos.y,
            width = close.width,
            height = close.height,
        }
    end

    local title = titleComponent(self)

    if title ~= nil and title.type == ui.ComponentType.LABEL then
        local position = title.xyGlobal

        session.title = {
            control = title,
            left = position.x - windowPos.x,
            right = windowPos.x + window.width - position.x - title.width,
            top = position.y - windowPos.y,
            height = title.height,
        }
    end

    local overlay = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP) or session.parent

    -- Own the entire tooltip subtree before calling PrettyUI: a failed constructor may
    -- have created components without returning an attachment we can individually destroy.
    session.tooltipMount = ContentLayer.New(overlay)
    session.tooltipLayer = session.tooltipMount.root

    session.nativeLayout:Apply(function()
        for index, entry in ipairs(session.rows) do
            if not entry.destination.hidden then
                local target = self:GetTooltipTarget(entry, index)

                if target ~= nil then
                    self:AttachTooltip(entry, target)
                end
            end
        end
    end)

    session.positionKey = self.enabledSetting or self.key
    session.windowPosition = placement and placement.windowPosition
        or settings.GetWindowPosition(session.positionKey) or self.windowPosition
    session.restoreWindowPosition = session.windowPosition ~= nil

    -- Independent dragging keeps placement in the plugin instead of native window settings.
    if native.independentDrag then
        WindowDrag.New(session, overlay)
    end
end

function ModalChoiceMenu:GetTooltipTarget(entry)
    return entry.click
end

function ModalChoiceMenu:AttachTooltip(entry, target)
    local session, parent = self.session, target.parent

    if not session.tooltipContexts[parent] then
        prettyui.Tooltip.registerContext(parent, session.tooltipLayer, function(control)
            local position, overlay = control.xyGlobal, session.tooltipLayer.xyGlobal

            return position.x - overlay.x, position.y - overlay.y
        end)

        session.tooltipContexts[parent] = true
    end

    session.tooltips[entry.name] = teleportTooltip.Attach(
        target, parent,
        self:GetDisplayName(entry), entry.destination.description
    )
end

-- Track overrides for maps and every modal subclass, including partially failed updates.
function ModalChoiceMenu:Update(snapshot)
    -- Adapters opt in after routing all native writes through NativeLayout.
    local apply = self.interface.nativeInterface.trackedLayout and NativeLayout.Track or NativeLayout.Apply

    apply(self.session.nativeLayout, function()
        self:UpdateLayoutHost(self.session, self:GetSizeMultiplier())
        TeleportMenu.Update(self, snapshot)
    end)
end

-- Measure only horizontal header clearance; retain the native title-bar height.
function ModalChoiceMenu:HeaderLayout()
    local session = self.session
    local title, close = session.title, session.close
    local left = self.supportsOriginalUI and MenuUIToggle.HeaderInset() or 16
    local right = 16

    if close ~= nil and close.control.visibleGlobal then
        right = math.max(right, close.right + close.width + 8)
    end

    if title ~= nil then
        left = math.max(left, title.left)
    end

    -- Keep breathing room between the title and both header controls.
    left, right = left + 15, right + 15

    local fontID = title and title.control.font
    local content = title and title.control.content
    local measurement = session.headerMeasurement

    if measurement == nil or measurement.font ~= fontID or measurement.content ~= content
        or measurement.title ~= session.menu.title then
        local measured, width = false, nil

        if fontID ~= nil then
            measured, width = pcall(function()
                local font = config.Font.FromID(fontID)
                local titleWidth = font:GetStringWidth(session.menu.title, false)

                return content == session.menu.title and titleWidth
                    or math.max(titleWidth, font:GetStringWidth(content, false))
            end)
        end

        measurement = {
            font = fontID,
            content = content,
            title = session.menu.title,
            width = measured and width or #text.StripFormatting(session.menu.title) * 8,
        }
        session.headerMeasurement = measurement
    end

    return {
        left = left,
        right = right,
        width = left + measurement.width + right,
    }
end

-- Definitions can enlarge or shrink the layout budget while retaining the native header.
function ModalChoiceMenu:GetSizeMultiplier()
    local multiplier = self.session.menu.group.sizeMultiplier or 1

    assert(utils.IsFinite(multiplier) and multiplier > 0, "Menu sizeMultiplier must be a positive number")

    return multiplier
end

-- Apply a global rectangle in a native control's parent coordinate space.
local function setRect(control, x, y, width, height)
    local parentPosition = control.parent.xyGlobal

    NativeLayout.SetPos(control, math.floor(x - parentPosition.x), math.floor(y - parentPosition.y))
    NativeLayout.SetSize(control, width, height)
end

-- Follow native or plugin-owned placement, constraining the fitted host at viewport edges.
-- The content inset is local and never added back into the host's position.
function ModalChoiceMenu:PositionLayoutHost()
    local session = self.session

    if session.windowPosition ~= nil and (session.windowDrag ~= nil or session.restoreWindowPosition) then
        local frame = session.hostContainers[1]
        local parent = frame.parent.xyGlobal
        NativeLayout.SetPos(frame, session.windowPosition.x - parent.x, session.windowPosition.y - parent.y)
    end

    session.restoreWindowPosition = nil
    nativeHelpers.ClampWindowHost(session)

    local origin = session.hostContainers[1].xyGlobal
    local previous = session.windowPosition

    if previous == nil or previous.x ~= origin.x or previous.y ~= origin.y then
        session.windowPosition = { x = origin.x, y = origin.y }
    end

    self.windowPosition = session.windowPosition
    session.appliedWindowPosition = session.windowPosition

    local position = session.layoutParent.xyGlobal

    return position.x + 8, position.y + 8
end

-- Resize the native window and clipping containers for either maps or custom menu layouts.
function ModalChoiceMenu:LayoutWindow(width, height)
    local session = self.session

    self:UpdateTitle()

    local window, content = session.window, session.content
    local windowWidth, windowHeight = width + session.left + session.right, height + session.top + session.bottom

    nativeHelpers.SizeWindowHost(session, windowWidth, windowHeight)

    local x, y = self:PositionLayoutHost()

    setRect(window, x, y, windowWidth, windowHeight)

    local origin = window.xyGlobal

    for _, frame in ipairs(session.frame) do
        setRect(
            frame.control,
            origin.x + frame.left, origin.y + frame.top,
            math.max(1, windowWidth - frame.left - frame.right),
            math.max(1, windowHeight - frame.top - frame.bottom)
        )
    end

    -- Content may be nested inside the background; position it after its frame ancestors.
    setRect(content, origin.x + session.left, origin.y + session.top, width, height)

    local close = session.close

    if close ~= nil then
        setRect(
            close.control,
            origin.x + windowWidth - close.width - close.right,
            origin.y + close.top, close.width, close.height
        )
    end

    local title = session.title

    if title ~= nil then
        local header = self:HeaderLayout()

        NativeLayout.Set(title.control, "maxLines", 1)
        setRect(
            title.control,
            origin.x + header.left, origin.y + title.top,
            math.max(1, windowWidth - header.left - header.right), title.height
        )
    end

    self:LayoutRowContainers(origin.x + session.left, origin.y + session.top, width, height)

    if session.windowDrag ~= nil then
        session.windowDrag:Update()
    else
        session.dragOutline:Update(window)

        if session.dragOutline.layout ~= nil then
            session.nativeLayout:PreservePosition(session.hostContainers[1])
        end
    end

    local dragging = session.windowDrag ~= nil and session.windowDrag.drag ~= nil
        or session.dragOutline ~= nil and session.dragOutline.layout ~= nil

    if not dragging then
        self:SaveWindowPosition()
    end
end

-- Persist settled, clamped geometry rather than every pointer update. The cached
-- applied position also remains safe to save after the client closes the window.
function ModalChoiceMenu:SaveWindowPosition()
    local session = self.session
    local position = session.appliedWindowPosition

    if position ~= nil and position ~= session.savedWindowPosition then
        settings.SetWindowPosition(session.positionKey, position)
        session.savedWindowPosition = position
    end
end

-- Expand intermediate clipping containers before moving their individual rows.
function ModalChoiceMenu:LayoutRowContainers(x, y, width, height)
    local session = self.session
    local window, content = session.window, session.content
    local expanded = {}

    for _, entry in ipairs(session.rows) do
        local ancestors, ancestor = {}, entry.row.parent

        while ancestor ~= nil and ancestor ~= window and ancestor ~= content do
            ancestors[#ancestors + 1] = ancestor
            ancestor = ancestor.parent
        end

        for index = #ancestors, 1, -1 do
            local control = ancestors[index]

            if control ~= content and not expanded[control] then
                setRect(control, x, y, width, height)
                NativeLayout.Set(control, "clickthrough", true)
                expanded[control] = true
            end
        end
    end
end

-- Suppress native child artwork without hiding controls from matching or input.
function ModalChoiceMenu:HideRowArtwork(entry)
    components.Walk(entry.row, function(control)
        NativeLayout.Set(control, "alpha", 0)
    end)
end

-- Position a native row and its input hierarchy without replacing its actions or hooks.
function ModalChoiceMenu:LayoutRow(entry, x, y, width, height)
    setRect(entry.row, x, y, width, height)
    NativeLayout.Set(entry.row, "alpha", 0)
    NativeLayout.Set(entry.row, "clickthrough", entry.row ~= entry.click)

    if entry.row == entry.click then
        self:HideRowArtwork(entry)
    end

    local chain, control = {}, entry.click

    while control ~= entry.row do
        chain[#chain + 1] = control
        control = control.parent
    end

    for index = #chain, 1, -1 do
        control = chain[index]
        NativeLayout.SetPos(control, 0, 0)
        NativeLayout.SetSize(control, width, height)
        NativeLayout.Set(control, "clickthrough", control ~= entry.click)
    end
end

-- Presentations supply global rectangles; adapters retain ownership of native input.
function ModalChoiceMenu:LayoutRows(rectangles, width, height)
    for _, rectangle in ipairs(rectangles) do
        self:HideRowArtwork(rectangle.entry)
        self:LayoutRow(rectangle.entry, rectangle.x, rectangle.y, rectangle.width, rectangle.height)
    end
end

-- Maps and slot menus share native tooltip attachments and hover selection.
function ModalChoiceMenu:UpdateTooltips(hovered)
    for name, tooltip in pairs(self.session.tooltips) do
        if name == hovered then
            tooltip:Show()
        else
            tooltip:Hide()
        end
    end
end

-- Remove plugin hooks before restoring surviving native controls to their client layout.
function ModalChoiceMenu:ReleaseTooltips()
    if self.session == nil then
        return
    end

    for _, tooltip in pairs(self.session.tooltips or {}) do
        cleanup.Try("destroy teleport tooltip", function()
            tooltip:Destroy()
        end)
    end

    for parent in pairs(self.session.tooltipContexts or {}) do
        cleanup.Try("unregister teleport tooltip context", function()
            prettyui.Tooltip.unregisterContext(parent)
        end)
    end

    self.session.tooltips, self.session.tooltipContexts = {}, {}
    cleanup.Release(self.session, "tooltipMount")
    self.session.tooltipLayer = nil
end

function ModalChoiceMenu:ReleaseInterface()
    if self.session == nil then
        return
    end

    cleanup.Try("save window position", function()
        self:SaveWindowPosition()
    end)

    self:ReleaseTooltips()
    cleanup.Release(self.session, "windowDrag")
    cleanup.Release(self.session, "dragOutline", "Restore")
    cleanup.Release(self.session, "nativeLayout", "Restore")

    if modalHost == self.session.hostPadding then
        modalHost = nil
    end
end

return ModalChoiceMenu
