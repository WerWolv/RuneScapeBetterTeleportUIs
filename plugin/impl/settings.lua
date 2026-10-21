local definitions = require("definitions/settings")
local settings = {}
local eventID = "teleportMapsSettings"
local values, byKey, controls = {}, {}, {}
local view
local parent

local function hasDescription(definition)
    return definition.description ~= nil and not definition.description:match("^%s*$")
end

local types = {
    boolean = {
        read = function(key) return PersistentDB:GetBool(key) end,
        write = function(key, value) PersistentDB:SetBool(key, value) end,
        valid = function(value) return type(value) == "boolean" end,
        create = function(host, definition)
            local control = host:AddCheckboxButton({
                {text = definition.label, value = definition.key, selected = values[definition.key]},
            }, {
                marginBottom = hasDescription(definition) and 0 or nil,
                onChange = function(_, _, _, selected)
                    settings.Set(definition.key, selected)
                end,
            })
            return function(value) control:SetSelected(definition.key, value) end
        end,
    },
    number = {
        read = function(key) return PersistentDB:GetFloat(key) end,
        write = function(key, value) PersistentDB:SetFloat(key, value) end,
        valid = function(value, definition)
            return type(value) == "number" and value == value and math.abs(value) < math.huge
                and value >= (definition.min or 0) and value <= (definition.max or 100)
        end,
        create = function(host, definition)
            host:AddText(definition.label)
            local control = host:AddSlider({
                min = definition.min or 0,
                max = definition.max or 100,
                step = definition.step or 1,
                value = values[definition.key],
                marginBottom = hasDescription(definition) and 0 or nil,
                onChange = function(_, value) settings.Set(definition.key, value) end,
            })
            return function(value) control:SetValue(value, false) end
        end,
    },
    string = {
        read = function(key) return PersistentDB:GetString(key) end,
        write = function(key, value) PersistentDB:SetString(key, value) end,
        valid = function(value) return type(value) == "string" end,
        create = function(host, definition)
            host:AddText(definition.label)
            local control = host:AddTextField({
                text = values[definition.key],
                placeholder = definition.placeholder,
                marginBottom = hasDescription(definition) and 0 or nil,
                onChange = function(_, _, text) settings.Set(definition.key, text) end,
            })
            return function(value) control:SetText(value, false) end
        end,
    },
}

for _, definition in ipairs(definitions) do
    assert(type(definition.key) == "string" and definition.key ~= "", "Setting requires a key")
    assert(byKey[definition.key] == nil, "Duplicate setting: " .. definition.key)
    local handler = types[definition.type]
    assert(handler ~= nil, "Unsupported setting type: " .. tostring(definition.type))
    assert(handler.valid(definition.default, definition), "Invalid default for setting: " .. definition.key)
    byKey[definition.key] = definition
    values[definition.key] = definition.default
end

function settings.Get(key)
    assert(byKey[key] ~= nil, "Unknown setting: " .. tostring(key))
    return values[key]
end

function settings.Set(key, value)
    local definition = byKey[key]
    assert(definition ~= nil, "Unknown setting: " .. tostring(key))
    local handler = types[definition.type]
    assert(handler.valid(value, definition), "Invalid value for setting: " .. key)
    if values[key] == value then return end
    values[key] = value
    handler.write(key, value)
    -- Also update an open control when callers change a setting programmatically.
    -- The equality check above prevents loops from controls that emit on sync.
    if controls[key] ~= nil then controls[key](value) end
end

local function clearView()
    controls = {}
    -- The client clears the settings layer before presenting it again.
    if parent ~= nil then
        pcall(function() parent:Unsubscribe(ui.Hook.ONRESIZE, eventID) end)
    end
    if view ~= nil then
        pcall(function() view:Destroy() end)
    end
    parent, view = nil, nil
end

local function buildSettings(event)
    clearView()
    parent = event.component
    view = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })
    for _, definition in ipairs(definitions) do
        controls[definition.key] = types[definition.type].create(view, definition)
        if hasDescription(definition) then
            view:AddText({
                text = "       " .. definition.description,
                font = id.Font.MUSEO_SANS_11PT_REGULAR,
                colour = 0xAFA79AFF,
                shadowed = false,
                marginTop = 0,
                marginBottom = 12,
            })
        end
    end
    parent:Subscribe(ui.Hook.ONRESIZE, eventID, function(control)
        if view ~= nil then view:SetSize(control.width, control.height) end
    end)
end

function settings.Start()
    for _, definition in ipairs(definitions) do
        local handler = types[definition.type]
        local saved = handler.read(definition.key)
        if handler.valid(saved, definition) then
            values[definition.key] = saved
        else
            values[definition.key] = definition.default
        end
    end
    Event.SettingsLayerReady.Subscribe(eventID, buildSettings)
end

function settings.Stop()
    Event.SettingsLayerReady.Unsubscribe(eventID)
    clearView()
end

return settings
