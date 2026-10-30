local Setting = require("impl/settings/setting")
local BooleanSetting = Setting:Extend()
BooleanSetting.valueType = "boolean"

function BooleanSetting:Read()
    return PersistentDB:GetBool(self.definition.key)
end

function BooleanSetting:Write(value)
    PersistentDB:SetBool(self.definition.key, value)
end

function BooleanSetting:CreateControl(host)
    local control = host:AddCheckboxButton({
        { text = self.definition.label, value = self.definition.key, selected = self.value },
    }, {
        marginBottom = self:ControlMargin(),
        onChange = function(_, _, _, selected) self:Set(selected) end,
    })
    self:AddDescription(host)
    return control
end

function BooleanSetting:UpdateControl()
    self.control:SetSelected(self.definition.key, self.value)
end

return BooleanSetting
