local text = require("impl/text")

local Setting = {}
Setting.__index = Setting

local descriptionColour = 0xAFA79AFF
local disabledDescriptionColour = 0x777777FF

function Setting:Extend()
    local class = {}
    class.__index = class

    return setmetatable(class, { __index = self })
end

function Setting:New(definition)
    local instance = setmetatable({ definition = definition, value = definition.default }, self)
    assert(instance:Validate(definition.default), "Invalid default for setting: " .. definition.key)

    return instance
end

function Setting:Validate(value)
    return type(value) == self.valueType
end

function Setting:Get()
    if not self:IsEnabled() then
        if self.definition.type == "boolean" then
            return false
        end
        return self.definition.default
    end
    return self.value
end

function Setting:IsEnabled()
    return self.dependency == nil or self.dependency:Get() == true
end

function Setting:RefreshEnabled()
    if self.descriptionLabel ~= nil then
        self.descriptionLabel.rgba = self:IsEnabled() and descriptionColour or disabledDescriptionColour
    end

    if self.dependency ~= nil and self.control ~= nil and self.control.SetDisabled ~= nil then
        self.control:SetDisabled(not self:IsEnabled())
    end

    for _, dependent in ipairs(self.dependents or {}) do
        dependent:RefreshEnabled()
    end
end

function Setting:Set(value)
    assert(self:Validate(value), "Invalid value for setting: " .. self.definition.key)

    if self.value == value then
        return
    end

    self.value = value
    self:Write(value)

    if self.control ~= nil then
        self:UpdateControl()
    end
    self:RefreshEnabled()
end

function Setting:Load()
    local saved = self:Read()

    if self:Validate(saved) then
        self.value = saved
    else
        self.value = self.definition.default
    end
end

-- The settings view owns native controls; instances retain only the active control state.
function Setting:Mount(host)
    self.control = self:CreateControl(host)
    self:UpdateControl()
    self:RefreshEnabled()
end

-- Reuse for controls and their labels so nested dependencies line up consistently.
function Setting:ControlOptions(options)
    options = options or {}
    local indent = (self.dependencyDepth or 0) * 18
    if indent > 0 then
        options.x = indent
        options.width = -indent
        options.widthAnchor = 1
    end
    return options
end

-- Widgets choose placement; these helpers keep shared typography and spacing consistent.
function Setting:AddLabel(host, label)
    label = label or self.definition.label

    if not text.IsBlank(label) then
        return host:AddText(self:ControlOptions({ text = label }))
    end
end

function Setting:AddDescription(host, description)
    description = description or self.definition.description

    if not text.IsBlank(description) then
        self.descriptionLabel = host:AddText(self:ControlOptions({
            text = "       " .. description,
            font = id.Font.MUSEO_SANS_11PT_REGULAR,
            colour = self:IsEnabled() and descriptionColour or disabledDescriptionColour,
            shadowed = false,
            marginTop = 0,
            marginBottom = 6,
        }))
        return self.descriptionLabel
    end
end

function Setting:Unmount()
    self.control = nil
    self.descriptionLabel = nil
end

-- Full-height editor groups supply the available area after mounting and resizing.
function Setting:Layout(width, height)
end

function Setting:ControlMargin()
    return not text.IsBlank(self.definition.description) and 0 or nil
end

return Setting
