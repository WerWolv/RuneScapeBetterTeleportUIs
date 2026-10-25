local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local WildernessSword = ModalChoiceMenu:Extend("wildernessSword")

-- Define the shared sword menu with locked markers for unavailable upgrades.
function WildernessSword:Define()
    return {
        title = "Wilderness",
        background = cropped(
            backgrounds.wilderness, 
            {x = 0, y = 80, width = 512, height = 792}
        ),
        icons = teleportIcons.obelisk,
        entries = {
            ["1. Teleport to Edgeville"] = {
                nameOverride = "Edgeville",
                point = {x = 263, y = 825},
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
