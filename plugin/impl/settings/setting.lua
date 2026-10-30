local text = require("impl/text")
local Setting = {}
Setting.__index = Setting

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
    return self.value
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
end

-- Widgets choose placement; these helpers keep shared typography and spacing consistent.
function Setting:AddLabel(host, label)
    label = label or self.definition.label

    if not text.IsBlank(label) then
        return host:AddText(label)
    end
end

function Setting:AddDescription(host, description)
    description = description or self.definition.description

    if not text.IsBlank(description) then
        return host:AddText({
            text = "       " .. description,
            font = id.Font.MUSEO_SANS_11PT_REGULAR,
            colour = 0xAFA79AFF,
            shadowed = false,
            marginTop = 0,
            marginBottom = 6,
        })
    end
end

function Setting:Unmount()
    self.control = nil
end

function Setting:ControlMargin()
    return not text.IsBlank(self.definition.description) and 0 or nil
end

return Setting
