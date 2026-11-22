local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local EnchantedLyre = MapMenu.Create(ModalChoiceMenu, "enchantedLyre")

function EnchantedLyre:Define()
    return {
        title = "Fremennik Isles",
        background = backgrounds.fremennikIsles,
        noBackgroundCrop = true,
        entries = {
            ["1. Rellekka"] = {
                id = "relekka",
                icons = teleportIcons.magicLyre,
                point = {x = 970, y = 418},
                hotkeyOffset = { x = 0, y = -25 },
            },
            ["^%d+%. Waterbirth Island$"] = {
                id = "waterbirth",
                icons = teleportIcons.magicLyre,
                point = {x = 754, y = 349},
                possiblyMissing = true,
            },
            ["^%d+%. Neitiznot$"] = {
                id = "neitiznot",
                icons = teleportIcons.magicLyre,
                point = {x = 431, y = 255},
                possiblyMissing = true,
            },
            ["^%d+%. Jatizso$"] = {
                id = "jatizso",
                icons = teleportIcons.magicLyre,
                point = {x = 559, y = 255},
                possiblyMissing = true,
            },
            ["^%d+%. Miscellania$"] = {
                id = "miscellania",
                icons = teleportIcons.magicLyre,
                point = {x = 766, y = 151},
                possiblyMissing = true,
            },
            ["^%d+%. Etceteria$"] = {
                id = "etceteria",
                icons = teleportIcons.magicLyre,
                point = {x = 855, y = 140},
                possiblyMissing = true,
            },
            ["^%d+%. Rellekka Market$"] = {
                id = "relekkamarket",
                icons = teleportIcons.magicLyre,
                point = {x = 918, y = 456},
                hotkeyOffset = { x = 0, y = -25 },
                possiblyMissing = true,
            },
            ["^%d+%. Cancel%.?$"] = {
                hidden = true
            },
        },
    }
end

return EnchantedLyre
