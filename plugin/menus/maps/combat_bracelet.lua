local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local CombatBracelet = MapMenu.Create(ModalChoiceMenu, "combatBracelet")

function CombatBracelet:Define()
    return {
        title = "Combat Bracelet",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.jewellery.goldDragonstone,
        entries = {
            ["1. Warriors' Guild"] = {
                id = "warriors",
                point = {x = 239, y = 70}
            },
            ["2. Champions' Guild"] = {
                id = "champions",
                point = {x = 336, y = 121}
            },
            ["3. Edgeville Monastery"] = {
                id = "monastery",
                point = {x = 297, y = 94}
            },
            ["4. Ranging Guild"] = {
                id = "ranging",
                point = {x = 188, y = 107}
            },
            ["5. Nowhere"] = {
                hidden = true
            },
        },
    }
end

return CombatBracelet
