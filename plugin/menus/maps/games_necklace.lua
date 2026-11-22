local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local GamesNecklace = MapMenu.Create(ModalChoiceMenu, "gamesNecklace")

function GamesNecklace:Define()
    return {
        title = "Games necklace",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.jewellery.goldSapphire,
        entries = {
            ["1. Troll Invasion"] = {
                id = "trollinvasion",
                point = {x = 247, y = 41},
                --icons = teleportIcons.trollInvasion,
            },
            ["2. Barbarian Outpost"] = {
                id = "barbarianoutpost",
                point = {x = 147, y = 69},
                --icons = teleportIcons.horn,
            },
            ["3. Gamer's Grotto"] = {
                id = "gamersgrotto",
                point = {x = 283, y = 111},
                --icons = teleportIcons.dice,
            },
            ["4. Agoroth"] = {
                id = "agoroth",
                point = {x = 110, y = 304},
                --icons = teleportIcons.squid,
            },
            ["5. Corporeal Beast"] = {
                id = "corporealbeast",
                point = {x = 326, y = 30},
                --icons = teleportIcons.corporealBeast,
            },
            ["6. Burgh De Rott"] = {
                id = "burghderott",
                point = {x = 432, y = 165},
                --icons = teleportIcons.sickle,
            },
            ["7. Tears of Guthix"] = {
                id = "tearsofguthix",
                point = {x = 341, y = 178},
                --icons = teleportIcons.tearsOfGuthix,
            },
        },
    }
end

return GamesNecklace
