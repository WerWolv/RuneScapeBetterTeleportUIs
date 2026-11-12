local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local PharaohsSceptre = MapMenu.Create(ModalChoiceMenu, "pharaohsSceptre")

function PharaohsSceptre:Define()
    return {
        title = "Desert",
        background = backgrounds.desert,
        vignette = false,
        noBackgroundCrop = true,
        entries = {
            ["1. Jalsavrah (Pyramid Plunder)"] = {
                nameOverride = "Jalsavrah",
                description = descriptions.Location("Pyramid Plunder"),
                icons = teleportIcons.magicCarpet.port,
                point = {x = 176, y = 258},
            },
            ["2. Jaleustrophos (Agility Pyramid)"] = {
                nameOverride = "Jaleustrophos",
                description = descriptions.Location("Agility Pyramid"),
                icons = teleportIcons.magicCarpet.worker,
                point = {x = 227, y = 239},
            },
            ["3. Jaldraocht (Azzanadra's Pyramid)"] = {
                nameOverride = "Jaldraocht",
                description = descriptions.Location("Azzanadra's Pyramid"),
                icons = teleportIcons.magicCarpet.merchant,
                point = {x = 100, y = 190},
            },
            ["4. Jalkabir (Menaphos Golden Palace)"] = {
                -- Only available in the Sceptre of the Gods
                nameOverride = "Jalkabir",
                description = descriptions.Location("Menaphos Golden Palace"),
                icons = teleportIcons.magicCarpet.imperial,
                point = {x = 71, y = 270},
                possiblyMissing = true
            },
            ["^%d%. I'm happy where I am actually%.$"] = { -- what?
                hidden = true
            },
        },
    }
end

return PharaohsSceptre
