local FairyRingMap = require("menus/maps/fairy_rings")
local EnhancedList = require("menus/enhancements/fairy_rings/enhanced_list")
local settings = require("impl/settings")

-- Keep the registered settings path stable while composing the two presentations.
local FairyRings = FairyRingMap:Extend("fairyRings")

function FairyRings:UseOriginalUIByDefault()
    return not settings.Get("fairyRingMapByDefault")
end

function FairyRings:CreateOriginalMenu()
    local menu = EnhancedList:New()
    menu.enabledSetting = self.enabledSetting

    return menu
end

return FairyRings
