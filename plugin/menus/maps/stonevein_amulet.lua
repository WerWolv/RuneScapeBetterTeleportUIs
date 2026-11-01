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
        sizeMultiplier = 1.25,
        entries = {
            ["1. Divine fall"] = {
                point = {x = 729, y = 250}
            },
            ["^%d+%. Bat mural$"] = {
                point = {x = 838, y = 357},
                possiblyMissing = true
            },
            ["^%d+%. Unicorn mural$"] = {
                point = {x = 764, y = 384},
                possiblyMissing = true
            },
            ["^%d+%. Tree mural$"] = {
                point = {x = 554, y = 396},
                possiblyMissing = true
            },
            ["^%d+%. Wolf mural$"] = {
                point = {x = 573, y = 305},
                possiblyMissing = true
            },
            ["^%d+%. Fox mural$"] = {
                point = {x = 682, y = 603},
                possiblyMissing = true
            },
            ["^%d+%. Spider mural$"] = {
                point = {x = 344, y = 233},
                possiblyMissing = true
            },
            ["^%d+%. Millipede mural$"] = {
                point = {x = 210, y = 609},
                possiblyMissing = true
            },
        },
    }
end

return StoneveinAmulet
