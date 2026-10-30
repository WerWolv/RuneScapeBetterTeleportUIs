local definitions = require("definitions/settings")
local Group = require("impl/settings/group")
local settings = {}
local eventID = "teleportMapsSettings"
local instances, byKey, groups = {}, {}, {}
local view, parent
local builtins = {
    boolean = "impl/settings/boolean",
    number = "impl/settings/number",
    string = "impl/settings/string",
    label  = "impl/settings/label"
}

-- Custom types are module paths returning Setting subclasses.
for _, group in ipairs(definitions) do
    local children = {}
    for _, definition in ipairs(group.settings) do
        assert(type(definition.key) == "string" and definition.key ~= "", "Setting requires a key")
        assert(byKey[definition.key] == nil, "Duplicate setting: " .. definition.key)

        local class = require(builtins[definition.type] or definition.type)
        local instance = class:New(definition)
        instances[#instances + 1] = instance
        children[#children + 1] = instance
        byKey[definition.key] = instance
    end
    groups[#groups + 1] = Group:New(group, children)
end

function settings.Get(key)
    return assert(byKey[key], "Unknown setting: " .. tostring(key)):Get()
end

function settings.Set(key, value)
    assert(byKey[key], "Unknown setting: " .. tostring(key)):Set(value)
end

local function clearView()
    if parent ~= nil then
        pcall(function() parent:Unsubscribe(ui.Hook.ONRESIZE, eventID) end)
    end

    for _, group in ipairs(groups) do
        group:Unmount()
    end

    if view ~= nil then
        pcall(function() view:Destroy() end)
    end

    parent, view = nil, nil
end

local function buildSettings(event)
    clearView()
    parent = event.component
    local tabs, tabIndexes = {}, {}

    for _, group in ipairs(groups) do
        local tab = group.definition.tab

        if tabIndexes[tab] == nil then
            tabs[#tabs + 1] = tab
            tabIndexes[tab] = #tabs
        end
    end

    view = prettyui.Tabs.new(parent, tabs, {
        width = 0,
        height = 0,
        widthAnchor = 1,
        heightAnchor = 1,
        onChange = function()
            for _, group in ipairs(groups) do group:Refresh() end
        end,
    })

    local positions = {}
    for _, group in ipairs(groups) do
        local index = tabIndexes[group.definition.tab]
        local page = view:GetPage(index)
        positions[index] = group:Mount(page, positions[index] or 8)
        page:SetContentHeight(positions[index])
    end
    for _, group in ipairs(groups) do group:Refresh() end

    parent:Subscribe(ui.Hook.ONRESIZE, eventID, function()
        if view ~= nil then
            view:SetActive(view:GetActiveIndex(), false)
            for _, group in ipairs(groups) do group:Refresh() end
        end
    end)
end

function settings.Start()
    for _, instance in ipairs(instances) do
        instance:Load()
    end

    Event.SettingsLayerReady.Subscribe(eventID, buildSettings)
end

function settings.Stop()
    Event.SettingsLayerReady.Unsubscribe(eventID)
    clearView()
end

return settings
