local Setting = require("impl/settings/setting")
local utils = require("impl/utils")
local NumberSetting = Setting:Extend()

function NumberSetting:Validate(value)
    return utils.IsFinite(value)
        and value >= (self.definition.min or 0) and value <= (self.definition.max or 100)
end

function NumberSetting:Read()
    return PersistentDB:GetFloat(self.definition.key)
end

function NumberSetting:Write(value)
    PersistentDB:SetFloat(self.definition.key, value)
end

function NumberSetting:CreateControl(host)
    self:AddLabel(host)
    local control = host:AddSlider({
        min = self.definition.min or 0,
        max = self.definition.max or 100,
        step = self.definition.step or 1,
        value = self.value,
        marginBottom = self:ControlMargin(),
        onChange = function(_, value) self:Set(value) end,
    })
    self:AddDescription(host)
    return control
end

function NumberSetting:UpdateControl()
    self.control:SetValue(self.value, false)
end

return NumberSetting
