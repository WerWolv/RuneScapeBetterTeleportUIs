local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local CombatBracelet = ModalChoiceMenu:Extend("combatBracelet")

function CombatBracelet:Define()
    return {
        title = "Combat Bracelet",
        background = cropped(backgrounds.runescapeSurface, {x = 119, y = 4, width = 290, height = 200}),
        icons = teleportIcons.combatBracelet,
        entries = {
            ["1. Warriors' Guild"] = {
                point = {x = 239, y = 70}
            },
            ["2. Champions' Guild"] = {
                point = {x = 336, y = 121}
            },
            ["3. Edgeville Monastery"] = {
                point = {x = 297, y = 94}
            },
            ["4. Ranging Guild"] = {
                point = {x = 188, y = 107}
            },
            ["5. Nowhere"] = {
                hidden = true
            },
        },
    }
end

return CombatBracelet
