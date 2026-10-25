local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local GamesNecklace = ModalChoiceMenu:Extend("gamesNecklace")

-- Define games necklace destinations on the cropped surface map.
function GamesNecklace:Define()
    return {
        title = "Games necklace",
        background = cropped(
            backgrounds.runescapeSurface, 
            {x = 85, y = 0, width = 377, height = 320}
        ),
        entries = {
            ["1. Troll Invasion"] = {
                point = {x = 247, y = 41},
                icons = teleportIcons.trollInvasion,
            },
            ["2. Barbarian Outpost"] = {
                point = {x = 147, y = 69},
                icons = teleportIcons.horn,
            },
            ["3. Gamer's Grotto"] = {
                point = {x = 283, y = 111},
                icons = teleportIcons.dice,
            },
            ["4. Agoroth"] = {
                point = {x = 110, y = 304},
                icons = teleportIcons.squid,
            },
            ["5. Corporeal Beast"] = {
                point = {x = 326, y = 30},
                icons = teleportIcons.corporealBeast,
            },
            ["6. Burgh De Rott"] = {
                point = {x = 432, y = 165},
                icons = teleportIcons.sickle,
            },
            ["7. Tears of Guthix"] = {
                point = {x = 341, y = 178},
                icons = teleportIcons.tearsOfGuthix,
            },
        },
    }
end

return GamesNecklace
