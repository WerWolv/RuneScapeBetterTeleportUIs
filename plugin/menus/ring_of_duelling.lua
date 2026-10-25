local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local RingOfDuelling = ModalChoiceMenu:Extend("ringOfDuelling")

-- Define ring of duelling destinations and its hidden cancel option.
function RingOfDuelling:Define()
    return {
        title = "Ring of Duelling",
        background = cropped(
            backgrounds.runescapeSurface, 
            {x = 93, y = 81, width = 314, height = 213}
        ),
        entries = {
            ["1. Het's Oasis"] = {
                icons = teleportIcons.relicOfHet,
                point = {x = 369, y = 161},
            },
            ["2. Castle Wars Arena"] = {
                icons = teleportIcons.castleWarsCape,
                point = {x = 110, y = 199},
            },
            ["3. The Warforge"] = {
                icons = teleportIcons.warForgeShield,
                point = {x = 112, y = 276},
            },
            ["4. Fist of Guthix"] = {
                icons = teleportIcons.fistOfGuthixOrb,
                point = {x = 283, y = 111},
            },
            ["5. Nowhere"] = {hidden = true},
        },
    }
end

return RingOfDuelling
