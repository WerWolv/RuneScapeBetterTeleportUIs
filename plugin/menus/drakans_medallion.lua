local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local DrakansMedallion = ModalChoiceMenu:Extend("drakansMedallion")

-- Define Drakan's medallion destinations.
function DrakansMedallion:Define()
    return {
        title = "Drakan's Medallion",
        background = backgrounds.morytaniaSouth,
        icons = teleportIcons.drakansMedallion,
        entries = {
            ["1. Barrows"] = {point = {x = 408, y = 284}},
            ["2. Burgh de Rott"] = {point = {x = 249, y = 566}},
            ["3. Meiyerditch"] = {point = {x = 586, y = 445}},
            ["4. Darkmeyer"] = {point = {x = 552, y = 168}},
            ["5. Meiyerditch Laboratories"] = {point = {x = 595, y = 312}},
        },
    }
end

return DrakansMedallion
