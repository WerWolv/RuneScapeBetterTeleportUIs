local ChoiceV2Menu = require("impl/interfaces/choice_v2_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local BogolinTelepearl = ChoiceV2Menu:Extend("bogolinTelepearl")

function BogolinTelepearl:Define()
    return {
        title = "Fenmoor",
        background = backgrounds.havenhythe,
        icons = teleportIcons.bogolinTelepearl,
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
