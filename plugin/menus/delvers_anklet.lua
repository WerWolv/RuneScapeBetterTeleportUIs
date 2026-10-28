local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local DelversAnklet = ModalChoiceMenu:Extend("delversAnklet")

function DelversAnklet:Define()
    return {
        title = "Delver's Anklet",
        background = cropped(
            backgrounds.runescapeSurface, 
            {x = 132, y = 0, width = 291, height = 200}
        ),
        icons = teleportIcons.delversAnklet,
        entries = {
            ["1. Brimhaven Dungeon"] = {
                point = {x = 209, y = 172},
            },
            ["2. Fremennik Slayer Dungeon"] = {
                point = {x = 200, y = 30},
            },
            ["3. Polypore Dungeon"] = {
                point = {x = 398, y = 144},
            },
            ["4. Nowhere"] = {hidden = true},
        },
    }
end

return DelversAnklet
