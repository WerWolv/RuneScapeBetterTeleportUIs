local TeleportMenu = require("impl/teleport_menu")
local teleportTooltip = require("impl/teleport_tooltip")
local geometry = require("impl/map_geometry")
local constants = require("definitions/constants")
local BackgroundView = require("impl/background_view")
local ButtonIcon = require("impl/button_icon")
local components = require("impl/components")
local text = require("impl/text")
local ModalChoiceMenu = TeleportMenu:Extend()
ModalChoiceMenu.interface = ModalChoiceMenu
ModalChoiceMenu.interfaceName = "MODAL_CHOICE (" .. id.Interface.MODAL_CHOICE .. ")"
local knownTitles = setmetatable({}, {__mode = "k"})
local frameInset, hitboxScale = 5, 0.75

-- Gather visible text without visiting a native component twice.
local function collectLabels(root)
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

-- Look up a named component belonging to MODAL_CHOICE.
local function component(name)
    local componentID = id.Component["MODAL_CHOICE__" .. name]
    return componentID and ui.Interfaces:GetComponent(componentID) or nil
end

-- Read the interface once for all registered modal-choice menu candidates.
function ModalChoiceMenu:ReadInterface()
    local window = component("MODAL_DIALOG_WINDOW")
    local content = component("MODAL_DIALOG_WINDOW_CONTENT")
    if window == nil or not window.visibleGlobal then
        self:ReportMatch(nil)
        return nil
    end
    if content == nil then
        self:ReportMatch({"Not matched: missing MODAL_DIALOG_WINDOW_CONTENT."})
        return nil
    end
    local rows = {}
    for index = 1, 10 do
        local row = component("OPTION_" .. index)
        local click = component("OPTION_CLICK_" .. index)
        if row ~= nil and row.visibleGlobal then
            if click == nil then
                self:ReportMatch({"Not matched: visible OPTION_" .. index .. " has no OPTION_CLICK_" .. index .. "."})
                return nil
            end
            local labels = collectLabels(row)
            local ancestor = click
            while ancestor ~= nil and ancestor ~= row do ancestor = ancestor.parent end
            if ancestor == nil then
                self:ReportMatch({"Not matched: OPTION_CLICK_" .. index .. " is not a child of OPTION_" .. index .. "."})
                return nil
            end
            ancestor = row
            while ancestor ~= nil and ancestor ~= window do ancestor = ancestor.parent end
            if ancestor == nil then
                self:ReportMatch({"Not matched: OPTION_" .. index .. " is outside MODAL_DIALOG_WINDOW."})
                return nil
            end
            rows[#rows + 1] = {row = row, click = click, labels = labels, index = index}
        end
    end
    if #rows == 0 then
        self:ReportMatch({"Not matched: no visible option rows were found."})
        return nil
    end
    local title = component("TITLE")
    local prompt = title ~= nil and title.type == ui.ComponentType.LABEL and text.Clean(title.content) or nil
    return {window = window, content = content, nativeRows = rows, prompt = prompt}
end

-- Require visible map destinations to have artwork, coordinates and a shared background.
function ModalChoiceMenu:ValidateDestination(definition, background)
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

-- Treat controls as unavailable only when invisible or all named actions are explicitly hidden.
function ModalChoiceMenu:IsDisabled(row)
    local control = row.click
    if not control.visibleGlobal then return true end
    local ok, disabled = pcall(function()
        local ops = control.opConfig
        if ops == nil then return false end
        local hasNamedAction = false
        for index = 1, ops.numOpNames do
            local name = ops:GetOpName(index)
            if name ~= nil and name ~= "" then
                hasNamedAction = true
                if not ops:TestOpIsHidden(index) then return false end
            end
        end
        return hasNamedAction
    end)
    return ok and disabled or false
end

-- Resolve a cached heading against the currently loaded interface.
local function currentTitle(title)
    if title.categoryID >= 0 and title.dynamicID >= 0 then
        return ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, title.staticID, title.categoryID, title.dynamicID)
    end
    return ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, title.staticID)
end

-- Replace generic headings while remembering renamed controls across menu sessions.
function ModalChoiceMenu:UpdateTitle()
    local session = self.session
    if #session.titles > 0 then
        local valid = true
        for _, title in ipairs(session.titles) do
            local control = currentTitle(title)
            if control ~= title.control then valid = false; break end
            if title.header then control.headerText.content = session.menu.title
            else control.content = session.menu.title end
        end
        if valid then return end
        session.titles = {}
    end
    local visited = {}
    local function inspect(control)
        if control.interfaceID ~= id.Interface.MODAL_CHOICE then
            return false
        end

        local header = control.type == ui.ComponentType.GROUP_BOX
        if control.type == ui.ComponentType.LABEL or header then
            local label = header and control.headerText.content or control.content
            if label ~= nil and label ~= "" and control.visibleGlobal then
                local normalized = text.Clean(label):gsub("%s+", " "):upper()
                if normalized:match("^SELECT AN OPTION[%.:!]?$") or knownTitles[control] then
                    knownTitles[control] = true
                    if header then control.headerText.content = session.menu.title
                    else control.content = session.menu.title end
                    session.titles[#session.titles + 1] = {
                        control = control, header = header, staticID = control.staticID,
                        categoryID = control.categoryID, dynamicID = control.dynamicID,
                    }
                end
            end
        end
    end
    -- Generic headings can live outside the named TITLE component.
    for staticID = 0, 45 do
        local control = ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, staticID)
        if control ~= nil then
            components.Walk(control, inspect, visited)
        end
    end
end

-- Preserve placement across pages without retaining native controls or plugin-owned artwork.
function ModalChoiceMenu:GetTransitionState(nextMenu, match)
    local session = self.session
    if session == nil or self.interface ~= nextMenu.interface or session.parent ~= match.window.parent then
        return nil
    end
    local relatedPage = self.pageGroup ~= nil and self.pageGroup == nextMenu.pageGroup
    local sameMenu = self == nextMenu and session.window == match.window
    if not relatedPage and not sameMenu then return nil end
    return {
        left = session.left, top = session.top, right = session.right, bottom = session.bottom,
        centerX = session.centerX, centerY = session.centerY,
    }
end

-- Measure native margins or reuse the current page group's placement before attaching tooltips.
function ModalChoiceMenu:BeginInterface(placement)
    local session = self.session
    local menu = session.menu
    local window, content = menu.window, menu.content
    local windowPos, contentPos = window.xyGlobal, content.xyGlobal
    session.window, session.content = window, content
    session.parent = window.parent
    -- Maps fill the frame interior rather than retaining the native text list's padding.
    session.left = frameInset
    session.top = math.max(32, contentPos.y - windowPos.y)
    session.right = frameInset
    session.bottom = frameInset
    session.centerX, session.centerY = window.x + window.width / 2, window.y + window.height / 2
    if placement ~= nil then
        session.left, session.top = placement.left, placement.top
        session.right, session.bottom = placement.right, placement.bottom
        session.centerX, session.centerY = placement.centerX, placement.centerY
    end
    session.rows, session.titles, session.tooltips, session.tooltipContexts = {}, {}, {}, {}
    session.frame = {}

    -- Frame artwork can be inset from the window bounds, especially the background fill.
    for _, name in ipairs({"MODAL_DIALOG_WINDOW_BACKGROUND", "MODAL_DIALOG_WINDOW_BORDER"}) do
        local control = component(name)

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
        if not row.locked then session.rows[#session.rows + 1] = row end
    end
    local close = component("MODAL_DIALOG_WINDOW_CLOSE_BUTTON")
    if close ~= nil then
        local position = close.xyGlobal
        session.close = {
            control = close, right = windowPos.x + window.width - position.x - close.width,
            top = position.y - windowPos.y, width = close.width, height = close.height,
        }
    end
    local title = component("TITLE")
    if title ~= nil and title.type == ui.ComponentType.LABEL then
        local position = title.xyGlobal
        session.title = {
            control = title, left = position.x - windowPos.x,
            right = windowPos.x + window.width - position.x - title.width,
            top = position.y - windowPos.y, height = title.height,
        }
    end
    local overlay = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP) or window.parent

    -- Own the entire tooltip subtree before calling PrettyUI: a failed constructor may
    -- have created components without returning an attachment we can individually destroy.
    session.tooltipLayer = ui.Layer.new(overlay)
    session.tooltipLayer:SetSize(0, 0, 1.0, 1.0)
    session.tooltipLayer.clickthrough = true

    for _, entry in ipairs(session.rows) do
        if not entry.destination.hidden then
            local parent = entry.click.parent
            if not session.tooltipContexts[parent] then
                prettyui.Tooltip.registerContext(parent, session.tooltipLayer, function(target)
                    local targetPosition, overlayPosition = target.xyGlobal, session.tooltipLayer.xyGlobal
                    return targetPosition.x - overlayPosition.x, targetPosition.y - overlayPosition.y
                end)
                session.tooltipContexts[parent] = true
            end
            session.tooltips[entry.name] = teleportTooltip.Attach(entry.click, parent,
                self:GetDisplayName(entry), entry.destination.description)
        end
    end
end

-- Create the map's plugin-owned background and marker views for this menu instance.
function ModalChoiceMenu:BeginVisuals()
    self.backgroundView = BackgroundView.New(self.session.content)
    self.iconView = ButtonIcon.New(self.backgroundView.layer)
end

-- Fit the cropped map into the native window's available space.
function ModalChoiceMenu:CalculateLayout()
    local session = self.session
    local crop = geometry.Bounds(session.menu.background)
    local parent = session.window.parent
    local scale = math.min(constants.maxWidth / crop.width,
        (parent.width - session.left - session.right - 16) / crop.width,
        (parent.height - session.top - session.bottom - 16) / crop.height)
    return {width = math.max(1, math.floor(crop.width * scale)), height = math.max(1, math.floor(crop.height * scale))}
end

-- Apply a global rectangle in a native control's parent coordinate space.
local function setRect(control, x, y, width, height)
    local parentPosition = control.parent.xyGlobal
    control:SetPos(math.floor(x - parentPosition.x), math.floor(y - parentPosition.y))
    control:SetSize(width, height)
end

-- Resize the native window and clipping containers for either maps or custom menu layouts.
function ModalChoiceMenu:LayoutWindow(width, height)
    local session = self.session
    self:UpdateTitle()
    local window, content = session.window, session.content
    local parent = window.parent
    local windowWidth, windowHeight = width + session.left + session.right, height + session.top + session.bottom
    window:SetSize(windowWidth, windowHeight)
    window:SetPos(
        math.max(8, math.min(math.floor(session.centerX - windowWidth / 2), parent.width - windowWidth - 8)),
        math.max(8, math.min(math.floor(session.centerY - windowHeight / 2), parent.height - windowHeight - 8)))
    local origin = window.xyGlobal
    setRect(content, origin.x + session.left, origin.y + session.top, width, height)
    for _, frame in ipairs(session.frame) do
        setRect(frame.control,
            origin.x + frame.left, origin.y + frame.top,
            math.max(1, windowWidth - frame.left - frame.right),
            math.max(1, windowHeight - frame.top - frame.bottom))
    end
    local close = session.close
    if close ~= nil then
        setRect(close.control, origin.x + windowWidth - close.width - close.right,
            origin.y + close.top, close.width, close.height)
    end
    local title = session.title
    if title ~= nil then
        setRect(title.control, origin.x + title.left, origin.y + title.top,
            math.max(1, windowWidth - title.left - title.right), title.height)
    end
    -- Expand intermediate clipping containers before moving their individual rows.
    local expanded = {}
    for _, entry in ipairs(session.rows) do
        local ancestors, ancestor = {}, entry.row.parent
        while ancestor ~= nil and ancestor ~= window do
            ancestors[#ancestors + 1] = ancestor
            ancestor = ancestor.parent
        end
        for index = #ancestors, 1, -1 do
            local control = ancestors[index]
            if control ~= content and not expanded[control] then
                setRect(control, origin.x + session.left, origin.y + session.top, width, height)
                control.clickthrough = true
                expanded[control] = true
            end
        end
    end
end

-- Suppress native child artwork without hiding controls from matching or input.
function ModalChoiceMenu:HideRowArtwork(entry)
    components.Walk(entry.row, function(control)
        control.alpha = 0
    end)
end

-- Position a native row and its input hierarchy without replacing its actions or hooks.
function ModalChoiceMenu:LayoutRow(entry, x, y, width, height)
    setRect(entry.row, x, y, width, height)
    entry.row.alpha = 0
    entry.row.clickthrough = true
    local chain, control = {}, entry.click
    while control ~= entry.row do
        chain[#chain + 1] = control
        control = control.parent
    end
    for index = #chain, 1, -1 do
        control = chain[index]
        control:SetPos(0, 0)
        control:SetSize(width, height)
        control.clickthrough = control ~= entry.click
    end
end

-- Align original click targets with the map's destination markers.
function ModalChoiceMenu:ApplyLayout(layout)
    local session = self.session
    local width, height = layout.width, layout.height
    self.backgroundView:Show(session.menu.background, width, height, self.definition.vignette)
    self:LayoutWindow(width, height)
    local imagePosition = self.backgroundView.layer.xyGlobal
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

        self:LayoutRow(entry, imagePosition.x + x, imagePosition.y + y, hitWidth, hitHeight)
    end
end

-- Return the hovered native destination only when its map point is visible.
function ModalChoiceMenu:GetHovered()
    local menu = self.session.menu
    for _, entry in ipairs(menu.rows) do
        local destination = entry.destination
        if not entry.locked and not destination.hidden and entry.click.visibleGlobal and entry.click.isMouseOver
            and geometry.Contains(menu.background, destination.point) then return entry.name end
    end
end

-- Refresh icon states and show only the hovered destination's tooltip.
function ModalChoiceMenu:UpdateVisuals(layout, hovered)
    self.iconView:Update(self.session.menu, hovered)
    self:UpdateTooltips(hovered)
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

-- Destroy this menu's artwork even if the native interface has already closed.
function ModalChoiceMenu:ReleaseVisuals()
    if self.iconView ~= nil then pcall(function() self.iconView:Destroy() end) end
    if self.backgroundView ~= nil then pcall(function() self.backgroundView:Destroy() end) end
    self.iconView, self.backgroundView = nil, nil
end

-- Remove plugin hooks without restoring native positions, sizes, alpha or headings.
function ModalChoiceMenu:ReleaseInterface()
    if self.session == nil then return end
    for _, tooltip in pairs(self.session.tooltips or {}) do pcall(function() tooltip:Destroy() end) end
    for parent in pairs(self.session.tooltipContexts or {}) do
        pcall(function() prettyui.Tooltip.unregisterContext(parent) end)
    end
    if self.session.tooltipLayer ~= nil then
        pcall(function() self.session.tooltipLayer:Destroy() end)
        self.session.tooltipLayer = nil
    end
end

return ModalChoiceMenu
