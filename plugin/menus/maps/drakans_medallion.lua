local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local DrakansMedallion = MapMenu.Create(ModalChoiceMenu, "drakansMedallion")

function DrakansMedallion:Define()
    return {
        title = "Drakan's Medallion",
        background = backgrounds.morytaniaSouth,
        noBackgroundCrop = true,
        icons = teleportIcons.drakansMedallion,
        entries = {
            ["1. Barrows"] = {
                id = "barrows",
                point = {x = 408, y = 284},
                hotkeyOffset = { x = 13, y = -18 },
            },
            ["2. Burgh de Rott"] = {
                id = "burghderott",
                point = {x = 249, y = 566},
                hotkeyOffset = { x = 13, y = -18 },
            },
            ["3. Meiyerditch"] = {
                id = "meiyerditch",
                point = {x = 586, y = 445},
                hotkeyOffset = { x = 13, y = -18 },
            },
            ["4. Darkmeyer"] = {
                id = "darkmeyer",
                point = {x = 552, y = 168},
                hotkeyOffset = { x = 13, y = -18 },
            },
            ["5. Meiyerditch Laboratories"] = {
                id = "laboratories",
                point = {x = 595, y = 312},
                hotkeyOffset = { x = 13, y = -18 },
            },
        },
    }
end

return DrakansMedallion
