local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local BigBookOPiracy = ModalChoiceMenu:Extend("bigBookOPiracy")

function BigBookOPiracy:Define()
    return {
        title = "Pirate Islands",
        background = backgrounds.pirateIslands,
        icons = teleportIcons.bigBookOPiracy,
        entries = {
            ["1. Mos Le'Harmless."] = {
                nameOverride = "Mos Le'Harmless",
                point = {x = 145, y = 451},
            },
            ["2. Braindeath Island."] = {
                nameOverride = "Braindeath Island",
                point = {x = 765, y = 512},
            },
            ["3. Dragontooth Isle."] = {
                nameOverride = "Dragontooth Isle",
                point = {x = 575, y = 83},
            },
            ["4. Harmony Island."] = {
                nameOverride = "Harmony Island",
                point = {x = 402, y = 753},
            },
        },
    }
end

return BigBookOPiracy
