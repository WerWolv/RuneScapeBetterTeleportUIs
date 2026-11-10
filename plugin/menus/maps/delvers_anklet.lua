local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local DelversAnklet = MapMenu.Create(ModalChoiceMenu, "delversAnklet")

function DelversAnklet:Define()
    return {
        title = "Delver's Anklet",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.jewellery.platinumDragonstone,
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
