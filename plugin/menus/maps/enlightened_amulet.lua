local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local EnlightenedAmulet = MapMenu.Create(ModalChoiceMenu, "enlightenedAmulet")

function EnlightenedAmulet:Define()
    return {
        title = "Enlightened Amulet",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.jewellery.silverTopaz,
        entries = {
            ["1. Lumbridge Swamp"] = {
                id = "nexus",
                point = {x = 338, y = 181},
            },
            ["2. South of the Graveyard of Shadows"] = {
                id = "graveyard",
                nameOverride = "Graveyard of Shadows",
                point = {x = 348, y = 45},
            },
            ["3. Desert bandit camp entrance"] = {
                id = "banditcamp",
                nameOverride = "Bandit camp",
                point = {x = 336, y = 224},
            },
            ["4. Nowhere"] = {hidden = true},
        },
    }
end

return EnlightenedAmulet
