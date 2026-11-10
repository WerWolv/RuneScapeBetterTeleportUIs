local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local PassingBracelet = MapMenu.Create(ModalChoiceMenu, "passingBracelet")

function PassingBracelet:Define()
    return {
        title = "Underworld",
        background = backgrounds.cityOfUm,
        noBackgroundCrop = true,
        icons = teleportIcons.jewellery.ensouledMoonstone,
        entries = {
            ["1. City of Um: Hanging Gardens"] = {
                nameOverride = "Hanging Gardens",
                point = {x = 737, y = 464},
            },
            ["2. City of Um: Haunt on the Hill"] = {
                nameOverride = "Haunt on the Hill",
                point = {x = 709, y = 223},
            },
            ["3. City of Um: Reflection Pool"] = {
                nameOverride = "Reflection Pool",
                point = {x = 555, y = 800},
            },
            ["4. Nowhere"] = {hidden = true},
        },
    }
end

return PassingBracelet
