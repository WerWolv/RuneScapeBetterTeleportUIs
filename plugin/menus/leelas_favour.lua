local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local LeelasFavour = ModalChoiceMenu:Extend("leelasFavour")

-- Define Leela's favour destinations and its hidden Soul Obelisk entry.
function LeelasFavour:Define()
    return {
        title = "Menaphos",
        background = backgrounds.menaphos,
        entries = {
            ["1. Imperial District"] = {
                point = {x = 402, y = 409},
                icons = teleportIcons.menaphosFactions.imperial,
            },
            ["2. Merchant District"] = {
                point = {x = 573, y = 213},
                icons = teleportIcons.menaphosFactions.merchant,
            },
            ["3. Port District"] = {
                point = {x = 544, y = 778},
                icons = teleportIcons.menaphosFactions.port,
            },
            ["4. Worker District"] = {
                point = {x = 336, y = 168},
                icons = teleportIcons.menaphosFactions.worker,
            },
            ["5. Soul Obelisk"] = {
                point = {x = 92, y = 770},
                hidden = true,
            },
            ["6. Shifting Tombs"] = {
                point = {x = 597, y = 409},
                icons = teleportIcons.shiftingTombs,
            },
            ["7. Sophanem Slayer Dungeon"] = {
                point = {x = 825, y = 494},
                icons = teleportIcons.sophanemSlayerDungeon,
            },
        },
    }
end

return LeelasFavour
