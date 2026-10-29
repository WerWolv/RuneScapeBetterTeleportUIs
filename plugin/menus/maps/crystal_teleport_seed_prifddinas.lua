local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local resize = require("definitions/artwork_variants").Resize
local CrystalTeleportSeedPrifddinas = ModalChoiceMenu:Extend("crystalTeleportSeedPrifddinas")

function CrystalTeleportSeedPrifddinas:Define()
    return {
        title = "Prifddinas",
        background = backgrounds.prifddinas,
        entries = {
            ["1. Amlodd (Prifddinas)"] = {
                point = {x = 230, y = 63},
                icons = resize(teleportIcons.elfClans.amlodd, 64),
            },
            ["2. Cadarn (Prifddinas)"] = {
                point = {x = 314, y = 99},
                icons = resize(teleportIcons.elfClans.cadarn, 64),
            },
            ["3. Crwys (Prifddinas)"] = {
                point = {x = 314, y = 63},
                icons = resize(teleportIcons.elfClans.crwys, 64),
            },
            ["4. Hefin (Prifddinas)"] = {
                point = {x = 254, y = 39},
                icons = resize(teleportIcons.elfClans.hefin, 64),
            },
            ["5. Iorwerth (Prifddinas)"] = {
                point = {x = 254, y = 123},
                icons = resize(teleportIcons.elfClans.iorwerth, 64),
            },
            ["6. Ithell (Prifddinas)"] = {
                point = {x = 230, y = 99},
                icons = resize(teleportIcons.elfClans.ithell, 64),
            },
            ["7. Meilyr (Prifddinas)"] = {
                point = {x = 290, y = 39},
                icons = resize(teleportIcons.elfClans.meilyr, 64),
            },
            ["8. Trahaearn (Prifddinas)"] = {
                point = {x = 290, y = 123},
                icons = resize(teleportIcons.elfClans.trahaearn, 64),
            },
        },
    }
end

return CrystalTeleportSeedPrifddinas
