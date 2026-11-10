local ChoiceV2Menu = require("impl/interfaces/native/choice_v2_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local BogolinTelepearl = MapMenu.Create(ChoiceV2Menu, "bogolinTelepearl")

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
