local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local UnderworldGrimoire = ModalChoiceMenu:Extend("underworldGrimoire")

-- Define grimoire destinations with a locked Lupe marker for lower tiers.
function UnderworldGrimoire:Define()
    return {
        title = "Underworld",
        background = backgrounds.cityOfUm,
        entries = {
            ["1. Teleport to Um Smithy"] = {
                nameOverride = "Um Smithy",
                point = {x = 616, y = 377},
                icons = teleportIcons.umSmithyTeleport,
            },
            ["2. Teleport to Um Ritual Site"] = {
                nameOverride = "Um Ritual Site",
                point = {x = 96, y = 590},
                icons = teleportIcons.underworldTeleport,
            },
            ["3. Teleport to Ungael Ritual Site"] = {
                nameOverride = "Ungael Ritual Site",
                point = {x = 170, y = 165},
                icons = teleportIcons.ungaelTeleport,
            },
            ["4. Teleport to Lupe"] = {
                nameOverride = "Lupe",
                possiblyMissing = true,
                point = {x = 371, y = 417},
                icons = teleportIcons.lupeTeleport,
            },
        },
    }
end

return UnderworldGrimoire
