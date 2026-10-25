local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local BigBookOPiracy = ModalChoiceMenu:Extend("bigBookOPiracy")

-- Define the Big Book o' Piracy island destinations.
function BigBookOPiracy:Define()
    return {
        title = "Pirate Islands",
        background = backgrounds.pirateIslands,
        icons = teleportIcons.bigBookOPiracy,
        entries = {
            ["1. Mos Le'Harmless."] = {
                nameOverride = "Mos Le'Harmless",
                point = {x = 120, y = 426},
            },
            ["2. Braindeath Island."] = {
                nameOverride = "Braindeath Island",
                point = {x = 710, y = 487},
            },
            ["3. Dragontooth Isle."] = {
                nameOverride = "Dragontooth Isle",
                point = {x = 550, y = 58},
            },
            ["4. Harmony Island."] = {
                nameOverride = "Harmony Island",
                point = {x = 377, y = 728},
            },
        },
    }
end

return BigBookOPiracy
