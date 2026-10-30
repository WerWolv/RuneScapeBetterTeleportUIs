local registry = require("menus/registry")
local matcher = require("impl/destination_matcher")
local settings = require("definitions/constants")
local userSettings = require("impl/settings")
local teleportMaps = {}
local interfaces

-- Release the selected menu's resources before switching or closing interfaces.
local function releaseActive(entry)
    if entry.active ~= nil then entry.active:Release() end
    entry.active = nil
end

-- Rank read-only candidates and resolve only the winner for an interface snapshot.
local function selectMenu(entry, snapshot)
    local interface, menus, active = entry.interface, entry.menus, entry.active
    if active ~= nil and active.interface == interface and active:Matches(snapshot) then
        return active, active.session.menu
    end
    local winner, match
    local matches, failures = {}, {}
    for _, menu in ipairs(menus) do
        local candidate, reason = menu:Match(snapshot)
        if candidate ~= nil then
            if match == nil or candidate.unusedEntries < match.unusedEntries then
                winner, match = menu, candidate
            end
            if settings.debugMatching then
                matches[#matches + 1] = menu.key .. " (" .. #snapshot.nativeRows .. " matches, " .. candidate.unusedEntries .. " unused entries)"
            end
        elseif settings.debugMatching then
            failures[#failures + 1] = "  " .. menu.key .. ": " .. reason
        end
    end
    if winner ~= nil then
        if #matches > 1 then
            interface:ReportMatch({"Selected " .. winner.key .. " by fewest unused entries, then alphabetical menu key.",
                "Candidates: " .. table.concat(matches, ", ")})
        else
            interface:ReportMatch(nil)
        end
    elseif settings.debugMatching then
        local lines = {"Not matched: no menu matched every visible option.",
            "Current options (after removing formatting tags and outer whitespace):"}
        for _, row in ipairs(snapshot.nativeRows) do
            lines[#lines + 1] = "  OPTION_" .. row.index .. ": " .. matcher.LabelSummary(row.labels)
        end
        lines[#lines + 1] = "First rejection reason for each menu:"
        for _, failure in ipairs(failures) do lines[#lines + 1] = failure end
        interface:ReportMatch(lines)
    else
        interface:ReportMatch(nil)
    end
    -- Identify the best match before checking its toggle, so a disabled menu cannot
    -- fall back to a less-specific replacement sharing the same native interface.
    if winner ~= nil and not userSettings.Get(winner.enabledSetting) then return nil end
    return winner, match
end

-- Each native interface owns a session; one open interface must not starve another.
local function updateInterface(entry)
    local ok, message = pcall(function()
        if entry.active ~= nil and not userSettings.Get(entry.active.enabledSetting) then
            releaseActive(entry)
        end
        local snapshot = entry.interface:ReadInterface()
        local winner, match
        if snapshot ~= nil then winner, match = selectMenu(entry, snapshot) end
        if winner == nil then releaseActive(entry); return end
        local active = entry.active
        if active ~= winner or active.session == nil or active.session.menu ~= match then
            local transition = active and active:GetTransitionState(winner, match)
            releaseActive(entry)
            entry.active = winner
            winner:Begin(match, transition)
        end
        winner:Update(snapshot)
        entry.lastLayoutError = nil
    end)
    if not ok then
        releaseActive(entry)
        message = tostring(message)
        if message ~= entry.lastLayoutError then
            print("Unable to embed teleport map: " .. message)
            entry.lastLayoutError = message
        end
    end
end

local function draw()
    for _, entry in ipairs(interfaces) do updateInterface(entry) end
end

-- Instantiate concrete menus and group them by their inherited interface class.
function teleportMaps.Start()
    if interfaces ~= nil then return end
    local discovered = {}
    local byInterface, keys = {}, {}
    for _, class in ipairs(registry) do
        local menu = class:New()
        assert(type(menu.key) == "string", "Teleport menu key must be a string, got " .. tostring(menu.key))
        assert(not keys[menu.key], "Duplicate teleport menu key: " .. menu.key)
        keys[menu.key] = true
        local interface = assert(menu.interface, "Teleport menu must inherit an interface class")
        local entry = byInterface[interface]
        if entry == nil then
            entry = {interface = interface, menus = {}}
            byInterface[interface] = entry
            discovered[#discovered + 1] = entry
        end
        entry.menus[#entry.menus + 1] = menu
    end
    for _, entry in ipairs(discovered) do
        table.sort(entry.menus, function(a, b) return a.key < b.key end)
    end
    interfaces = discovered
    Event.Draw.Subscribe("destinationPreview", draw)
end

-- Stop rendering and discard all menu instances and active session resources.
function teleportMaps.Stop()
    Event.Draw.Unsubscribe("destinationPreview")
    for _, entry in ipairs(interfaces or {}) do releaseActive(entry) end
    interfaces = nil
end

return teleportMaps
