local FairyRingMap = require("menus/maps/fairy_rings")
local EnhancedList = require("menus/maps/fairy_rings/enhanced_list")
local settings = require("impl/settings")

-- Compose the map and enhanced native presentations under one registered menu.
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
