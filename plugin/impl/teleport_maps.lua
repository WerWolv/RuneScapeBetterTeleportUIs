local registry = require("menus/registry")
local matcher = require("impl/destination_matcher")
local settings = require("definitions/constants")
local userSettings = require("impl/settings")
local MenuUIToggle = require("impl/ui/menu_ui_toggle")
local log = require("impl/log")
local cleanup = require("impl/cleanup")

local teleportMaps = {}
local interfaces

-- Release the selected menu's resources before switching or closing interfaces.
local function releaseActive(entry)
    cleanup.Release(entry, "active", "Release")
end

local function releaseToggle(entry)
    cleanup.Release(entry, "toggle")
end

local function releaseInterface(entry)
    releaseActive(entry)
    cleanup.Release(entry, "originalActive", "Release")
    releaseToggle(entry)
end

-- Some interfaces retain an enhanced native view when their map is toggled off.
local function updateOriginal(entry, winner)
    if winner.CreateOriginalMenu == nil then
        return
    end

    if entry.originalActive == nil then
        entry.originalActive = winner:CreateOriginalMenu()
    end

    local original = entry.originalActive
    local snapshot = original:GetSnapshot()

    if snapshot == nil then
        cleanup.Release(entry, "originalActive", "Release")
        return
    end

    if not original:Matches(snapshot) then
        if original.session ~= nil then
            original:Release()
        end

        local match = original:Match(snapshot)

        if match == nil or original:Begin(match) == false then
            return
        end
    end

    original:Update(snapshot)
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
                matches[#matches + 1] = menu.key .. " (" .. #snapshot.nativeRows .. " matches, "
                    .. candidate.unusedEntries .. " unused entries)"
            end
        elseif settings.debugMatching then
            failures[#failures + 1] = "  " .. menu.key .. ": " .. reason
        end
    end

    if winner ~= nil then
        if #matches > 1 then
            interface:ReportMatch({
                "Selected " .. winner.key .. " by fewest unused entries, then alphabetical menu key.",
                "Candidates: " .. table.concat(matches, ", ")
            })
        else
            interface:ReportMatch(nil)
        end
    elseif settings.debugMatching then
        local lines = {
            "Not matched: no menu matched every visible option.",
            "Current options (after removing formatting tags and outer whitespace):"
        }

        for _, row in ipairs(snapshot.nativeRows) do
            lines[#lines + 1] = "  OPTION_" .. row.index .. ": " .. matcher.LabelSummary(row.labels)
        end

        lines[#lines + 1] = "First rejection reason for each menu:"

        for _, failure in ipairs(failures) do
            lines[#lines + 1] = failure
        end

        interface:ReportMatch(lines)
    else
        interface:ReportMatch(nil)
    end

    -- Identify the best match before checking its toggle, so a disabled menu cannot
    -- fall back to a less-specific replacement sharing the same native interface.
    if winner ~= nil and not userSettings.Get(winner.enabledSetting) then
        return nil
    end

    return winner, match
end

-- Each native interface owns a session; one open interface must not starve another.
local function updateInterface(entry)
    -- Discovery can fail before a window is available to quarantine. Back off
    -- those reads as well, without blocking unrelated interfaces.
    if (entry.retryFrames or 0) > 0 then
        entry.retryFrames = entry.retryFrames - 1

        return
    end

    local snapshot

    local ok, message = pcall(function()
        if entry.active ~= nil and not userSettings.Get(entry.active.enabledSetting) then
            releaseInterface(entry)
        end

        -- Restore the list before map discovery/layout or disabling this interface.
        if entry.originalActive ~= nil and (entry.toggle == nil or not entry.toggle.original
            or not userSettings.Get(entry.originalActive.enabledSetting)) then
            cleanup.Release(entry, "originalActive", "Release")
        end

        snapshot = entry.interface:GetSnapshot()

        -- Retrying a failed layout every Draw can exhaust more IDs. Keep the
        -- restored native dialog until it closes or a different window replaces it.
        if entry.failedWindow ~= nil then
            if snapshot ~= nil and snapshot.window == entry.failedWindow then
                return
            end

            if snapshot == nil then
                local readable, visible = pcall(function()
                    return entry.failedWindow.visibleGlobal
                end)

                if readable and visible then
                    return
                end
            end

            entry.failedWindow = nil
        end

        local winner, match

        if snapshot ~= nil then
            winner, match = selectMenu(entry, snapshot)
        end

        if winner == nil then
            releaseInterface(entry)

            return
        end

        if entry.toggle ~= nil and (not winner.supportsOriginalUI or not entry.toggle:Matches(winner, snapshot)) then
            cleanup.Release(entry, "originalActive", "Release")
            releaseToggle(entry)
        end

        if winner.supportsOriginalUI and entry.toggle == nil then
            entry.toggle = MenuUIToggle:New(winner, snapshot)
        end

        if entry.toggle ~= nil and entry.toggle.original then
            releaseActive(entry)
            updateOriginal(entry, winner)
            entry.toggle:Update(snapshot)

            return
        end

        local active = entry.active

        if active ~= winner or active.session == nil or active.session.menu ~= match then
            local transition = active and active:GetTransitionState(winner, match)

            releaseActive(entry)
            entry.active = winner
            if winner:Begin(match, transition) == false then
                entry.active = nil

                return
            end
        end

        winner:Update(snapshot)

        if entry.toggle ~= nil then
            entry.toggle:Update(snapshot)
        end
    end)

    if not ok then
        if snapshot ~= nil then
            entry.failedWindow = snapshot.window
        else
            entry.retryDelay = math.min(600, (entry.retryDelay or 30) * 2)
            entry.retryFrames = entry.retryDelay
        end

        releaseInterface(entry)
        log.Once("Unable to embed teleport map: " .. tostring(message))
    else
        entry.retryDelay = nil
    end
end

local function draw()
    for _, entry in ipairs(interfaces) do
        updateInterface(entry)
    end
end

-- Instantiate each menu once and register only its declared interface.
function teleportMaps.Start()
    if interfaces ~= nil then
        return
    end

    local discovered = {}
    local byInterface, keys = {}, {}

    local function register(menu)
        local interface = assert(menu.interface, "Teleport menu must inherit an interface class")
        local entry = byInterface[interface]

        if entry == nil then
            entry = {
                interface = interface,
                menus = {},
            }
            byInterface[interface] = entry
            discovered[#discovered + 1] = entry
        end

        entry.menus[#entry.menus + 1] = menu
    end

    for _, class in ipairs(registry) do
        local ok, message = pcall(function()
            local menu = class:New()

            assert(type(menu.key) == "string", "Teleport menu key must be a string, got " .. tostring(menu.key))
            assert(not keys[menu.key], "Duplicate teleport menu key: " .. menu.key)
            assert(menu.interface, "Teleport menu must inherit an interface class")

            keys[menu.key] = true
            register(menu)
        end)

        if not ok then
            log.Once("Unable to initialize teleport menu " .. tostring(class.key) .. ": " .. tostring(message))
        end
    end

    for _, entry in ipairs(discovered) do
        table.sort(entry.menus, function(a, b)
            return a.key < b.key
        end)
    end

    interfaces = discovered
    Event.Draw.Subscribe("destinationPreview", draw)
end

-- Stop rendering and discard all menu instances and active session resources.
function teleportMaps.Stop()
    Event.Draw.Unsubscribe("destinationPreview")

    for _, entry in ipairs(interfaces or {}) do
        releaseInterface(entry)
        entry.interface:InvalidateSnapshot()
    end

    interfaces = nil
end

return teleportMaps
