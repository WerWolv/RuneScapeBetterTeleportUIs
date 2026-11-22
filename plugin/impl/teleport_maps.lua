local registry = require("menus/registry")
local matcher = require("impl/destination_matcher")
local settings = require("definitions/constants")
local userSettings = require("impl/settings")
local MenuUIToggle = require("impl/ui/menu_ui_toggle")
local log = require("impl/log")
local cleanup = require("impl/cleanup")

local teleportMaps = {}
local interfaces
local menusByKey = {}
local detectionOrder = 0
local highlightRequests = {}

local function isVisible(entry)
    local ok, visible = pcall(function()
        return entry.detectedSnapshot.window.visibleGlobal
    end)

    return ok and visible
end

-- Release the selected menu's resources before switching or closing interfaces.
local function releaseActive(entry)
    entry.showing = false
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

    return winner, match
end

-- Recognition is independent of presentation settings and the original-UI toggle.
local function detected(entry, menu, snapshot)
    local previous = entry.detectedSnapshot
    if menu ~= nil and (entry.detectedMenu ~= menu or previous == nil
        or previous.window ~= snapshot.window or previous.content ~= snapshot.content) then
        detectionOrder = detectionOrder + 1
        entry.detectionOrder = detectionOrder
    end
    entry.detectedMenu = menu
    entry.detectedSnapshot = menu ~= nil and snapshot or nil
end

local function failInterface(entry, snapshot, message)
    detected(entry, nil)
    if snapshot ~= nil then
        entry.failedWindow = snapshot.window
    else
        entry.retryDelay = math.min(600, (entry.retryDelay or 30) * 2)
        entry.retryFrames = entry.retryDelay
    end

    releaseInterface(entry)
    log.Once("Unable to embed teleport map: " .. tostring(message))
end

-- Restore outgoing layouts before any replacement measures a shared native host.
local function prepareInterface(entry)
    entry.pending = nil

    -- Discovery can fail before a window is available to quarantine. Back off
    -- those reads as well, without blocking unrelated interfaces.
    if (entry.retryFrames or 0) > 0 then
        entry.retryFrames = entry.retryFrames - 1
        detected(entry, nil)

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
            detected(entry, nil)
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

        detected(entry, winner, snapshot)

        -- Keep the best match identifiable even while its presentation is disabled.
        -- It must not fall back to a less-specific enabled menu.
        if winner == nil or not userSettings.Get(winner.enabledSetting) then
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

        local active = entry.active
        local transition

        if entry.toggle ~= nil and entry.toggle.original then
            releaseActive(entry)
        elseif active ~= winner or active.session == nil or active.session.menu ~= match then
            transition = active and active:GetTransitionState(winner, match)
            releaseActive(entry)
        end

        entry.pending = {
            snapshot = snapshot,
            winner = winner,
            match = match,
            transition = transition,
        }
    end)

    if not ok then
        failInterface(entry, snapshot, message)
    else
        entry.retryDelay = nil
    end
end

-- Each native interface owns a session; one open interface must not starve another.
local function updateInterface(entry)
    local pending = entry.pending
    entry.pending = nil

    if pending == nil then
        return
    end

    local snapshot, winner = pending.snapshot, pending.winner
    local ok, message = pcall(function()
        if entry.toggle ~= nil and entry.toggle.original then
            updateOriginal(entry, winner)
        else
            if entry.active == nil then
                entry.active = winner
                if winner:Begin(pending.match, pending.transition) == false then
                    entry.active = nil

                    return
                end
            end

            winner:Update(snapshot)
            entry.showing = true
        end

        if entry.toggle ~= nil then
            entry.toggle:Update(snapshot)
        end
    end)

    if not ok then
        failInterface(entry, snapshot, message)
    end
end

-- Read the latest discovery without matching menus, rendering, or exposing mutable state.
function teleportMaps.GetStatus()
    local current
    for _, entry in ipairs(interfaces or {}) do
        if entry.detectedMenu ~= nil then
            -- A client window can close between our Draw callback and a consumer's query.
            if isVisible(entry) and (current == nil or entry.detectionOrder > current.detectionOrder) then
                current = entry
            end
        end
    end
    if current == nil then
        return nil, false
    end

    local menu = current.detectedMenu
    local enabled = current.showing == true and current.active == menu and menu.session ~= nil
        and userSettings.Get(menu.enabledSetting) and (current.toggle == nil or not current.toggle.original)
    return menu.key, not not enabled
end

-- Resolve the registered menu even when its presentation is not showing.
local function getHighlightPresentation(interfaceKey)
    if type(interfaceKey) ~= "string" then
        return nil, "Interface key must be a string"
    end

    local registered = menusByKey[interfaceKey]
    if registered == nil then
        return nil, "Interface is not registered"
    end

    local menu, entry = registered.menu, registered.entry
    if entry.detectedMenu ~= menu then
        return nil, "Interface is not open", menu
    end
    if not isVisible(entry) or not userSettings.Get(menu.enabledSetting) then
        return nil, "Interface is not showing", menu
    end

    local presentation
    if entry.toggle ~= nil and entry.toggle.original then
        presentation = entry.originalActive
    elseif entry.showing then
        presentation = entry.active
    end
    if presentation == nil or presentation.session == nil then
        return nil, "Presentation is not showing", menu
    end

    return presentation, nil, menu
end

local function withHighlightPresentation(interfaceKey, callback)
    local presentation, reason, menu = getHighlightPresentation(interfaceKey)

    local ok, result, failure = pcall(callback, presentation, reason, menu)
    if not ok then
        log.Once("Unable to process highlight request for " .. tostring(interfaceKey) .. ": " .. tostring(result))
        return nil, "Highlight request failed"
    end

    return result, failure
end

local function removeHighlightRequest(request)
    local requests = highlightRequests[request.interfaceKey]
    for index, existing in ipairs(requests or {}) do
        if existing == request then
            table.remove(requests, index)
            if #requests == 0 then
                highlightRequests[request.interfaceKey] = nil
            end
            return
        end
    end
end

local function releaseHighlightBinding(request)
    local active = request.active
    request.active, request.presentation, request.session = nil, nil, nil
    if active == nil then
        return true
    end

    local released
    local ok = cleanup.Try("release highlight binding for " .. request.interfaceKey, function()
        released = active:Release()
    end)
    return ok and released ~= false
end

-- Public ownership outlives native sessions; each opening gets its own visual handle.
local function newHighlightRequest(interfaceKey, buttonKey, exclusive)
    local request = {
        interfaceKey = interfaceKey,
        buttonKey = buttonKey,
        exclusive = exclusive,
        applying = true,
    }
    local handle = {}

    function handle.Release()
        if request.released then
            return true
        end

        request.released = true
        local released = releaseHighlightBinding(request)
        removeHighlightRequest(request)
        return released
    end

    request.handle = handle
    local requests = highlightRequests[interfaceKey] or {}
    highlightRequests[interfaceKey] = requests
    requests[#requests + 1] = request
    return request
end

local function applyHighlightRequest(request, presentation)
    if presentation ~= nil and presentation.exclusiveHighlights then
        request.exclusive = true
    end

    local session = presentation and presentation.session
    if request.active ~= nil and (request.presentation ~= presentation
        or session ~= request.session) then
        releaseHighlightBinding(request)
    end
    if presentation == nil or request.active ~= nil then
        return true
    end

    local handle, reason = presentation:CreateHighlight(request.buttonKey)
    if handle == nil then
        return nil, reason
    end
    if request.released or presentation.session ~= session then
        handle:Release()
    else
        request.active, request.presentation, request.session = handle, presentation, session
    end
    return true
end

function teleportMaps.CreateHighlight(interfaceKey, buttonKey)
    if type(buttonKey) ~= "string" and type(buttonKey) ~= "number" then
        return nil, "Button key must be a string or number"
    end

    local request
    local handle, reason = withHighlightPresentation(interfaceKey, function(presentation, failure, menu)
        if menu == nil then
            return nil, failure
        end

        local exclusive = menu.exclusiveHighlights or presentation ~= nil and presentation.exclusiveHighlights
        for _, existing in ipairs(highlightRequests[interfaceKey] or {}) do
            if exclusive or existing.exclusive then
                return nil, "Interface already has an active or pending highlight"
            end
        end

        request = newHighlightRequest(interfaceKey, buttonKey, exclusive)
        local applied, message = applyHighlightRequest(request, presentation)
        if not applied then
            return nil, message
        end

        return request.handle
    end)

    if request ~= nil then
        request.applying = false
        if handle == nil then
            request.handle:Release()
        end
    end

    return handle, reason
end

function teleportMaps.GetHighlightTargets(interfaceKey)
    return withHighlightPresentation(interfaceKey, function(presentation, reason)
        if presentation == nil then
            return nil, reason
        end

        return presentation:GetHighlightTargets()
    end)
end

local function updateHighlightRequests()
    -- Copy before invoking menu hooks: callbacks can create or release other requests.
    local current = {}
    for _, requests in pairs(highlightRequests) do
        for _, request in ipairs(requests) do
            current[#current + 1] = request
        end
    end

    for _, request in ipairs(current) do
        if not request.released and not request.applying then
            request.applying = true
            local applied, reason = withHighlightPresentation(request.interfaceKey, function(presentation)
                return applyHighlightRequest(request, presentation)
            end)
            request.applying = false
            if not applied and not request.released then
                log.Once("Unable to apply highlight for " .. request.interfaceKey
                    .. " (" .. tostring(request.buttonKey) .. "): " .. tostring(reason))
            end
        end
    end
end

local function draw()
    for _, entry in ipairs(interfaces) do
        prepareInterface(entry)
    end

    for _, entry in ipairs(interfaces) do
        updateInterface(entry)
    end
    -- Layout, native rows and search controls must exist before resolving queued keys.
    updateHighlightRequests()
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
        return entry
    end

    for _, class in ipairs(registry) do
        local ok, message = pcall(function()
            local menu = class:New()

            assert(type(menu.key) == "string", "Teleport menu key must be a string, got " .. tostring(menu.key))
            assert(not keys[menu.key], "Duplicate teleport menu key: " .. menu.key)
            assert(menu.interface, "Teleport menu must inherit an interface class")

            keys[menu.key] = { menu = menu, entry = register(menu) }
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
    menusByKey = keys
    Event.Draw.Subscribe("destinationPreview", draw)
end

-- Stop rendering and discard all menu instances and active session resources.
function teleportMaps.Stop()
    Event.Draw.Unsubscribe("destinationPreview")

    local previous = interfaces
    interfaces = nil
    menusByKey = {}
    for _, requests in pairs(highlightRequests) do
        while #requests > 0 do
            requests[1].handle:Release()
        end
    end
    for _, entry in ipairs(previous or {}) do
        releaseInterface(entry)
        entry.interface:InvalidateSnapshot()
    end

    detectionOrder = 0
end

return teleportMaps
