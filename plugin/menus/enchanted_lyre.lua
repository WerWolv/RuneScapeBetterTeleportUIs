local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local EnchantedLyre = ModalChoiceMenu:Extend("enchantedLyre")

-- Define the Enchanted Lyre destinations.
function EnchantedLyre:Define()
    return {
        title = "Fremennik Isles",
        background = cropped(
            backgrounds.fremennikIsles,
            { x = 380, y = 60, width = 640, height = 453 }
        ),
        entries = {
            ["^%d+%. Rellekka$"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 970, y = 418},
            },
            ["^%d+%. Waterbirth Island$"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 754, y = 349},
                possiblyMissing = true,
            },
            ["^%d+%. Neitiznot$"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 431, y = 255},
                possiblyMissing = true,
            },
            ["^%d+%. Jatizso$"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 559, y = 255},
                possiblyMissing = true,
            },
            ["^%d+%. Miscellania$"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 766, y = 151},
                possiblyMissing = true,
            },
            ["^%d+%. Etceteria$"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 855, y = 140},
                possiblyMissing = true,
            },
            ["^%d+%. Rellekka Market$"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 918, y = 456},
                possiblyMissing = true,
            },
            ["^%d+%. Cancel%.?$"] = {
                hidden = true
            },
        },
    }
end

return EnchantedLyre
