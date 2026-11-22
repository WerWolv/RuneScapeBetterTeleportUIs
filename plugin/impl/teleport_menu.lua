local matcher = require("impl/destination_matcher")
local settings = require("definitions/constants")
local log = require("impl/log")
local cleanup = require("impl/cleanup")

local TeleportMenu = {}
TeleportMenu.__index = TeleportMenu

-- Create a subclass with inherited methods and an optional stable menu key.
function TeleportMenu:Extend(key)
    local class = { key = key }
    class.__index = class

    return setmetatable(class, { __index = self })
end

-- Construct a concrete menu with independent definitions and session state.
function TeleportMenu:New()
    local instance = setmetatable({}, self)
    instance.definition = instance:Define()

    return instance
end

-- Require concrete menus to supply their configuration.
function TeleportMenu:Define()
    error("Teleport menu must implement Define")
end

-- Let presentations impose their own artwork and placement requirements.
function TeleportMenu:ValidateDestination(definition, background)
    return true
end

-- Match this menu without resolving callbacks or changing the native interface.
function TeleportMenu:Match(snapshot)
    return matcher.Match(snapshot, self.definition, function(definition, background)
        return self:ValidateDestination(definition, background)
    end)
end

-- Reuse the active session only while its native controls and labels are unchanged.
function TeleportMenu:Matches(snapshot)
    return self.session ~= nil
        and (self.session.menu.snapshot == snapshot or matcher.SameSnapshot(self.session.menu.snapshot, snapshot))
end

local function componentIdentity(control)
    return {
        interfaceID = control.interfaceID,
        staticID = control.staticID,
        categoryID = control.categoryID,
        dynamicID = control.dynamicID,
    }
end

local function currentComponent(identity)
    if identity.categoryID >= 0 and identity.dynamicID >= 0 then
        return ui.Interfaces:GetComponent(
            identity.interfaceID, identity.staticID, identity.categoryID, identity.dynamicID
        )
    end

    return ui.Interfaces:GetComponent(identity.interfaceID, identity.staticID)
end

-- Destination lists are fixed for an opening. Check only native host identities
-- until closure/replacement, leaving interactive state to the menu's Update path.
function TeleportMenu:GetSnapshot()
    -- Choice dialogs can transition between picker pages without replacing their
    -- host. Fixed-list adapters opt in; page-driven dialogs keep live discovery.
    if not self.cacheNativeSnapshot then
        return self:ReadInterface()
    end

    local cached = rawget(self, "interfaceSnapshot")

    if cached ~= nil then
        local window = currentComponent(cached.window)

        if window ~= nil and window == cached.snapshot.window and window.visibleGlobal
            and window.parent == cached.parent and currentComponent(cached.content) == cached.snapshot.content then
            return cached.snapshot
        end

        self:InvalidateSnapshot()
    end

    local snapshot = self:ReadInterface()

    if snapshot ~= nil then
        self.interfaceSnapshot = {
            snapshot = snapshot,
            window = componentIdentity(snapshot.window),
            content = componentIdentity(snapshot.content),
            parent = snapshot.window.parent,
        }
    end

    return snapshot
end

function TeleportMenu:InvalidateSnapshot()
    self.interfaceSnapshot = nil
end

-- Read availability from the normalized native option unless an interface overrides it.
function TeleportMenu:IsDisabled(row)
    return row.native.disabled == true
end

-- Display labels omit native shortcuts and trailing sentence punctuation.
function TeleportMenu:GetDisplayName(row)
    if row.destination.nameOverride ~= nil then
        return row.destination.nameOverride
    end

    local name = row.name

    -- Missing options have only their pattern key, not a matched native label.
    if row.locked and name:sub(1, 1) == "^" then
        local shortcutEnd = name:find("%.", 1, true)

        if shortcutEnd ~= nil then
            name = name:sub(shortcutEnd + 2):gsub("^%s*", "")
            name = name:gsub("%%%..*$", ""):gsub("%$$", "")
        end
    end

    return (name:gsub("^%d+%.%s*", ""):gsub("%.$", ""))
end

function TeleportMenu:GetDescription(row)
    if (row.disabled or row.locked) and row.destination.disabledDescription ~= nil then
        return row.destination.disabledDescription
    end
    return row.destination.description
end

-- Highlight keys are independent of native translations, shortcuts and display overrides.
function TeleportMenu:GetHighlightKey(row)
    return row.destination.highlightKey or row.entryKey
end

function TeleportMenu:GetHighlightTargets()
    local targets = {}

    for _, row in ipairs(self.session.menu.rows) do
        if not row.destination.hidden then
            targets[#targets + 1] = {
                key = self:GetHighlightKey(row),
                name = self:GetDisplayName(row),
                disabled = row.disabled == true or row.locked == true,
            }
        end
    end

    return targets
end

function TeleportMenu:MatchesHighlightKey(row, key)
    return self:GetHighlightKey(row) == key
end

function TeleportMenu:FindHighlightTarget(key)
    local found

    for _, row in ipairs(self.session.menu.rows) do
        if not row.destination.hidden and self:MatchesHighlightKey(row, key) then
            if found ~= nil then
                return nil, "Button key is ambiguous"
            end
            found = row
        end
    end

    if found == nil then
        return nil, "Button is not visible in this menu"
    end

    return found
end

-- Ownership is shared; presentations override Begin/End/UpdateHighlight and may
-- set exclusiveHighlights = true when their UI can only represent one request.
function TeleportMenu:CreateHighlight(key)
    local session = self.session
    if session == nil or session.releasingHighlights then
        return nil, "Presentation is not showing"
    end

    session.highlights = session.highlights or {}
    if self.exclusiveHighlights and (session.creatingHighlight or next(session.highlights) ~= nil) then
        return nil, "Interface already has an active highlight"
    end

    session.creatingHighlight = true
    local ok, state, reason = pcall(self.BeginHighlight, self, key)
    session.creatingHighlight = nil
    if not ok then
        error(state, 0)
    end
    if state == nil then
        return nil, reason
    end

    if self.session ~= session or session.releasingHighlights then
        cleanup.Try("release interrupted highlight for " .. tostring(self.key), function()
            self:EndHighlight(state)
        end)
        return nil, "Presentation is not showing"
    end

    local handle = {}
    local release = function()
        local released = cleanup.Try("release highlight for " .. tostring(self.key), function()
            self:EndHighlight(state)
        end)
        session.highlights[handle] = nil
        return released
    end

    function handle.Release()
        local callback = release
        release = nil

        return callback == nil or callback()
    end

    session.highlights[handle] = state
    return handle
end

function TeleportMenu:ClearHighlights()
    if self.session ~= nil then
        self.session.releasingHighlights = true
        for handle in pairs(self.session.highlights or {}) do
            handle:Release()
        end
    end
end

function TeleportMenu:BeginHighlight(key)
    return nil, "Presentation does not support highlighting"
end

function TeleportMenu:EndHighlight(state)
    cleanup.Release(state, "highlightVisual")
end

function TeleportMenu:UpdateHighlight(state, layout)
end

function TeleportMenu:UpdateHighlights(layout)
    for _, state in pairs(self.session.highlights or {}) do
        self:UpdateHighlight(state, layout)
    end
end

-- Refresh availability independently from cached definitions and display callbacks.
function TeleportMenu:RefreshAvailability(snapshot)
    for index, row in ipairs(self.session.menu.rows) do
        if snapshot ~= nil and not row.locked then
            row.native = snapshot.nativeRows[index]
        end

        row.disabled = row.locked == true or self:IsDisabled(row)
    end
end

-- Resolve the winner and establish its native and plugin-owned session resources.
function TeleportMenu:Begin(menu, transition)
    self.session = { menu = matcher.Resolve(menu) }

    self:RefreshAvailability()
    -- Native hosts may detach after discovery but before attachment.
    if self:BeginInterface(transition) == false then
        self.session = nil
        return false
    end
    self:BeginVisuals()
end

-- Apply layout before querying hover so hit testing uses the current control positions.
function TeleportMenu:Update(snapshot)
    self:RefreshAvailability(snapshot)

    local layout = self:CalculateLayout()

    self:ApplyLayout(layout)
    self:UpdateVisuals(layout, self:GetHovered())
    self:UpdateHighlights(layout)
end

-- Release both resource categories even when the client has already destroyed native controls.
function TeleportMenu:Release()
    cleanup.Try("clear highlights for " .. tostring(self.key), function()
        self:ClearHighlights()
    end)
    cleanup.Try("release visuals for " .. tostring(self.key), function()
        self:ReleaseVisuals()
    end)

    cleanup.Try("restore interface for " .. tostring(self.key), function()
        self:ReleaseInterface()
    end)

    self.session = nil
end

-- Supply optional lifecycle hooks for interfaces that retain native artwork.
function TeleportMenu:BeginInterface()
end

function TeleportMenu:BeginVisuals()
end

function TeleportMenu:UpdateVisuals(layout, hovered)
end

function TeleportMenu:ReleaseVisuals()
end

function TeleportMenu:ReleaseInterface()
end

function TeleportMenu:GetHovered()
    return nil
end

-- Let interfaces carry lightweight layout state between related menu sessions.
function TeleportMenu:GetTransitionState(nextMenu, match)
    return nil
end

-- Require interface classes to discover their native controls.
function TeleportMenu:ReadInterface()
    error("Teleport interface must implement ReadInterface")
end

-- Require presentations to calculate their content layout.
function TeleportMenu:CalculateLayout()
    error("Teleport interface must implement CalculateLayout")
end

-- Presentations render artwork and submit target rectangles to their native adapter.
function TeleportMenu:ApplyLayout(layout)
    error("Teleport interface must implement ApplyLayout")
end

-- Include the interface in each diagnostic so distinct interfaces remain distinguishable.
function TeleportMenu:ReportMatch(lines)
    if not settings.debugMatching or lines == nil then
        return
    end

    log.Once("[Teleport Maps matching] " .. self.interfaceName .. "\n" .. table.concat(lines, "\n"))
end

return TeleportMenu
