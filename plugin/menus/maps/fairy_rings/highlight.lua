local highlight = {}

local routeIDs = {
    DIRAKS = "kethsi",
    BIRDIPCLRALP = "rift",
    AIRDLRDJQAJS = "resistance",
}

local function destinationID(row)
    local code = table.concat(row.codes):upper()
    return routeIDs[code] or code
end

-- A multi-code route is one destination, not several unrelated ring targets.
function highlight.GetTargets(menu)
    local targets, seen = {}, {}
    for _, row in ipairs(menu.session.highlightRows or {}) do
        local key = destinationID(row)
        if key ~= "" and not seen[key] then
            seen[key] = true
            targets[#targets + 1] = { key = key, name = row.name or row.location, disabled = false }
        end
    end
    return targets
end

function highlight.Begin(menu, search, key)
    if search == nil then return nil, "Search is not showing" end
    local code
    for _, row in ipairs(menu.session.highlightRows or {}) do
        if destinationID(row) == key and key ~= "" then
            code = table.concat(row.codes):upper()
            break
        end
    end
    if code == nil then return nil, "Fairy Ring ID is not in the destination log" end

    local previous = search:GetText()
    search:SetText(code)
    return { field = search, previous = previous, applied = code }
end

function highlight.End(menu, state)
    -- Do not erase a query the player edited after the request.
    if state.field:GetText() == state.applied then
        state.field:SetText(state.previous)
    end
end

return highlight
