local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local RingOfRespawn = ModalChoiceMenu:Extend("ringOfRespawn")

function RingOfRespawn:Define()
    return {
        title = "Respawn Points",
        background = cropped(
            backgrounds.runescapeSurface,
            { x = 0, y = 0, width = 400, height = 300 }
        ),
        icons = teleportIcons.ringOfRespawn,
        entries = {
            ["1. Lumbridge"] = {
                point = {x = 343, y = 177},
            },
            ["2. Falador"] = {
                point = {x = 271, y = 118},
            },
            ["3. Camelot"] = {
                point = {x = 216, y = 93},
            },
            ["4. Soul Wars"] = {
                point = {x = 58, y = 267},
            },
            ["5. Burthorpe"] = {
                point = {x = 257, y = 73},
            },
            ["6. Nowhere"] = {hidden = true},
        },
    }
end

return RingOfRespawn
