local matcher = require("impl/destination_matcher")
local settings = require("definitions/constants")
local TeleportMenu = {}
TeleportMenu.__index = TeleportMenu

-- Create a subclass with inherited methods and an optional stable menu key.
function TeleportMenu:Extend(key)
    local class = {key = key}
    class.__index = class
    return setmetatable(class, {__index = self})
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

-- Let interface subclasses impose their own artwork and placement requirements.
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
    return self.session ~= nil and matcher.SameSnapshot(self.session.menu.snapshot, snapshot)
end

-- Read availability from the normalized native option unless an interface overrides it.
function TeleportMenu:IsDisabled(row)
    return row.native.disabled == true
end

-- Refresh availability independently from cached definitions and display callbacks.
function TeleportMenu:RefreshAvailability(snapshot)
    for index, row in ipairs(self.session.menu.rows) do
        if snapshot ~= nil and not row.locked then row.native = snapshot.nativeRows[index] end
        row.disabled = row.locked == true or self:IsDisabled(row)
    end
end

-- Resolve the winner and establish its native and plugin-owned session resources.
function TeleportMenu:Begin(menu, transition)
    self.session = {menu = matcher.Resolve(menu)}
    self:RefreshAvailability()
    self:BeginInterface(transition)
    self:BeginVisuals()
end

-- Apply layout before querying hover so hit testing uses the current control positions.
function TeleportMenu:Update(snapshot)
    self:RefreshAvailability(snapshot)
    local layout = self:CalculateLayout()
    self:ApplyLayout(layout)
    self:UpdateVisuals(layout, self:GetHovered())
end

-- Release both resource categories even when the client has already destroyed native controls.
function TeleportMenu:Release()
    pcall(function() self:ReleaseVisuals() end)
    pcall(function() self:ReleaseInterface() end)
    self.session = nil
end

-- Supply optional lifecycle hooks for interfaces that retain native artwork.
function TeleportMenu:BeginInterface() end
function TeleportMenu:BeginVisuals() end
function TeleportMenu:UpdateVisuals(layout, hovered) end
function TeleportMenu:ReleaseVisuals() end
function TeleportMenu:ReleaseInterface() end
function TeleportMenu:GetHovered() return nil end

-- Let interfaces carry lightweight layout state between related menu sessions.
function TeleportMenu:GetTransitionState(nextMenu, match) return nil end

-- Require interface classes to discover their native controls.
function TeleportMenu:ReadInterface()
    error("Teleport interface must implement ReadInterface")
end

-- Require interface classes to calculate their content layout.
function TeleportMenu:CalculateLayout()
    error("Teleport interface must implement CalculateLayout")
end

-- Require interface classes to apply positions to native controls.
function TeleportMenu:ApplyLayout(layout)
    error("Teleport interface must implement ApplyLayout")
end

-- Deduplicate matching diagnostics per interface rather than per candidate menu.
function TeleportMenu:ReportMatch(lines)
    if not settings.debugMatching or lines == nil then
        self.lastMatchReport = nil
        return
    end
    local message = table.concat(lines, "\n")
    if message ~= self.lastMatchReport then
        print("[Teleport Maps matching] " .. self.interfaceName .. "\n" .. message)
        self.lastMatchReport = message
    end
end

return TeleportMenu
