local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local SkillsNecklace = ModalChoiceMenu:Extend("skillsNecklace")

function SkillsNecklace:Define()
    return {
        title = "Skilling Guilds",
        background = cropped(
            backgrounds.runescapeSurface,
            { x = 147, y = 68, width = 210, height = 147 }
        ),
        entries = {
            ["1. Fishing Guild"] = {
                point = {x = 175, y = 123},
                icons = teleportIcons.skillCursor.fishing
            },
            ["2. Mining Guild"] = {
                point = {x = 295, y = 135},
                icons = teleportIcons.skillCursor.mining
            },
            ["3. Crafting Guild"] = {
                point = {x = 268, y = 147},
                icons = teleportIcons.skillCursor.crafting
            },
            ["4. Cooking Guild"] = {
                point = {x = 327, y = 110},
                icons = teleportIcons.skillCursor.cooking
            },
            ["5. Invention Guild"] = {
                point = {x = 278, y = 103},
                icons = teleportIcons.skillCursor.inventionDiscover
            },
            ["6. Farming Guild"] = {
                point = {x = 190, y = 130},
                icons = teleportIcons.skillCursor.farming
            },
            ["7. Runecrafting Guild"] = {
                point = {x = 315, y = 187},
                icons = teleportIcons.skillCursor.runecrafting
            },
            ["8. Nowhere"] = {hidden = true},
        },
    }
end

return SkillsNecklace
