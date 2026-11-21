local utils = require("impl/utils")
local translations = require("impl/translations")
local constants = require("definitions/constants")

local matcher = {}

-- Test localized input on English worlds without changing native controls or actions.
local function nativeLabel(label)
    return constants.debugNativeLabels and constants.debugNativeLabels[label] or label
end

-- Keep canonical keys separate from native labels and translated patterns.
local function indexEntries(entries)
    local literals, patterns = {}, {}
    local language = translations.Current()

    local function add(key, label)
        if key:sub(1, 1) == "^" then
            patterns[#patterns + 1] = { key = key, pattern = label }
        elseif literals[label] == nil or literals[label] == key then
            literals[label] = key
        else
            literals[label] = false
        end
    end

    for key in pairs(entries) do
        if type(key) == "string" then
            local translated = translations.GetMapping(key, language)
            if translated ~= key then
                add(key, translated)
            end
            add(key, key)
        end
    end

    return literals, patterns
end

-- Format detected labels in a stable order for readable matching diagnostics.
function matcher.LabelSummary(labels)
    local names = {}

    for text in pairs(labels) do
        names[#names + 1] = string.format("%q", nativeLabel(text))
    end

    table.sort(names)

    return #names > 0 and table.concat(names, ", ") or "<no visible text>"
end

-- Recognize every native option without copying definitions or modifying native controls.
function matcher.Match(snapshot, group, validate)
    if type(group) ~= "table" or type(group.entries) ~= "table" then
        return nil, "missing entries table"
    end

    local minimumMatches = group.minimumMatches
    if minimumMatches ~= nil and (not utils.IsFinite(minimumMatches)
        or minimumMatches < 1 or minimumMatches % 1 ~= 0) then
        return nil, "minimumMatches must be a positive integer"
    end

    local rows, matched = {}, {}
    local background, hasVisibleDestination
    local literals, patterns = indexEntries(group.entries)

    for _, native in ipairs(snapshot.nativeRows) do
        local name, entryKey, matchPattern

        for label in pairs(native.labels) do
            local text = nativeLabel(label)
            local key, pattern = literals[text], nil

            if key == false then
                return nil, "OPTION_" .. native.index .. " matches multiple literal entries: " .. text
            end

            -- Literal entries take precedence over explicitly anchored Lua patterns.
            if key == nil then
                for _, candidate in ipairs(patterns) do
                    local candidateKey = candidate.key
                    if key ~= candidateKey then
                        local ok, start = pcall(string.find, text, candidate.pattern)

                        if not ok then
                            return nil, string.format(
                                "entry %q has an invalid Lua pattern %q: %s", candidateKey, candidate.pattern, start
                            )
                        end

                        if start ~= nil then
                            if key ~= nil then
                                return nil, "OPTION_" .. native.index .. " matches multiple pattern entries: " .. text
                            end

                            key, pattern = candidateKey, candidate.pattern
                        end
                    end
                end
            end

            if key ~= nil then
                if name ~= nil then
                    return nil, "OPTION_" .. native.index .. " matches multiple entries: " .. matcher.LabelSummary(native.labels)
                end

                name, entryKey, matchPattern = text, key, pattern
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

            if not ok then
                return nil, string.format("entry %q %s", name, reason)
            end

            background = definition.background or group.background
            hasVisibleDestination = true
        end

        matched[entryKey] = true
        rows[#rows + 1] = {
            name = name,
            entryKey = entryKey,
            matchPattern = matchPattern,
            row = native.row,
            click = native.click,
            native = native,
        }
    end

    if not hasVisibleDestination then
        return nil, "no non-hidden destinations matched"
    end

    -- Only native options count; possiblyMissing placeholders are added afterward.
    if minimumMatches ~= nil and #rows < minimumMatches then
        return nil, string.format("matched %d native options; requires at least %d", #rows, minimumMatches)
    end

    local unusedEntries, missingKeys = 0, {}

    for name, definition in pairs(group.entries) do
        if not matched[name] then
            unusedEntries = unusedEntries + 1

            if type(definition) == "table" and definition.possiblyMissing == true and definition.hidden ~= true then
                local ok, reason = validate(definition, background)

                if not ok then
                    return nil, string.format("missing entry %q %s", name, reason)
                end

                missingKeys[#missingKeys + 1] = name
            end
        end
    end

    table.sort(missingKeys)

    for _, name in ipairs(missingKeys) do
        rows[#rows + 1] = { name = name, entryKey = name, locked = true, disabled = true }
    end

    return {
        group = group,
        title = group.title or "Select a destination",
        rows = rows,
        background = background,
        unusedEntries = unusedEntries,
        snapshot = snapshot,
        window = snapshot.window,
        content = snapshot.content,
        nativeRows = snapshot.nativeRows,
    }
end

-- Resolve display callbacks or expand captures without reinterpreting captured text.
local function expandCaptures(text, match)
    if type(text) == "function" then
        local result

        if match ~= nil then
            result = text(table.unpack(match, 3, match.n))
        else
            result = text()
        end

        assert(
            result == nil or type(result) == "string",
            "Teleport nameOverride, description and disabledDescription functions must return a string or nil"
        )

        return result
    end

    if match == nil or type(text) ~= "string" then
        return text
    end

    return (text:gsub("%%([1-9%%])", function(token)
        if token == "%" then
            return "%"
        end

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
            if key ~= "background" and key ~= "icons" then
                data[key] = value
            end
        end

        row.destination = utils.DeepCopy(data)
        row.destination.hidden = definition.hidden == true
        row.destination.background = definition.background or menu.group.background
        row.destination.icons = definition.icons or menu.group.icons

        local match
        if not row.locked then
            local pattern = row.matchPattern or row.entryKey
            if pattern ~= row.name and row.entryKey:sub(1, 1) == "^" then
                match = table.pack(string.find(row.name, pattern))
            end

            row.destination.nameOverride = expandCaptures(row.destination.nameOverride, match)
            row.destination.description = expandCaptures(row.destination.description, match)
        end
        row.destination.disabledDescription = expandCaptures(row.destination.disabledDescription, match)
    end

    return menu
end

-- Compare native identity and complete label sets before reusing a resolved menu.
function matcher.SameSnapshot(previous, current)
    if previous.window ~= current.window or previous.content ~= current.content
        or #previous.nativeRows ~= #current.nativeRows then
        return false
    end

    for index, native in ipairs(current.nativeRows) do
        local old = previous.nativeRows[index]

        if native.row ~= old.row or native.click ~= old.click or native.index ~= old.index then
            return false
        end

        for label in pairs(native.labels) do
            if not old.labels[label] then
                return false
            end
        end

        for label in pairs(old.labels) do
            if not native.labels[label] then
                return false
            end
        end
    end

    return true
end

return matcher
