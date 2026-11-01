local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local TokKulZo = ModalChoiceMenu:Extend("tokKulZo")

function TokKulZo:Define()
    return {
        title = "TzHaar City",
        background = backgrounds.tzhaarCity,
        icons = teleportIcons.tokKulZo,
        noBackgroundCrop = true,
        entries = {
            ["1. Main Plaza"] = {
                point = {x = 512, y = 116},
            },
            ["2. Fight Pit"] = {
                point = {x = 211, y = 481},
            },
            ["3. Fight Cave"] = {
                point = {x = 276, y = 224},
            },
            ["4. Fight Kiln"] = {
                point = {x = 800, y = 90},
            },
            ["5. Fight Cauldron"] = {
                point = {x = 972, y = 250},
            },
            ["6. Nowhere"] = {hidden = true},
        },
    }
end

return TokKulZo
