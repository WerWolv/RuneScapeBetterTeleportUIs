local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local L = require("impl/translations").Localize
local AmuletOfGlory = MapMenu.Create(ModalChoiceMenu, "amuletOfGlory")

function AmuletOfGlory:Define()
    return {
        title = L("Amulet of Glory"),
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.jewellery.goldDragonstone,
        entries = {
            ["^1%. Edgeville%.?"] = {
                id = "edgeville",
                point = {x = 302, y = 86},
            },
            ["^2%. Karamja%.?"] = {
                id = "karamja",
                point = {x = 254, y = 181},
            },
            ["^3%. Draynor Village%.?"] = {
                id = "draynor",
                point = {x = 308, y = 156},
            },
            ["^4%. Al Kharid%.?"] = {
                id = "alkharid",
                point = {x = 371, y = 196},
            },
            ["^5%. Nowhere%.?"] = {hidden = true},
        },
    }
end

return AmuletOfGlory
