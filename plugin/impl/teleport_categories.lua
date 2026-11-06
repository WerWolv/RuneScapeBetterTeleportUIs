local text = require("impl/text")

local TeleportCategories = {}
TeleportCategories.__index = TeleportCategories

local function encode(value)
    return value:gsub("[%%,\t\r\n]", function(character)
        return string.format("%%%02X", character:byte())
    end)
end

local function decode(value)
    return value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

-- Stable IDs keep the active category and its assignments intact when renamed.
function TeleportCategories.Parse(value)
    local data = { nextID = 1, entries = {} }
    local nextID, body = value:match("^v1\n(%d+)\n(.*)$")

    if nextID == nil then
        return data
    end

    data.nextID = math.max(1, tonumber(nextID))

    local seen = {}

    for line in body:gmatch("[^\r\n]+") do
        local id, name, members = line:match("^(%d+)\t([^\t]+)\t(.*)$")
        id = tonumber(id)

        if id ~= nil and id > 0 and not seen[id] then
            name = text.Clean(decode(name))

            if name ~= "" then
                local entry = { id = id, name = name, destinations = {} }

                for member in members:gmatch("[^,]+") do
                    entry.destinations[decode(member)] = true
                end

                data.entries[#data.entries + 1] = entry
                data.nextID = math.max(data.nextID, id + 1)
                seen[id] = true
            end
        end
    end

    return data
end

function TeleportCategories.Serialize(data)
    local lines = { "v1", tostring(data.nextID) }

    for _, entry in ipairs(data.entries) do
        local members = {}

        for name, selected in pairs(entry.destinations) do
            if selected then
                members[#members + 1] = encode(name)
            end
        end

        table.sort(members)
        lines[#lines + 1] = entry.id .. "\t" .. encode(entry.name) .. "\t" .. table.concat(members, ",")
    end

    return table.concat(lines, "\n") .. "\n"
end

function TeleportCategories.NameError(name, data, builtins, exceptID)
    if name == "" then
        return "Enter a category name."
    end

    local normalized = name:lower()

    if normalized == "all" then
        return "This category name is already in use."
    end

    for _, category in ipairs(builtins) do
        if category.label:lower() == normalized then
            return "This category name is already in use."
        end
    end

    for _, category in ipairs(data.entries) do
        if category.id ~= exceptID and category.name:lower() == normalized then
            return "This category name is already in use."
        end
    end
end

function TeleportCategories.New(definition, destinations)
    return setmetatable({
        definition = definition,
        destinations = destinations,
        selected = PersistentDB:GetString(definition.selectionKey) or "all",
    }, TeleportCategories)
end

-- The caller supplies saved data, allowing the same model to serve any teleport menu.
function TeleportCategories:Update(value)
    if value == self.value then
        return false, false
    end

    self.value = value
    self.data = TeleportCategories.Parse(value)
    self.choices = { { text = "All", value = "all" } }
    self.byKey = { all = true }

    for _, category in ipairs(self.definition.builtins) do
        self.choices[#self.choices + 1] = { text = category.label, value = category.key }
        self.byKey[category.key] = true
    end

    for _, category in ipairs(self.data.entries) do
        local key = "custom:" .. category.id
        self.choices[#self.choices + 1] = { text = category.name, value = key }
        self.byKey[key] = category
    end

    -- A map only offers categories containing one of its native destinations.
    -- Keep this independent of search and the currently selected category.
    if self.destinations ~= nil then
        local choices = {}

        for _, choice in ipairs(self.choices) do
            local populated = choice.value == "all"

            for _, destination in ipairs(self.destinations) do
                if populated or self:Includes(destination, choice.value) then
                    populated = true
                    break
                end
            end

            if populated then
                choices[#choices + 1] = choice
            else
                self.byKey[choice.value] = nil
            end
        end

        self.choices = choices
    end

    local labels = {}

    for _, choice in ipairs(self.choices) do
        labels[#labels + 1] = choice.value .. "\t" .. encode(choice.text)
    end

    local signature = table.concat(labels, "\n")
    local choicesChanged = signature ~= self.signature
    self.signature = signature

    if not self.byKey[self.selected] then
        self:Select("all")
    end

    return true, choicesChanged
end

function TeleportCategories:Select(key)
    if self.byKey[key] and self.selected ~= key then
        self.selected = key
        PersistentDB:SetString(self.definition.selectionKey, key)
    end
end

function TeleportCategories:Includes(destination, key)
    local selected = key or self.selected

    if selected == "all" then
        return true
    end

    local custom = self.byKey[selected]

    if type(custom) == "table" then
        return custom.destinations[destination.categoryKey] == true
    end

    for _, categoryKey in ipairs(destination.categories or {}) do
        if categoryKey == selected then
            return true
        end
    end

    return false
end

return TeleportCategories
