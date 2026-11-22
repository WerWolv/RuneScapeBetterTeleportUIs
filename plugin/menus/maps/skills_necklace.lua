local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local SkillsNecklace = MapMenu.Create(ModalChoiceMenu, "skillsNecklace")

function SkillsNecklace:Define()
    return {
        title = "Skilling Guilds",
        background = backgrounds.runescapeSurface,
        entries = {
            ["1. Fishing Guild"] = {
                id = "fishing",
                point = {x = 175, y = 123},
                icons = teleportIcons.skillCursor.fishing
            },
            ["2. Mining Guild"] = {
                id = "mining",
                point = {x = 295, y = 135},
                icons = teleportIcons.skillCursor.mining
            },
            ["3. Crafting Guild"] = {
                id = "crafting",
                point = {x = 268, y = 147},
                icons = teleportIcons.skillCursor.crafting
            },
            ["4. Cooking Guild"] = {
                id = "cooking",
                point = {x = 327, y = 110},
                icons = teleportIcons.skillCursor.cooking
            },
            ["5. Invention Guild"] = {
                id = "invention",
                point = {x = 278, y = 103},
                icons = teleportIcons.skillCursor.inventionDiscover
            },
            ["6. Farming Guild"] = {
                id = "farming",
                point = {x = 190, y = 130},
                icons = teleportIcons.skillCursor.farming
            },
            ["7. Runecrafting Guild"] = {
                id = "runecrafting",
                point = {x = 315, y = 187},
                icons = teleportIcons.skillCursor.runecrafting
            },
            ["8. Nowhere"] = {hidden = true},
        },
    }
end

return SkillsNecklace
