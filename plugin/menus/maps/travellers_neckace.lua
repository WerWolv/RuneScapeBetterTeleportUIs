local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local TravellersNecklace = ModalChoiceMenu:Extend("travellersNecklace")

function TravellersNecklace:Define()
    return {
        title = "Traveller's Necklace",
        background = cropped(
            backgrounds.runescapeSurface,
            {x = 50, y = 50, width = 420, height = 200}
        ),
        icons = teleportIcons.travellersNecklace,
        entries = {
            ["1. Wizards' Tower"] = {
                point = {x = 310, y = 170},
            },
            ["2. The Outpost"] = {
                point = {x = 130, y = 130},
            },
            ["3. South of the Desert Eagle's Eyrie"] = {
                nameOverride = "Desert Eagle's Eyrie",
                point = {x = 400, y = 190},
            },
            ["4. Nowhere"] = {hidden = true},
        },
    }
end

return TravellersNecklace
