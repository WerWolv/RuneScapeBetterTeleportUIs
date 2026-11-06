local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local resize = require("impl/utils").Resize

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
                nameOverride = "Amlodd",
                point = {x = 230, y = 63},
                icons = teleportIcons.elfClans.amlodd,
                hotkeyOffset = {x = 18, y = -10},
            },
            ["4. Cadarn (Prifddinas)"] = {
                nameOverride = "Cadarn",
                point = {x = 314, y = 99},
                icons = teleportIcons.elfClans.cadarn,
                hotkeyOffset = {x = 20, y = -10},
            },
            ["5. Crwys (Prifddinas)"] = {
                nameOverride = "Crwys",
                point = {x = 314, y = 63},
                icons = teleportIcons.elfClans.crwys,
                hotkeyOffset = {x = 20, y = -20},
            },
            ["6. Hefin (Prifddinas)"] = {
                nameOverride = "Hefin",
                point = {x = 254, y = 29},
                icons = teleportIcons.elfClans.hefin,
                hotkeyOffset = {x = 12, y = -20},
            },
            ["7. Iorwerth (Prifddinas)"] = {
                nameOverride = "Iorwerth",
                point = {x = 254, y = 133},
                icons = teleportIcons.elfClans.iorwerth,
                hotkeyOffset = {x = 12, y = -20},
            },
            ["8. Ithell (Prifddinas)"] = {
                nameOverride = "Ithell",
                point = {x = 230, y = 99},
                icons = teleportIcons.elfClans.ithell,
                hotkeyOffset = {x = 20, y = -10},
            },
            ["9. Meilyr (Prifddinas)"] = {
                nameOverride = "Meilyr",
                point = {x = 290, y = 29},
                icons = teleportIcons.elfClans.meilyr,
                hotkeyOffset = {x = 16, y = -20},
            },
            ["0. Trahaearn (Prifddinas)"] = {
                nameOverride = "Trahaearn",
                point = {x = 290, y = 133},
                icons = teleportIcons.elfClans.trahaearn,
                hotkeyOffset = {x = 8, y = -20},
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
                nameOverride = "Amlodd",
                point = {x = 230, y = 63},
                icons = resize(teleportIcons.elfClans.amlodd, 64),
                hotkeyOffset = {x = 20, y = -24},
            },
            ["2. Cadarn (Prifddinas)"] = {
                nameOverride = "Cadarn",
                point = {x = 314, y = 99},
                icons = resize(teleportIcons.elfClans.cadarn, 64),
                hotkeyOffset = {x = 24, y = -24},
            },
            ["3. Crwys (Prifddinas)"] = {
                nameOverride = "Crwys",
                point = {x = 314, y = 63},
                icons = resize(teleportIcons.elfClans.crwys, 64),
                hotkeyOffset = {x = 24, y = -24},
            },
            ["4. Hefin (Prifddinas)"] = {
                nameOverride = "Hefin",
                point = {x = 254, y = 39},
                icons = resize(teleportIcons.elfClans.hefin, 64),
                hotkeyOffset = {x = 24, y = -24},
            },
            ["5. Iorwerth (Prifddinas)"] = {
                nameOverride = "Iorwerth",
                point = {x = 254, y = 123},
                icons = resize(teleportIcons.elfClans.iorwerth, 64),
                hotkeyOffset = {x = 24, y = -24},
            },
            ["6. Ithell (Prifddinas)"] = {
                nameOverride = "Ithell",
                point = {x = 230, y = 99},
                icons = resize(teleportIcons.elfClans.ithell, 64),
                hotkeyOffset = {x = 24, y = -24},
            },
            ["7. Meilyr (Prifddinas)"] = {
                nameOverride = "Meilyr",
                point = {x = 290, y = 39},
                icons = resize(teleportIcons.elfClans.meilyr, 64),
                hotkeyOffset = {x = 24, y = -24},
            },
            ["8. Trahaearn (Prifddinas)"] = {
                nameOverride = "Trahaearn",
                point = {x = 290, y = 123},
                icons = resize(teleportIcons.elfClans.trahaearn, 64),
                hotkeyOffset = {x = 16, y = -24},
            },
        },
    }
end


return { CrystalTeleportSeed, CrystalTeleportSeedPrifddinas }
