local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local WildernessSword = MapMenu.Create(ModalChoiceMenu, "wildernessSword")

function WildernessSword:Define()
    return {
        title = "Wilderness",
        background = backgrounds.wilderness,
        icons = teleportIcons.lodestone.wilderness,
        entries = {
            ["1. Teleport to Edgeville"] = {
                nameOverride = "Edgeville",
                point = {x = 263, y = 805},
            },
            ["2. Teleport to Herb patch"] = {
                nameOverride = "Herb patch",
                point = {x = 359, y = 355},
            },
            ["3. Teleport to Forinthry Dungeon"] = {
                nameOverride = "Forinthry Dungeon",
                possiblyMissing = true,
                point = {x = 237, y = 667},
            },
            ["4. Teleport to Wilderness Agility course"] = {
                nameOverride = "Wilderness Agility course",
                possiblyMissing = true,
                point = {x = 106, y = 192},
            },
        },
    }
end

return WildernessSword
