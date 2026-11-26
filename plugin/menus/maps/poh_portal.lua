local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local POHPortal = MapMenu.Create(ModalChoiceMenu, "pohPortal")

function POHPortal:Define()
    return {
        title = "House Portals",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.house,
        entries = {
            ["1. Rimmington"] = {
                point = {x = 266, y = 164},
            },
            ["2. Taverley"] = {
                point = {x = 239, y = 98},
            },
            ["^%d%. Pollnivneach"] = {
                point = {x = 374, y = 233},
                possiblyMissing = true,
            },
            ["^%d%. Relleka"] = {
                point = {x = 178, y = 45},
                possiblyMissing = true,
            },
            ["^%d%. Brimhaven"] = {
                point = {x = 209, y = 177},
                possiblyMissing = true,
            },
            ["^%d%. Yanille"] = {
                point = {x = 158, y = 204},
                possiblyMissing = true,
            },
            ["^%d%. Menaphos"] = {
                point = {x = 334, y = 290},
                possiblyMissing = true,
            },
            ["^%d%. Mazcab"] = {
                point = {x = 306, y = 264},
                possiblyMissing = true,
            },
            ["^%d%. Prifddinas"] = {
                point = {x = 44, y = 126},
                possiblyMissing = true,
            }
        },
    }
end

return POHPortal
