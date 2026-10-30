local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local EnlightenedAmulet = ModalChoiceMenu:Extend("enlightenedAmulet")

function EnlightenedAmulet:Define()
    return {
        title = "Enlightened Amulet",
        background = cropped(
            backgrounds.runescapeSurface,
            {x = 240, y = 0, width = 210, height = 250}
        ),
        icons = teleportIcons.enlightenedAmulet,
        entries = {
            ["1. Lumbridge Swamp"] = {
                point = {x = 338, y = 181},
            },
            ["2. South of the Graveyard of Shadows"] = {
                nameOverride = "Graveyard of Shadows",
                point = {x = 348, y = 45},
            },
            ["3. Desert bandit camp entrance"] = {
                nameOverride = "Bandit camp",
                point = {x = 336, y = 224},
            },
            ["4. Nowhere"] = {hidden = true},
        },
    }
end

return EnlightenedAmulet
