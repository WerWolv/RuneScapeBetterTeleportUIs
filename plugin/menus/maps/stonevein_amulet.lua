local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local StoneveinAmulet = ModalChoiceMenu:Extend("stoneveinAmulet")

function StoneveinAmulet:Define()
    return {
        title = "Havenhythe Murals",
        background = backgrounds.havenhythe,
        noBackgroundCrop = true,
        icons = teleportIcons.remnantEnergy,
        entries = {
            ["1. Divine fall"] = {
                point = {x = 729, y = 250}
            },
            ["2. Bat mural"] = {
                point = {x = 838, y = 357},
                possiblyMissing = true
            },
            ["3. Unicorn mural"] = {
                point = {x = 764, y = 384},
                possiblyMissing = true
            },
            ["4. Tree mural"] = {
                point = {x = 554, y = 396},
                possiblyMissing = true
            },
            ["5. Wolf mural"] = {
                point = {x = 573, y = 305},
                possiblyMissing = true
            },
            ["6. Fox mural"] = {
                point = {x = 682, y = 603},
                possiblyMissing = true
            },
            ["7. Spider mural"] = {
                point = {x = 344, y = 233},
                possiblyMissing = true
            },
            ["8. Millipede mural"] = {
                point = {x = 210, y = 609},
                possiblyMissing = true
            },
        },
    }
end

return StoneveinAmulet
