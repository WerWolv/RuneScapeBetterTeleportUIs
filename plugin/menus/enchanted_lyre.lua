local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local EnchantedLyre = ModalChoiceMenu:Extend("enchantedLyre")

-- Define the Desert Amulet destinations.
function EnchantedLyre:Define()
    return {
        title = "Fremennik Isles",
        background = cropped(
            backgrounds.fremennikIsles,
            { x = 380, y = 60, width = 640, height = 453 }
        ),
        entries = {
            ["1. Rellekka"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 970, y = 418},
            },
            ["2. Waterbirth Island"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 754, y = 349},
            },
            ["3. Neitiznot"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 431, y = 255},
            },
            ["4. Jatizso"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 559, y = 255},
            },
            ["5. Miscellania"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 766, y = 151},
            },
            ["6. Etceteria"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 855, y = 140},
            },
            ["7. Rellekka Market"] = {
                icons = teleportIcons.magicLyre,
                point = {x = 918, y = 456},
            },
            ["8. Cancel."] = {
                hidden = true
            },
        },
    }
end

return EnchantedLyre
