local Setting = require("impl/settings/setting")
local LabelSetting = Setting:Extend()

-- Labels are display-only and have no stored value.
function LabelSetting:Validate(value)
    return value == nil
end

function LabelSetting:Read()
    return nil
end

function LabelSetting:Write(value) end

function LabelSetting:CreateControl(host)
    self:AddLabel(host)
    self:AddDescription(host)
    return nil
end

function LabelSetting:UpdateControl() end

return LabelSetting
