local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local WildernessObelisks = MapMenu.Create(ModalChoiceMenu, "wildernessObelisks")

function WildernessObelisks:Define()
    return {
        title = "Wilderness Obelisks",
        background = backgrounds.wilderness,
        noBackgroundCrop = true,
        icons = teleportIcons.obelisk,
        entries = {
            ["1. Level 13 Wilderness"] = {
                id = "13",
                nameOverride = "Wilderness Lodestone",
                point = {x = 382, y = 708},
            },
            ["2. Level 18 Wilderness"] = {
                id = "18",
                nameOverride = "Graveyard of Shadows",
                point = {x = 492, y = 646},
            },
            ["3. Level 27 Wilderness"] = {
                id = "27",
                nameOverride = "Chaos Ridge",
                point = {x = 171, y = 512},
            },
            ["4. Level 35 Wilderness"] = {
                id = "35",
                nameOverride = "Lava Maze",
                point = {x = 294, y = 405},
            },
            ["5. Level 44 Wilderness"] = {
                id = "44",
                nameOverride = "Frozen Waste Plateau",
                point = {x = 75, y = 279},
            },
            ["6. Level 50 Wilderness"] = {
                id = "50",
                nameOverride = "Rogues' Castle",
                point = {x = 645, y = 192},
            },
        },
    }
end

return WildernessObelisks
