local highlight = {}

-- Use native log codes, including destinations outside the map and multi-code routes.
function highlight.GetTargets(menu)
    local targets, seen = {}, {}
    for _, row in ipairs(menu.session.highlightRows or {}) do
        for _, code in ipairs(row.codes) do
            code = code:upper()
            if not seen[code] then
                seen[code] = true
                targets[#targets + 1] = { key = code, name = row.name or row.location, disabled = false }
            end
        end
    end
    return targets
end

function highlight.Begin(menu, search, key)
    if search == nil then return nil, "Search is not showing" end
    if type(key) ~= "string" then return nil, "Fairy Ring key must be a code" end
    local code = key:upper():gsub("[%s%-]", "")
    local found = false
    for _, target in ipairs(highlight.GetTargets(menu)) do
        if target.key == code then
            found = true
            break
        end
    end
    if not found then return nil, "Fairy Ring code is not in the destination log" end

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
