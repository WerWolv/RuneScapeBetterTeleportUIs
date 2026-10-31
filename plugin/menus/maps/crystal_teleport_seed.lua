local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local resize = require("definitions/artwork_variants").Resize

local CrystalTeleportSeed = ModalChoiceMenu:Extend("crystalTeleportSeed")
local CrystalTeleportSeedPrifddinas = ModalChoiceMenu:Extend("crystalTeleportSeedPrifddinas")

function CrystalTeleportSeed:Define()
    return {
        title = "Tirannwn",
        background = backgrounds.tirannwn,
        noBackgroundCrop = true,
        entries = {
            ["1. Lletya"] = {
                point = {x = 348, y = 207},
                icons = teleportIcons.elfcityTeleport[0],
            },
            ["2. Temple of Light"] = {
                point = {x = 430, y = 125},
                icons = teleportIcons.elfcityTeleport[4],
            },
            -- Clan icons occupy the eight compass sectors around (272, 81), radius 46.
            ["3. Amlodd (Prifddinas)"] = {
                point = {x = 230, y = 63},
                icons = teleportIcons.elfClans.amlodd,
            },
            ["4. Cadarn (Prifddinas)"] = {
                point = {x = 314, y = 99},
                icons = teleportIcons.elfClans.cadarn,
            },
            ["5. Crwys (Prifddinas)"] = {
                point = {x = 314, y = 63},
                icons = teleportIcons.elfClans.crwys,
            },
            ["6. Hefin (Prifddinas)"] = {
                point = {x = 254, y = 39},
                icons = teleportIcons.elfClans.hefin,
            },
            ["7. Iorwerth (Prifddinas)"] = {
                point = {x = 254, y = 123},
                icons = teleportIcons.elfClans.iorwerth,
            },
            ["8. Ithell (Prifddinas)"] = {
                point = {x = 230, y = 99},
                icons = teleportIcons.elfClans.ithell,
            },
            ["9. Meilyr (Prifddinas)"] = {
                point = {x = 290, y = 39},
                icons = teleportIcons.elfClans.meilyr,
            },
            ["0. Trahaearn (Prifddinas)"] = {
                point = {x = 290, y = 123},
                icons = teleportIcons.elfClans.trahaearn,
            },
        },
    }
end

function CrystalTeleportSeedPrifddinas:Define()
    return {
        title = "Prifddinas",
        background = backgrounds.prifddinas,
        noBackgroundCrop = true,
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


return { CrystalTeleportSeed, CrystalTeleportSeedPrifddinas }
