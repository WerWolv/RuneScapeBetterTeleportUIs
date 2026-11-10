local ChoiceV2Menu = require("impl/interfaces/native/choice_v2_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local ClanVexillum = MapMenu.Create(ChoiceV2Menu, "clanVexillum")

function ClanVexillum:Define()
    return {
        title = "Clan Portals",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.portal,
        noBackgroundCrop = true,
        entries = {
            ["1. Teleport to the clan camp at the Grand Exchange."] = {
                nameOverride = "Grand Exchange",
                point = {x = 335, y = 97},
            },
            ["2. Teleport to the clan portal in Prifddinas."] = {
                nameOverride = "Prifddinas",
                point = {x = 55, y = 123},
            },
            ["3. Cancel."] = {
                hidden = true
            }
        },
    }
end

return ClanVexillum
