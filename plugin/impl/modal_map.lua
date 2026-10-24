-- Repositions native MODAL_CHOICE controls; their ops and hooks stay untouched.
local modalMap = {}
local teleportTooltip = require("impl/teleport_tooltip")
local mapGeometry = require("impl/map_geometry")
local utils = require("impl/utils")
local settings = require("definitions/constants")
local session
local knownTitles = setmetatable({}, {__mode = "k"})
local lastMatchReport

-- Print changed match diagnostics when debug matching is enabled.
local function reportMatch(lines)
    if not settings.debugMatching then
        lastMatchReport = nil
        return
    end
    local message = table.concat(lines, "\n")
    if message ~= lastMatchReport then
        print("[Teleport Maps matching] MODAL_CHOICE (" .. id.Interface.MODAL_CHOICE .. ")\n" .. message)
        lastMatchReport = message
    end
end

-- Format detected labels in a stable order for readable matching diagnostics.
local function labelSummary(labels)
    local names = {}
    for text in pairs(labels) do names[#names + 1] = string.format("%q", text) end
    table.sort(names)
    return #names > 0 and table.concat(names, ", ") or "<no visible text>"
end

local padding = 12
local hitboxScale = 0.75
local collectionTypes = {
    [ui.ComponentType.LAYER] = true,
    [ui.ComponentType.PANEL] = true,
    [ui.ComponentType.GRID] = true,
    [ui.ComponentType.PAGED_LAYER] = true,
    [ui.ComponentType.PAGED_CAROUSEL] = true,
    [ui.ComponentType.GROUP_BOX] = true,
}

-- Identify a static or dynamic UI component uniquely during tree traversal.
local function controlKey(control)
    return table.concat({control.interfaceID, control.staticID, control.categoryID, control.dynamicID}, ":")
end

-- Remove formatting tags and surrounding whitespace before matching option labels.
local function cleanText(text)
    return (text or ""):gsub("<[^>]*>", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Visit both static and dynamic children when a component supports collections.
local function visitChildren(control, callback)
    if collectionTypes[control.type] then
        control:IterateStaticComponents(callback)
        control:IterateDynamicComponents(callback)
    end
end

-- Gather visible label and button text without visiting the same component twice.
local function collectLabels(control, labels, visited)
    local key = controlKey(control)
    if visited[key] or not control.visibleGlobal then return false end
    visited[key] = true

    local text
    if control.type == ui.ComponentType.LABEL then
        text = control.content
    elseif control.type == ui.ComponentType.BUTTON then
        text = control.label
    end
    text = cleanText(text)
    if text ~= "" then labels[text] = true end

    visitChildren(control, function(child)
        return collectLabels(child, labels, visited)
    end)
    return false
end

-- Look up a named component belonging to MODAL_CHOICE.
local function component(name)
    local componentID = id.Component["MODAL_CHOICE__" .. name]
    return componentID and ui.Interfaces:GetComponent(componentID) or nil
end

-- Treat a native control as unavailable only when all its named actions are explicitly hidden.
local function isDisabled(control)
    local ok, disabled = pcall(
        function()
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
        end
    )

    return ok and disabled or false
end

-- Resolve a cached title's IDs against the currently loaded interface.
local function currentTitle(title)
    if title.categoryID >= 0 and title.dynamicID >= 0 then
        return ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, title.staticID,
            title.categoryID, title.dynamicID)
    end

    return ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, title.staticID)
end

-- Replace the modal title
local function updateVisibleTitle()
    if #session.titles > 0 then
        local valid = true

        for _, title in ipairs(session.titles) do
            local control = currentTitle(title)
            if control ~= title.control then
                valid = false
                break
            end

            if title.header then
                control.headerText.content = session.headerText
            else
                control.content = session.headerText
            end
        end
        if valid then return end
        session.titles = {}
    end

    local visited = {}
    -- Find generic headings in both labels and group-box header text.
    local function inspect(control)
        local key = controlKey(control)
        if visited[key] or control.interfaceID ~= id.Interface.MODAL_CHOICE then return false end
        visited[key] = true

        local header = control.type == ui.ComponentType.GROUP_BOX
        if control.type == ui.ComponentType.LABEL or header then
            local text = header and control.headerText.content or control.content
            if text ~= nil and text ~= "" and control.visibleGlobal then
                local normalized = cleanText(text):gsub("%s+", " "):upper()

                if normalized:match("^SELECT AN OPTION[%.:!]?$") or knownTitles[control] then
                    knownTitles[control] = true
                    if header then
                        control.headerText.content = session.headerText
                    else
                        control.content = session.headerText
                    end
                    session.titles[#session.titles + 1] = {
                        control = control, header = header, staticID = control.staticID,
                        categoryID = control.categoryID, dynamicID = control.dynamicID,
                    }
                end
            end
        end

        visitChildren(control, inspect)

        return false
    end

    -- Scan static IDs 0–45 and their dynamic children because the visible heading may not be TITLE.
    for staticID = 0, 45 do
        local control = ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, staticID)
        if control ~= nil then inspect(control) end
    end
end

-- Remove plugin tooltip hooks and discard the session without restoring native UI properties.
function modalMap.Release()
    if session == nil then
        return
    end

    for _, tooltip in pairs(session.tooltips) do
        pcall(function() tooltip:Destroy() end)
    end

    for parent in pairs(session.tooltipContexts) do
        pcall(function() prettyui.Tooltip.unregisterContext(parent) end)
    end

    session = nil
end

-- Resolve every visible row against a single teleport group and score the complete match.
local function matchGroup(nativeRows, group)
    if type(group) ~= "table" or type(group.entries) ~= "table" then
        return nil, "missing entries table"
    end

    local rows, matched = {}, {}
    local background
    for _, native in ipairs(nativeRows) do
        local name
        for text in pairs(native.labels) do
            if group.entries[text] ~= nil then
                if name ~= nil then
                    return nil, "OPTION_" .. native.index .. " matches multiple entries: " .. labelSummary(native.labels)
                end
                name = text
            end
        end

        -- Match the whole visible menu against one group
        if name == nil then
            return nil, "OPTION_" .. native.index .. " has no configured entry for " .. labelSummary(native.labels)
        end

        if type(group.entries[name]) ~= "table" then
            return nil, string.format("entry %q must be a table", name)
        end

        local definition = group.entries[name]
        local destination = {
            hidden = definition.hidden,
            point = definition.point,
            background = definition.background or group.background,
            icons = definition.icons or group.icons,
        }

        local hidden = destination.hidden == true
        if not hidden then
            if destination.point == nil or destination.icons == nil or destination.background == nil then
                local missing = {}
                if destination.point == nil then missing[#missing + 1] = "point" end
                if destination.icons == nil then missing[#missing + 1] = "icons (including group default)" end
                if destination.background == nil then missing[#missing + 1] = "background (including group default)" end
                return nil, string.format("entry %q is missing %s", name, table.concat(missing, ", "))
            end

            if background ~= nil and background ~= destination.background then
                return nil, string.format("entry %q uses a different background from the other visible entries", name)
            end

            background = destination.background
        end

        matched[name] = true
        rows[#rows + 1] = {
            name = name, row = native.row, click = native.click,
        }
    end

    if background == nil then
        return nil, "no non-hidden destinations matched"
    end

    local unusedEntries = 0
    for name in pairs(group.entries) do
        if not matched[name] then
            unusedEntries = unusedEntries + 1
        end
    end

    return {
        group = group, 
        title = group.title or "Select a destination", 
        rows = rows,
        background = background, 
        unusedEntries = unusedEntries
    }
end

-- Inspect native option rows and select the best fully matching teleport map definition
function modalMap.ReadRows(groups)
    local window = component("MODAL_DIALOG_WINDOW")
    local content = component("MODAL_DIALOG_WINDOW_CONTENT")
    if window == nil or not window.visibleGlobal then
        lastMatchReport = nil
        return nil
    end

    if content == nil then
        reportMatch({"Not matched: missing MODAL_DIALOG_WINDOW_CONTENT."})
        return nil
    end

    local nativeRows = {}
    for index = 1, 10 do
        local row = component("OPTION_" .. index)
        local click = component("OPTION_CLICK_" .. index)

        if row ~= nil and row.visibleGlobal and click == nil then
            reportMatch({"Not matched: visible OPTION_" .. index .. " has no OPTION_CLICK_" .. index .. "."})
            return nil
        end

        if row ~= nil and row.visibleGlobal and click ~= nil then
            local labels = {}
            collectLabels(row, labels, {})
            local ancestor = click

            while ancestor ~= nil and ancestor ~= row do 
                ancestor = ancestor.parent
            end

            if ancestor == nil then
                reportMatch({"Not matched: OPTION_CLICK_" .. index .. " is not a child of OPTION_" .. index .. "."})
                return nil
            end

            ancestor = row
            while ancestor ~= nil and ancestor ~= window do ancestor = ancestor.parent end
            if ancestor == nil then
                reportMatch({"Not matched: OPTION_" .. index .. " is outside MODAL_DIALOG_WINDOW."})
                return nil
            end

            nativeRows[#nativeRows + 1] = {
                row = row, 
                click = click, 
                labels = labels, 
                index = index
            }
        end
    end

    if #nativeRows == 0 then
        reportMatch({"Not matched: no visible option rows were found."})
        return nil
    end

    -- Reuse resolved definitions while the native controls and complete label sets stay unchanged.
    if session ~= nil and session.menu.groups == groups and session.window == window
        and session.content == content and #session.nativeRows == #nativeRows then
        local unchanged = true
        for index, native in ipairs(nativeRows) do
            local previous = session.nativeRows[index]
            if native.row ~= previous.row or native.click ~= previous.click or native.index ~= previous.index then
                unchanged = false
                break
            end
            for label in pairs(native.labels) do
                if not previous.labels[label] then unchanged = false end
            end
            for label in pairs(previous.labels) do
                if not native.labels[label] then unchanged = false end
            end
        end
        if unchanged then
            for _, row in ipairs(session.rows) do
                row.disabled = not row.click.visibleGlobal or isDisabled(row.click)
            end
            return session.menu
        end
    end

    local menu, selectedGroupName
    local groupNames, failures, matches = {}, {}, {}
    local candidateCount = 0
    for name in pairs(groups) do 
        groupNames[#groupNames + 1] = name
    end
    table.sort(groupNames)

    -- All candidates match every row, so prefer fewer unused entries and then alphabetical names.
    for _, name in ipairs(groupNames) do
        local candidate, reason = matchGroup(nativeRows, groups[name])
        if candidate ~= nil then
            candidateCount = candidateCount + 1
            if menu == nil or candidate.unusedEntries < menu.unusedEntries then
                menu, selectedGroupName = candidate, name
            end
            if settings.debugMatching then
                matches[#matches + 1] = name .. " (" .. #candidate.rows .. " matches, " ..
                    candidate.unusedEntries .. " unused entries)"
            end
        elseif settings.debugMatching then
            failures[#failures + 1] = "  " .. name .. ": " .. reason
        end
    end

    if menu ~= nil then
        menu.window, menu.content = window, content
        menu.groups, menu.nativeRows = groups, nativeRows
        -- Copy only the winner's per-entry data, retaining shared artwork and resource identities.
        for _, row in ipairs(menu.rows) do
            local definition = menu.group.entries[row.name]
            local data = {}
            for key, value in pairs(definition) do
                if key ~= "background" and key ~= "icons" then data[key] = value end
            end
            row.destination = utils.deepcopy(data)
            row.destination.hidden = definition.hidden == true
            row.destination.background = definition.background or menu.group.background
            row.destination.icons = definition.icons or menu.group.icons
            row.disabled = not row.click.visibleGlobal or isDisabled(row.click)
        end
        if candidateCount > 1 and settings.debugMatching then
            reportMatch({"Selected " .. selectedGroupName .. " by fewest unused entries, then alphabetical group name.",
                "Candidates: " .. table.concat(matches, ", ")})
        else
            lastMatchReport = nil
        end
        return menu
    end

    if settings.debugMatching then
        local lines = {"Not matched: no group matched every visible option."}
        lines[#lines + 1] = "Current options (after removing formatting tags and outer whitespace):"
        for _, row in ipairs(nativeRows) do
            lines[#lines + 1] = "  OPTION_" .. row.index .. ": " .. labelSummary(row.labels)
        end
        lines[#lines + 1] = "First rejection reason for each group:"
        for _, failure in ipairs(failures) do 
            lines[#lines + 1] = failure
        end

        reportMatch(lines)
    else
        lastMatchReport = nil
    end

    return nil
end

-- Check whether the mounted session can be reused for this menu and its tooltip data.
function modalMap.Matches(menu)
    return session ~= nil and session.menu == menu
end

-- Measure the modal's margins and attach cursor-following tooltips to its buttons.
function modalMap.Begin(menu)
    assert(session == nil, "Release the previous modal before attaching a new map")
    local window, content = menu.window, menu.content
    local windowPos, contentPos = window.xyGlobal, content.xyGlobal
    local left = math.max(padding, contentPos.x - windowPos.x)
    local top = math.max(32, contentPos.y - windowPos.y)

    session = {
        menu = menu,
        nativeRows = menu.nativeRows,
        window = window,
        content = content,
        rows = menu.rows,
        group = menu.group,
        titles = {},
        tooltips = {},
        tooltipContexts = {},
        headerText = menu.title,
        left = left,
        top = top,
        right = math.max(padding, window.width - left - content.width),
        bottom = math.max(padding, window.height - top - content.height),
        centerX = window.x + window.width / 2,
        centerY = window.y + window.height / 2,
    }

    local close = component("MODAL_DIALOG_WINDOW_CLOSE_BUTTON")

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

    local title = component("TITLE")
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

    local overlay = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP) or window.parent

    -- Convert native button positions to overlay coordinates so tooltips avoid clipping and scale offsets.
    for _, entry in ipairs(menu.rows) do
        if not entry.destination.hidden then
            local parent = entry.click.parent
            if not session.tooltipContexts[parent] then
                prettyui.Tooltip.registerContext(parent, overlay, function(target)
                    local targetPosition, overlayPosition = target.xyGlobal, overlay.xyGlobal
                    return targetPosition.x - overlayPosition.x, targetPosition.y - overlayPosition.y
                end)
                session.tooltipContexts[parent] = true
            end
            session.tooltips[entry.name] = teleportTooltip.Attach(
                entry.click, 
                parent,
                entry.destination.nameOverride or entry.name:gsub("^%d+%.%s*", ""),
                entry.destination.description
            )
        end
    end
end

-- Show only the hovered destination's tooltip and hide all others.
function modalMap.UpdateTooltip(name)
    if session == nil then return end
    for destination, tooltip in pairs(session.tooltips) do
        if destination == name then
            tooltip:Show()
        else
            tooltip:Hide()
        end
    end
end

-- Apply a global rectangle in the control's parent coordinate space.
local function setRect(control, x, y, width, height)
    local parentPosition = control.parent.xyGlobal

    control:SetPos(math.floor(x - parentPosition.x), math.floor(y - parentPosition.y))
    control:SetSize(width, height)
end

-- Fit the cropped map inside the available window space while retaining its aspect ratio.
function modalMap.Fit(background, maxWidth)
    local crop = mapGeometry.Bounds(background)
    local parent = session.window.parent
    local horizontalMargin = session.left + session.right
    local verticalMargin = session.top + session.bottom
    local scale = math.min(
        maxWidth / crop.width,
        (parent.width - horizontalMargin - 16) / crop.width,
        (parent.height - verticalMargin - 16) / crop.height
    )

    return 
        math.max(
            1, 
            math.floor(crop.width * scale)
        ),
        math.max(
            1, 
            math.floor(crop.height * scale)
        )
end

-- Resize the native modal and align its original click targets with the displayed map icons.
function modalMap.Layout(width, height, imageHost)
    updateVisibleTitle()

    local window, content = session.window, session.content
    local parent = window.parent
    local windowWidth = width + session.left + session.right
    local windowHeight = height + session.top + session.bottom

    window:SetSize(windowWidth, windowHeight)
    window:SetPos(
        math.max(8, math.min(math.floor(session.centerX - windowWidth / 2), parent.width - windowWidth - 8)),
        math.max(8, math.min(math.floor(session.centerY - windowHeight / 2), parent.height - windowHeight - 8)))

    local origin = window.xyGlobal
    setRect(content, origin.x + session.left, origin.y + session.top, width, height)

    for _, name in ipairs({"MODAL_DIALOG_WINDOW_BACKGROUND", "MODAL_DIALOG_WINDOW_BORDER"}) do
        local control = component(name)
        if control ~= nil then 
            setRect(control, origin.x, origin.y, windowWidth, windowHeight) 
        end
    end

    local close = session.close
    if close ~= nil then
        setRect(
            close.control, 
            origin.x + windowWidth - close.width - close.right,
            origin.y + close.top, 
            close.width, 
            close.height
        )
    end

    local title = session.title
    if title ~= nil then
        setRect(
            title.control, 
            origin.x + title.left, 
            origin.y + title.top,
            math.max(
                1, 
                windowWidth - title.left - title.right
            ), 
            title.height
        )
    end

    -- Expand intermediate clipping containers before moving individual rows.
    local expanded = {}
    for _, entry in ipairs(session.rows) do
        local ancestors = {}
        local ancestor = entry.row.parent
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

    local imagePosition = imageHost.xyGlobal
    for _, entry in ipairs(session.rows) do
        local destination = entry.destination
        local background, point = destination.background, destination.point
        local size, x, y = 0, nil, nil
        if not destination.hidden then
            size = math.max(1, math.floor((destination.icons.size or 48) * hitboxScale))
            x, y = mapGeometry.Project(background, point, width, height)
        end
        if x == nil then
            -- Keep the row discoverable, but remove its clickable area.
            x, y, size = 0, 0, 0
        else
            x, y = x - size / 2, y - size / 2
        end

        setRect(entry.row, imagePosition.x + x, imagePosition.y + y, size, size)
        entry.row.alpha = 0 -- Preserve visibility/input; suppress old row artwork/text.
        entry.row.clickthrough = true

        local chain = {}

        -- Resize the original input hierarchy
        local control = entry.click
        while control ~= entry.row do
            chain[#chain + 1] = control
            control = control.parent
        end
        
        for index = #chain, 1, -1 do
            control = chain[index]
            control:SetPos(0, 0)
            control:SetSize(size, size)
            control.clickthrough = control ~= entry.click
        end
    end
end

-- Return the hovered native destination only when its map point is visible and not hidden by configuration.
function modalMap.Hovered(menu)
    for _, entry in ipairs(menu.rows) do
        local destination = entry.destination
        if not destination.hidden and entry.click.visibleGlobal and entry.click.isMouseOver
            and mapGeometry.Contains(menu.background, destination.point) then
            return entry.name
        end
    end
end

return modalMap
