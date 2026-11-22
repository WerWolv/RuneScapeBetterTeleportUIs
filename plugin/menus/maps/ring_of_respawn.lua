local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local RingOfRespawn = MapMenu.Create(ModalChoiceMenu, "ringOfRespawn")

function RingOfRespawn:Define()
    return {
        title = "Respawn Points",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.jewellery.silverJade,
        entries = {
            ["1. Lumbridge"] = {
                id = "lumbridge",
                point = {x = 343, y = 177},
            },
            ["2. Falador"] = {
                id = "falador",
                point = {x = 271, y = 118},
            },
            ["3. Camelot"] = {
                id = "camelot",
                point = {x = 216, y = 93},
            },
            ["4. Soul Wars"] = {
                id = "soulwars",
                point = {x = 58, y = 267},
            },
            ["5. Burthorpe"] = {
                id = "burthorpe",
                point = {x = 257, y = 73},
            },
            ["6. Nowhere"] = {hidden = true},
        },
    }
end

return RingOfRespawn
