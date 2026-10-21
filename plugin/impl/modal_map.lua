-- Repositions native MODAL_CHOICE controls; their ops and hooks stay untouched.
local modalMap = {}
local teleportTooltip = require("impl/teleport_tooltip")
local mapGeometry = require("impl/map_geometry")
local settings = require("definitions/constants")
local session
local lastMatchReport

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

local function component(name)
    local componentID = id.Component["MODAL_CHOICE__" .. name]
    return componentID and ui.Interfaces:GetComponent(componentID) or nil
end

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

local function remember(control)
    if session.saved[control] == nil then
        local snapshot = {
            control = control,
            position = ui.Pos.new(control.position),
            size = ui.Size.new(control.size),
            alpha = control.alpha,
            clickthrough = control.clickthrough,
            staticID = control.staticID,
            categoryID = control.categoryID,
            dynamicID = control.dynamicID,
        }

        session.saved[control] = snapshot
        session.order[#session.order + 1] = snapshot
    end
end

local function currentControl(snapshot)
    if snapshot.categoryID >= 0 and snapshot.dynamicID >= 0 then
        return ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, snapshot.staticID,
            snapshot.categoryID, snapshot.dynamicID)
    end

    return ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, snapshot.staticID)
end

local function updateVisibleTitle()
    if #session.titles > 0 then
        local valid = true

        for _, snapshot in ipairs(session.titles) do
            local control = currentControl(snapshot)
            if control ~= snapshot.control then
                valid = false
                break
            end

            if snapshot.originalHeader ~= nil then
                control.headerText.content = session.headerText
            else
                control.content = session.headerText
            end
        end
        if valid then return end
        session.titles = {}
    end

    local visited = {}
    local function inspect(control)
        local key = table.concat({control.staticID, control.categoryID, control.dynamicID}, ":")
        if visited[key] or control.interfaceID ~= id.Interface.MODAL_CHOICE then return false end
        visited[key] = true

        local header = control.type == ui.ComponentType.GROUP_BOX
        if control.type == ui.ComponentType.LABEL or header then
            local text = header and control.headerText.content or control.content
            if text ~= nil and text ~= "" and control.visibleGlobal then
                local normalized = 
                    text
                    :gsub("<[^>]*>", "")
                    :gsub("%s+", " ")
                    :gsub("^%s+", "")
                    :gsub("%s+$", ""):upper()

                local snapshot = session.saved[control]
                local previouslyMatched = snapshot and snapshot.visibleTitle

                if normalized:match("^SELECT AN OPTION[%.:!]?$") or previouslyMatched then
                    remember(control)
                    snapshot = session.saved[control]
                    snapshot.visibleTitle = true

                    if header then
                        if snapshot.originalHeader == nil then snapshot.originalHeader = text end
                        snapshot.replacementHeader = session.headerText
                        control.headerText.content = session.headerText
                    else
                        if snapshot.originalContent == nil then snapshot.originalContent = text end
                        snapshot.replacementContent = session.headerText
                        control.content = session.headerText
                    end
                    session.titles[#session.titles + 1] = snapshot
                end
            end
        end

        if collectionTypes[control.type] then
            control:IterateStaticComponents(inspect)
            control:IterateDynamicComponents(inspect)
        end

        return false
    end

    -- This interface has static IDs 0..45; some header labels are created
    -- dynamically under them rather than living in the named TITLE component.
    for staticID = 0, 45 do
        local control = ui.Interfaces:GetComponent(id.Interface.MODAL_CHOICE, staticID)
        if control ~= nil then inspect(control) end
    end
end

function modalMap.Restore()
    if session == nil then
        return
    end

    for _, tooltip in pairs(session.tooltips) do
        pcall(function() tooltip:Destroy() end)
    end

    for parent in pairs(session.tooltipContexts) do
        pcall(function() prettyui.Tooltip.unregisterContext(parent) end)
    end

    -- A closed interface may already have destroyed its controls. Never restore
    -- saved state onto a new instance that happens to reuse the same IDs.
    for _, snapshot in ipairs(session.order) do
        pcall(
            function()
                local control = currentControl(snapshot)
                if control == snapshot.control then
                    control.position = snapshot.position
                    control.size = snapshot.size
                    control.alpha = snapshot.alpha
                    control.clickthrough = snapshot.clickthrough
                    if snapshot.originalContent ~= nil and control.content == snapshot.replacementContent then
                        control.content = snapshot.originalContent
                    end
                    if snapshot.originalHeader ~= nil and control.headerText.content == snapshot.replacementHeader then
                        control.headerText.content = snapshot.originalHeader
                    end
                end
            end
        )
    end

    session = nil
end

local function matchGroup(nativeRows, group)
    if type(group) ~= "table" or type(group.entries) ~= "table" then
        return nil, "missing entries table"
    end

    local rows, destinations = {}, {}
    local background, defaultDestination
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

        -- Match the whole visible menu against one group, not a global name index.
        if name == nil then
            return nil, "OPTION_" .. native.index .. " has no configured entry for " .. labelSummary(native.labels)
        end

        if type(group.entries[name]) ~= "table" then
            return nil, string.format("entry %q must be a table", name)
        end

        local destination = {}
        for key, value in pairs(group.entries[name]) do 
            destination[key] = value 
        end

        destination.background = destination.background or group.background
        destination.icons = destination.icons or group.icons

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
            defaultDestination = defaultDestination or name
        end

        destinations[name] = destination
        rows[#rows + 1] = {
            name = name, row = native.row, click = native.click,
            nameOverride = destination.nameOverride, description = destination.description,
            disabled = not native.click.visibleGlobal or isDisabled(native.click),
            background = destination.background, point = destination.point,
            hidden = hidden,
        }
    end

    if defaultDestination == nil then 
        return nil, "no non-hidden destinations matched"
    end

    local unusedEntries = 0
    for name in pairs(group.entries) do
        if destinations[name] == nil then 
            unusedEntries = unusedEntries + 1
        end
    end

    return {
        group = group, 
        title = group.title or "Select a destination", 
        rows = rows,
        destinations = destinations, 
        background = background, 
        defaultDestination = defaultDestination,
        matchCount = #rows, 
        unusedEntries = unusedEntries
    }
end

function modalMap.ReadRows(readLabels, groups)
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
            readLabels(row, labels, {})
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

    local menu, selectedGroupName
    local groupNames, failures, matches = {}, {}, {}
    for name in pairs(groups) do 
        groupNames[#groupNames + 1] = name
    end
    table.sort(groupNames)
    
    for _, name in ipairs(groupNames) do
        local candidate, reason = matchGroup(nativeRows, groups[name])
        if candidate ~= nil then
            if menu == nil or candidate.matchCount > menu.matchCount
                or (candidate.matchCount == menu.matchCount and candidate.unusedEntries < menu.unusedEntries) then
                menu, selectedGroupName = candidate, name
            end
            matches[#matches + 1] = name .. " (" .. candidate.matchCount .. " matches, " ..
                candidate.unusedEntries .. " unused entries)"
        elseif settings.debugMatching then
            failures[#failures + 1] = "  " .. name .. ": " .. reason
        end
    end

    if menu ~= nil then
        menu.window, menu.content = window, content
        if #matches > 1 then
            reportMatch({"Selected " .. selectedGroupName .. " by match count, then fewest unused entries.",
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

function modalMap.Matches(menu)
    if session == nil or session.window ~= menu.window or session.content ~= menu.content
        or session.group ~= menu.group or session.headerText ~= menu.title
        or #session.rows ~= #menu.rows then
        return false
    end

    for index, row in ipairs(menu.rows) do
        local previous = session.rows[index]
        if previous.name ~= row.name or previous.row ~= row.row or previous.click ~= row.click
            or previous.nameOverride ~= row.nameOverride or previous.description ~= row.description
            or previous.hidden ~= row.hidden 
        then
            return false
        end
    end

    return true
end

function modalMap.Begin(menu)
    assert(session == nil, "Restore the previous modal before attaching a new map")
    local window, content = menu.window, menu.content
    local windowPos, contentPos = window.xyGlobal, content.xyGlobal
    local left = math.max(padding, contentPos.x - windowPos.x)
    local top = math.max(32, contentPos.y - windowPos.y)

    session = {
        window = window,
        content = content,
        rows = menu.rows,
        group = menu.group,
        saved = {},
        order = {},
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

    remember(window)
    remember(content)

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
        remember(close)
    end

    local title = component("TITLE")
    if title ~= nil and title.type == ui.ComponentType.LABEL then
        remember(title)
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
    for _, entry in ipairs(menu.rows) do
        if not entry.hidden then
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
                entry.nameOverride or entry.name:gsub("^%d+%.%s*", ""), 
                entry.description
            )
        end
    end
end

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

local function setRect(control, x, y, width, height)
    remember(control)
    local parentPosition = control.parent.xyGlobal

    control:SetPos(math.floor(x - parentPosition.x), math.floor(y - parentPosition.y))
    control:SetSize(width, height)
end

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

function modalMap.Layout(width, height, imageHost, destinations)
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
        if control ~= nil then setRect(control, origin.x, origin.y, windowWidth, windowHeight) end
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
        local destination = destinations[entry.name]
        local background, point = destination.background, destination.point
        local size, x, y = 0, nil, nil
        if not entry.hidden then
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
        local control = entry.click
        while control ~= entry.row do
            chain[#chain + 1] = control
            control = control.parent
        end
        
        for index = #chain, 1, -1 do
            control = chain[index]
            remember(control)
            control:SetPos(0, 0)
            control:SetSize(size, size)
            control.clickthrough = control ~= entry.click
        end
    end
end

function modalMap.Hovered(menu)
    for _, entry in ipairs(menu.rows) do
        if not entry.hidden and entry.click.visibleGlobal and entry.click.isMouseOver
            and mapGeometry.Contains(entry.background, entry.point) then
            return entry.name
        end
    end
end

return modalMap
