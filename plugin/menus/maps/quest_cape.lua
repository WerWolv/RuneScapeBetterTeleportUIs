local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local QuestCape = ModalChoiceMenu:Extend("questCape")

function QuestCape:Define()
    return {
        title = "Quest Teleports",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.quests,
        entries = {
            ["1. Ancient Guthix Temple"] = {
                point = {x = 331, y = 180},
            },
            ["2. Behind the Scenes"] = {
                point = {x = 348, y = 128},
            },
            ["3. Champions' Guild"] = {
                point = {x = 323, y = 110},
            },
            ["4. The Empty Throne Room"] = {
                point = {x = 384, y = 106},
            },
            ["5. Glacor Cavern"] = {
                point = {x = 245, y = 20},
            },
            ["6. Heroes' Guild - Fountain of Heroes"] = {
                nameOverride = "Heroes' Guild",
                description = descriptions.Location("Fountain of Heroes"),
                point = {x = 256, y = 80},
            },
            ["7. Legends' Guild"] = {
                point = {x = 200, y = 127},
            },
            ["8. Tears of Guthix"] = {
                point = {x = 348, y = 180},
            },
            ["9. Varrock Museum"] = {
                point = {x = 358, y = 96},
            },
            ["0. The World Gate"] = {
                point = {x = 101, y = 124},
            },
        },
    }
end

return QuestCape
