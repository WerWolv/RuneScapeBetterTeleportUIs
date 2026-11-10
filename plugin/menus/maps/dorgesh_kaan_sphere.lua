local ChoiceV2Menu = require("impl/interfaces/native/choice_v2_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local DorgeshKaanSphere = MapMenu.Create(ChoiceV2Menu, "dorgeshKaanSphere")

function DorgeshKaanSphere:Define()
    return {
        title = "Dorgesh-kaan",
        background = backgrounds.dorgeshKaan,
        sizeMultiplier = 1.5,
        noBackgroundCrop = true,
        vignette = false,
        icons = teleportIcons.dorgeshKaanSphere,
        entries = {
            ["1. Dorgesh-kaan North"] = {
                nameOverride = "North",
                point = {x = 220, y = 115},
            },
            ["2. Dorgesh-kaan South"] = {
                nameOverride = "South",
                point = {x = 223, y = 539},
            },
            ["3. Dorgesh-kaan East"] = {
                nameOverride = "East",
                point = {x = 241, y = 311},
            },
            ["4. Dorgesh-kaan West"] = {
                nameOverride = "West",
                point = {x = 116, y = 349},
            },
        },
    }
end

return DorgeshKaanSphere
