local utils = require("impl/utils")
local matcher = {}

-- Format detected labels in a stable order for readable matching diagnostics.
function matcher.LabelSummary(labels)
    local names = {}
    for text in pairs(labels) do names[#names + 1] = string.format("%q", text) end
    table.sort(names)
    return #names > 0 and table.concat(names, ", ") or "<no visible text>"
end

-- Recognize every native option without copying definitions or modifying native controls.
function matcher.Match(snapshot, group, validate)
    if type(group) ~= "table" or type(group.entries) ~= "table" then
        return nil, "missing entries table"
    end
    local rows, matched = {}, {}
    local background, hasVisibleDestination
    for _, native in ipairs(snapshot.nativeRows) do
        local name, entryKey
        for text in pairs(native.labels) do
            local key = group.entries[text] ~= nil and text or nil
            -- Literal entries take precedence over explicitly anchored Lua patterns.
            if key == nil then
                for candidateKey in pairs(group.entries) do
                    if type(candidateKey) == "string" and candidateKey:sub(1, 1) == "^" then
                        local ok, start = pcall(string.find, text, candidateKey)
                        if not ok then
                            return nil, string.format("entry %q has an invalid Lua pattern: %s", candidateKey, start)
                        end
                        if start ~= nil then
                            if key ~= nil then
                                return nil, "OPTION_" .. native.index .. " matches multiple pattern entries: " .. text
                            end
                            key = candidateKey
                        end
                    end
                end
            end
            if key ~= nil then
                if name ~= nil then
                    return nil, "OPTION_" .. native.index .. " matches multiple entries: " .. matcher.LabelSummary(native.labels)
                end
                name, entryKey = text, key
            end
        end
        if name == nil then
            return nil, "OPTION_" .. native.index .. " has no configured entry for " .. matcher.LabelSummary(native.labels)
        end
        local definition = group.entries[entryKey]
        if type(definition) ~= "table" then
            return nil, string.format("entry %q must be a table", entryKey)
        end
        if definition.hidden ~= true then
            local ok, reason = validate(definition, background)
            if not ok then return nil, string.format("entry %q %s", name, reason) end
            background = definition.background or group.background
            hasVisibleDestination = true
        end
        matched[entryKey] = true
        rows[#rows + 1] = {
            name = name, entryKey = entryKey, row = native.row, click = native.click,
            native = native,
        }
    end
    if not hasVisibleDestination then return nil, "no non-hidden destinations matched" end

    local unusedEntries, missingKeys = 0, {}
    for name, definition in pairs(group.entries) do
        if not matched[name] then
            unusedEntries = unusedEntries + 1
            if type(definition) == "table" and definition.possiblyMissing == true and definition.hidden ~= true then
                local ok, reason = validate(definition, background)
                if not ok then return nil, string.format("missing entry %q %s", name, reason) end
                missingKeys[#missingKeys + 1] = name
            end
        end
    end
    table.sort(missingKeys)
    for _, name in ipairs(missingKeys) do
        rows[#rows + 1] = {name = name, entryKey = name, locked = true, disabled = true}
    end
    return {
        group = group, title = group.title or "Select a destination",
        rows = rows, background = background, unusedEntries = unusedEntries,
        snapshot = snapshot, window = snapshot.window, content = snapshot.content,
        nativeRows = snapshot.nativeRows,
    }
end

-- Resolve display callbacks or expand captures without reinterpreting captured text.
local function expandCaptures(text, match)
    if type(text) == "function" then
        local result
        if match ~= nil then result = text(table.unpack(match, 3, match.n)) else result = text() end
        assert(result == nil or type(result) == "string",
            "Teleport nameOverride and description functions must return a string or nil")
        return result
    end
    if match == nil or type(text) ~= "string" then return text end
    return (text:gsub("%%([1-9%%])", function(token)
        if token == "%" then return "%" end
        local value = match[tonumber(token) + 2]
        return value ~= nil and tostring(value) or "%" .. token
    end))
end

-- Copy only the winning menu's entry data, preserving shared artwork and resource identities.
function matcher.Resolve(menu)
    for _, row in ipairs(menu.rows) do
        local definition = menu.group.entries[row.entryKey]
        local data = {}
        for key, value in pairs(definition) do
            if key ~= "background" and key ~= "icons" then data[key] = value end
        end
        row.destination = utils.deepcopy(data)
        row.destination.hidden = definition.hidden == true
        row.destination.background = definition.background or menu.group.background
        row.destination.icons = definition.icons or menu.group.icons
        if not row.locked then
            local match
            if row.entryKey ~= row.name and row.entryKey:sub(1, 1) == "^" then
                match = table.pack(string.find(row.name, row.entryKey))
            end
            row.destination.nameOverride = expandCaptures(row.destination.nameOverride, match)
            row.destination.description = expandCaptures(row.destination.description, match)
        end
    end
    return menu
end

-- Compare native identity and complete label sets before reusing a resolved menu.
function matcher.SameSnapshot(previous, current)
    if previous.window ~= current.window or previous.content ~= current.content
        or #previous.nativeRows ~= #current.nativeRows then return false end
    for index, native in ipairs(current.nativeRows) do
        local old = previous.nativeRows[index]
        if native.row ~= old.row or native.click ~= old.click or native.index ~= old.index then return false end
        for label in pairs(native.labels) do if not old.labels[label] then return false end end
        for label in pairs(old.labels) do if not native.labels[label] then return false end end
    end
    return true
end

return matcher
