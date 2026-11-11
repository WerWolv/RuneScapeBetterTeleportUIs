local definitions = require("definitions/settings")
local Group = require("impl/settings/group")
local Page = require("impl/settings/page")
local utils = require("impl/utils")

local settings = {}
local eventID = "teleportMapsSettings"
local instances, byKey = {}, {}
local pages = {}
local windowPositions = {}
local view, parent
local builtins = {
    boolean = "impl/settings/boolean",
    number = "impl/settings/number",
    string = "impl/settings/string",
    label  = "impl/settings/label"
}

-- Register nested settings eagerly so their saved values are available before any UI opens.
local function registerGroups(groupDefinitions)
    local groups = {}

    for _, group in ipairs(groupDefinitions) do
        local children = {}

        for _, definition in ipairs(group.settings) do
            assert(type(definition.key) == "string" and definition.key ~= "", "Setting requires a key")
            assert(byKey[definition.key] == nil, "Duplicate setting: " .. definition.key)

            local class = require(builtins[definition.type] or definition.type)
            local instance = class:New(definition)

            instances[#instances + 1] = instance
            children[#children + 1] = instance
            byKey[definition.key] = instance

            if definition.details ~= nil then
                assert(definition.type == "boolean", "Only boolean settings support detail pages")

                instance.details = registerGroups(definition.details)
            end
        end

        local widget = group.widget and require(group.widget) or Group
        groups[#groups + 1] = widget:New(group, children)
    end

    return groups
end

local groups = registerGroups(definitions)

function settings.Get(key)
    return assert(byKey[key], "Unknown setting: " .. tostring(key)):Get()
end

function settings.Set(key, value)
    assert(byKey[key], "Unknown setting: " .. tostring(key)):Set(value)
end

local function validPosition(position)
    return type(position) == "table" and utils.IsFinite(position.x) and utils.IsFinite(position.y)
end

-- Menu module keys keep separate interfaces independent while sharing a position across pages.
function settings.GetWindowPosition(key)
    if key == nil then
        return nil
    end

    if windowPositions[key] == nil then
        local saved = PersistentDB:GetStructuredData("windowPosition/" .. key)
        windowPositions[key] = validPosition(saved) and { x = math.floor(saved.x), y = math.floor(saved.y) } or false
    end

    local position = windowPositions[key]
    return position and { x = position.x, y = position.y } or nil
end

function settings.SetWindowPosition(key, position)
    if key == nil then
        return
    end

    assert(validPosition(position), "Invalid window position for: " .. key)
    local x, y = math.floor(position.x), math.floor(position.y)
    local previous = windowPositions[key]

    if previous and previous.x == x and previous.y == y then
        return
    end

    local saved = { x = x, y = y }
    PersistentDB:SetStructuredData("windowPosition/" .. key, saved)
    windowPositions[key] = saved
end

local function clearView()
    local previousParent, previousView, previousPages = parent, view, pages
    parent, view, pages = nil, nil, {}

    if previousParent ~= nil then
        pcall(function()
            previousParent:Unsubscribe(ui.Hook.ONRESIZE, eventID)
        end)
    end

    for _, page in ipairs(previousPages) do
        pcall(function()
            page:Destroy()
        end)
    end

    if previousView ~= nil then
        pcall(function()
            previousView:Destroy()
        end)
    end
end

local function buildSettings(event)
    clearView()
    parent = event.component

    local tabs, tabIndexes, tabGroups = {}, {}, {}

    for _, group in ipairs(groups) do
        local tab = group.definition.tab

        if tabIndexes[tab] == nil then
            tabs[#tabs + 1] = tab
            tabIndexes[tab] = #tabs
            tabGroups[#tabs] = {}
        end

        local children = tabGroups[tabIndexes[tab]]
        children[#children + 1] = group
    end

    view = prettyui.Tabs.new(parent, tabs, {
        width = 0,
        height = 0,
        widthAnchor = 1,
        heightAnchor = 1,
        scrollable = false,
        onChange = function()
            if view == nil then
                return
            end

            for _, page in ipairs(pages) do
                page:Refresh()
            end
        end,
    })

    for index, children in ipairs(tabGroups) do
        local page = Page.New(view:GetPage(index).root, children, view.root)
        pages[index] = page
        page:Mount()
    end

    parent:Subscribe(ui.Hook.ONRESIZE, eventID, function()
        if view ~= nil then
            view:SetActive(view:GetActiveIndex(), false)

            for _, page in ipairs(pages) do
                page:Refresh()
            end
        end
    end)
end

function settings.Start()
    windowPositions = {}

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
