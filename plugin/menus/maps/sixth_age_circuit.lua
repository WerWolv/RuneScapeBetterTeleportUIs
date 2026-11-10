local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local descriptions = require("definitions/descriptions")
local teleportIcons = require("definitions/teleport_icons")
local SixthAgeCircuit = MapMenu.Create(ModalChoiceMenu, "sixthAgeCircuit")

function SixthAgeCircuit:Define()
    return {
        title = "Sixth-Age Circuit",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.sixthAgeCircuit,
        entries = {
            ["1. Guthix's shrine"] = {
                description =
                    descriptions.Location("Legends Guild, Ardougne") ..
                    descriptions.Text("Automatons"),
                point = {x = 190, y = 130}
            },
            ["2. World Gate"] = {
                showLockWhenDisabled = true,
                description =
                    descriptions.Location("West of the Arandar Pass Gate"),
                point = {x = 100, y = 125}
            },
            ["3. Guthix memorial"] = {
                nameOverride = "Memorial to Guthix",
                description =
                    descriptions.Location("Piscatoris") ..
                    descriptions.Text("Hall of Memories"),
                point = {x = 75, y = 70}
            },
            ["4. Guthix temple (Tormented Demons)"] = {
                nameOverride = "Guthix temple",
                description =
                    descriptions.Location("Chasm of Tears, Lumbridge") ..
                    descriptions.Text("Tormented Demons"),
                point = {x = 340, y = 180}
            },
            ["5. Nowhere"] = {hidden = true},
        },
    }
end

return SixthAgeCircuit
