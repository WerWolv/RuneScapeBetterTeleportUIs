local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local PassingBracelet = ModalChoiceMenu:Extend("passingBracelet")

-- Define passing bracelet destinations in the City of Um.
function PassingBracelet:Define()
    return {
        title = "Underworld",
        background = backgrounds.cityOfUm,
        entries = {
            ["1. City of Um: Hanging Gardens"] = {
                nameOverride = "Hanging Gardens",
                point = {x = 737, y = 464},
                icons = teleportIcons.elfcityTeleport[1],
            },
            ["2. City of Um: Haunt on the Hill"] = {
                nameOverride = "Haunt on the Hill",
                point = {x = 709, y = 223},
                icons = teleportIcons.elfcityTeleport[0],
            },
            ["3. City of Um: Reflection Pool"] = {
                nameOverride = "Reflection Pool",
                point = {x = 555, y = 800},
                icons = teleportIcons.elfcityTeleport[3],
            },
            ["4. Nowhere"] = {hidden = true},
        },
    }
end

return PassingBracelet
