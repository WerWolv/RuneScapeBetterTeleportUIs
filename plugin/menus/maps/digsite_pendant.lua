local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local DigsitePendant = MapMenu.Create(ModalChoiceMenu, "digsitePendant")

function DigsitePendant:Define()
    return {
        title = "Digsite",
        background = backgrounds.digsite,
        icons = teleportIcons.jewellery.goldRuby,
        noBackgroundCrop = true,
        entries = {
            ["1. Varrock Dig Site."] = {
                nameOverride = "Varrock Dig Site",
                point = {x = 220, y = 260},
            },
            ["2. Senntisten Temple."] = {
                nameOverride = "Senntisten Temple",
                point = {x = 322, y = 44},
            },
            ["3. Exam Centre."] = {
                nameOverride = "Exam Centre",
                point = {x = 255, y = 508},
            }
        },
    }
end

return DigsitePendant
