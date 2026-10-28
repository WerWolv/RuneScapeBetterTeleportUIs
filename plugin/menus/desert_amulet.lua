local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local DesertAmulet = ModalChoiceMenu:Extend("desertAmulet")

function DesertAmulet:Define()
    return {
        title = "Desert",
        background = backgrounds.desert,
        entries = {
            ["1. Nardah"] = {
                icons = teleportIcons.magicCarpet.port,
                point = {x = 263, y = 163},
            },
            ["2. Uzer"] = {
                icons = teleportIcons.magicCarpet.worker,
                point = {x = 294, y = 30},
            },
        },
    }
end

return DesertAmulet
