local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local BogolinTelepearl = ModalChoiceMenu:Extend("bogolinTelepearl")

function BogolinTelepearl:Define()
    return {
        title = "Fenmoor",
        background = backgrounds.havenhythe,
        icons = teleportIcons.bogolinTelepearl,
        sizeMultiplier = 3.5,
        entries = {
            ["1. Linbog"] = {
                point = {x = 671, y = 496}
            },
            ["2. Globin"] = {
                point = {x = 759, y = 574},
            }
        },
    }
end

return BogolinTelepearl
