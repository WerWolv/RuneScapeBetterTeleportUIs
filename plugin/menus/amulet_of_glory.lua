local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local AmuletOfGlory = ModalChoiceMenu:Extend("amuletOfGlory")

function AmuletOfGlory:Define()
    return {
        title = "Amulet of Glory",
        background = cropped(
            backgrounds.runescapeSurface, 
            {x = 194, y = 60, width = 241, height = 161}
        ),
        icons = teleportIcons.amuletOfGlory,
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
