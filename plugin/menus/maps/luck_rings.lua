local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local LuckRings = ModalChoiceMenu:Extend("luckRings")

function LuckRings:Define()
    return {
        title = "Ring of Duelling",
        background = backgrounds.runescapeSurface,
        entries = {
            ["1. Miscellania"] = {
                icons = teleportIcons.ringOfFortune,
                point = {x = 113, y = 17},
            },
            ["2. Grand Exchange"] = {
                icons = teleportIcons.ringOfFortune,
                point = {x = 329, y = 93},
            },
            ["3. Keldagrim"] = {
                icons = teleportIcons.luckOfTheDwarves,
                point = {x = 204, y = 29},
                possiblyMissing = true
            },
            ["4. Hazelmere's Statue"] = {
                icons = teleportIcons.hazelmeresSignetRing,
                point = {x = 120, y = 115},
                possiblyMissing = true
            },
            ["^%d%. Dwarven Outpost$"] = {
                icons = teleportIcons.luckOfTheDwarves,
                point = {x = 154, y = 96},
                possiblyMissing = true
            },
            ["^%d%. Nowhere$"] = {hidden = true},
        },
    }
end

return LuckRings
