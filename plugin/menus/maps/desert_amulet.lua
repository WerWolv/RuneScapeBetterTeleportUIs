local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local DesertAmulet = MapMenu.Create(ModalChoiceMenu, "desertAmulet")

function DesertAmulet:Define()
    return {
        title = "Desert",
        background = backgrounds.desert,
        vignette = false,
        noBackgroundCrop = true,
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
