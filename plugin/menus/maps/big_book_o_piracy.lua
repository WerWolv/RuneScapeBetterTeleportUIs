local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local ChoiceV2Menu = require("impl/interfaces/native/choice_v2_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local PirateSpellSheet = MapMenu.Create(ChoiceV2Menu, "pirateSpellSheet")
local BigBookOPiracy = MapMenu.Create(ModalChoiceMenu, "bigBookOPiracy")

function PirateSpellSheet:Define()
    return {
        title = "Pirate Islands",
        background = backgrounds.pirateIslands,
        noBackgroundCrop = true,
        entries = {
            ["1. Braindeath Island."] = {
                nameOverride = "Braindeath Island",
                point = {x = 765, y = 512},
                icons = teleportIcons.pirateSpellSheet,
            },
            ["2. Mos Le'Harmless."] = {
                nameOverride = "Mos Le'Harmless",
                point = {x = 145, y = 451},
                icons = teleportIcons.pirateSpellSheet,
            },
            ["3. Dragontooth Isle."] = {
                nameOverride = "Dragontooth Isle",
                point = {x = 575, y = 83},
                possiblyMissing = true,
                icons = teleportIcons.bigBookOPiracy,
            },
            ["4. Harmony Island."] = {
                nameOverride = "Harmony Island",
                point = {x = 402, y = 753},
                possiblyMissing = true,
                icons = teleportIcons.bigBookOPiracy,
            },
        },
    }
end

function BigBookOPiracy:Define()
    return {
        title = "Pirate Islands",
        background = backgrounds.pirateIslands,
        noBackgroundCrop = true,
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

return { PirateSpellSheet, BigBookOPiracy }
