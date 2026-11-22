local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local QuestCape = MapMenu.Create(ModalChoiceMenu, "questCape")

function QuestCape:Define()
    return {
        title = "Quest Teleports",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.quests,
        entries = {
            ["1. Ancient Guthix Temple"] = {
                id = "guthixtemple",
                point = {x = 331, y = 180},
            },
            ["2. Behind the Scenes"] = {
                id = "behindthescenes",
                point = {x = 348, y = 128},
            },
            ["3. Champions' Guild"] = {
                id = "championsguild",
                point = {x = 323, y = 110},
            },
            ["4. The Empty Throne Room"] = {
                id = "emptythroneroom",
                point = {x = 384, y = 106},
            },
            ["5. Glacor Cavern"] = {
                id = "glacorcavern",
                point = {x = 245, y = 20},
            },
            ["6. Heroes' Guild - Fountain of Heroes"] = {
                id = "heroesguild",
                nameOverride = "Heroes' Guild",
                description = descriptions.Location("Fountain of Heroes"),
                point = {x = 256, y = 80},
            },
            ["7. Legends' Guild"] = {
                id = "legensguild",
                point = {x = 200, y = 127},
            },
            ["8. Tears of Guthix"] = {
                id = "tearsofguthix",
                point = {x = 348, y = 180},
            },
            ["9. Varrock Museum"] = {
                id = "museum",
                point = {x = 358, y = 96},
            },
            ["0. The World Gate"] = {
                id = "worldgate",
                point = {x = 101, y = 124},
            },
        },
    }
end

return QuestCape
