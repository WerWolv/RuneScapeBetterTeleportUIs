local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local AmuletOfGlory = MapMenu.Create(ModalChoiceMenu, "amuletOfGlory")

function AmuletOfGlory:Define()
    return {
        title = "Amulet of Glory",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.jewellery.goldDragonstone,
        entries = {
            ["1. Edgeville"] = {
                point = {x = 302, y = 86},
            },
            ["2. Karamja"] = {
                point = {x = 254, y = 181},
            },
            ["3. Draynor Village"] = {
                point = {x = 308, y = 156},
            },
            ["4. Al Kharid"] = {
                point = {x = 371, y = 196},
            },
            ["5. Nowhere"] = {hidden = true},
        },
    }
end

return AmuletOfGlory
