local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local StoneveinAmulet = MapMenu.Create(ModalChoiceMenu, "stoneveinAmulet")

function StoneveinAmulet:Define()
    return {
        title = "Havenhythe Murals",
        background = backgrounds.havenhythe,
        noBackgroundCrop = true,
        icons = teleportIcons.remnantEnergy,
        sizeMultiplier = 1.25,
        entries = {
            ["1. Divine fall"] = {
                id = "divinefall",
                point = {x = 729, y = 250}
            },
            ["^%d+%. Bat mural$"] = {
                id = "batmural",
                point = {x = 838, y = 357},
                possiblyMissing = true
            },
            ["^%d+%. Unicorn mural$"] = {
                id = "unicornmural",
                point = {x = 764, y = 384},
                possiblyMissing = true
            },
            ["^%d+%. Tree mural$"] = {
                id = "treemural",
                point = {x = 554, y = 396},
                possiblyMissing = true
            },
            ["^%d+%. Wolf mural$"] = {
                id = "wolfmural",
                point = {x = 573, y = 305},
                possiblyMissing = true
            },
            ["^%d+%. Fox mural$"] = {
                id = "foxmural",
                point = {x = 682, y = 603},
                possiblyMissing = true
            },
            ["^%d+%. Spider mural$"] = {
                id = "spidermural",
                point = {x = 344, y = 233},
                possiblyMissing = true
            },
            ["^%d+%. Millipede mural$"] = {
                id = "millipedemural",
                point = {x = 210, y = 609},
                possiblyMissing = true
            },
        },
    }
end

return StoneveinAmulet
