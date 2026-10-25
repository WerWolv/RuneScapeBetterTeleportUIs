local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local WildernessObelisks = ModalChoiceMenu:Extend("wildernessObelisks")

-- Define the Wilderness obelisk destinations.
function WildernessObelisks:Define()
    return {
        title = "Wilderness Obelisks",
        background = backgrounds.wilderness,
        icons = teleportIcons.obelisk,
        entries = {
            ["1. Level 13 Wilderness"] = {
                nameOverride = "Wilderness Lodestone",
                point = {x = 382, y = 708},
            },
            ["2. Level 18 Wilderness"] = {
                nameOverride = "Graveyard of Shadows",
                point = {x = 492, y = 646},
            },
            ["3. Level 27 Wilderness"] = {
                nameOverride = "Chaos Ridge",
                point = {x = 171, y = 512},
            },
            ["4. Level 35 Wilderness"] = {
                nameOverride = "Lava Maze",
                point = {x = 294, y = 405},
            },
            ["5. Level 44 Wilderness"] = {
                nameOverride = "Frozen Waste Plateau",
                point = {x = 75, y = 279},
            },
            ["6. Level 50 Wilderness"] = {
                nameOverride = "Rogues' Castle",
                point = {x = 645, y = 192},
            },
        },
    }
end

return WildernessObelisks
