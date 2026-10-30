local Setting = require("impl/settings/setting")
local StringSetting = Setting:Extend()
StringSetting.valueType = "string"

function StringSetting:Read()
    return PersistentDB:GetString(self.definition.key)
end

function StringSetting:Write(value)
    PersistentDB:SetString(self.definition.key, value)
end

function StringSetting:CreateControl(host)
    self:AddLabel(host)
    local control = host:AddTextField({
        text = self.value,
        placeholder = self.definition.placeholder,
        marginBottom = self:ControlMargin(),
        onChange = function(_, _, value) self:Set(value) end,
    })
    self:AddDescription(host)
    return control
end

function StringSetting:UpdateControl()
    self.control:SetText(self.value, false)
end

return StringSetting
