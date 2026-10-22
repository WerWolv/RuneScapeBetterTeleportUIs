local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local utils = require("impl/utils")

function resize(icon, newSize)
    local result = utils.deepcopy(icon)
    result.size = newSize

    return result
end

return {
    wildernessObelisks = {
        title = "Wilderness Obelisks",
        background = backgrounds.wilderness,
        icons = teleportIcons.obelisk,
        entries = {
            ["1. Level 13 Wilderness"] = {
                nameOverride = "Wilderness Lodestone",
                point = {x = 382, y = 708},
            },
            ["2. Level 18 Wilderness"] = {
                nameOverride = "Graveyard of Shadows",
                point = {x = 492, y = 646},
            },
            ["3. Level 27 Wilderness"] = {
                nameOverride = "Chaos Ridge",
                point = {x = 171, y = 512},
            },
            ["4. Level 35 Wilderness"] = {
                nameOverride = "Lava Maze",
                point = {x = 294, y = 405},
            },
            ["5. Level 44 Wilderness"] = {
                nameOverride = "Frozen Waste Plateau",
                point = {x = 75, y = 279},
            },
            ["6. Level 50 Wilderness"] = {
                nameOverride = "Rogues' Castle",
                point = {x = 645, y = 192},
            },
        },
    },
    wildernessSword1 = {
        title = "Wilderness",
        background = backgrounds.wildernessWest,
        icons = teleportIcons.obelisk,
        entries = {
            ["1. Teleport to Edgeville"] = {
                nameOverride = "Edgeville",
                point = {x = 263, y = 825},
            },
            ["2. Teleport to Herb patch"] = {
                nameOverride = "Herb patch",
                point = {x = 359, y = 355},
            }
        },
    },
    wildernessSword23 = {
        title = "Wilderness",
        background = backgrounds.wildernessWest,
        icons = teleportIcons.obelisk,
        entries = {
            ["1. Teleport to Edgeville"] = {
                nameOverride = "Edgeville",
                point = {x = 263, y = 825},
            },
            ["2. Teleport to Herb patch"] = {
                nameOverride = "Herb patch",
                point = {x = 359, y = 355},
            },
            ["3. Teleport to Forinthry Dungeon"] = {
                nameOverride = "Forinthry Dungeon",
                point = {x = 237, y = 667},
            }
        },
    },
    wildernessSword4 = {
        title = "Wilderness",
        background = backgrounds.wildernessWest,
        icons = teleportIcons.obelisk,
        entries = {
            ["1. Teleport to Edgeville"] = {
                nameOverride = "Edgeville",
                point = {x = 263, y = 825},
            },
            ["2. Teleport to Herb patch"] = {
                nameOverride = "Herb patch",
                point = {x = 359, y = 355},
            },
            ["3. Teleport to Forinthry Dungeon"] = {
                nameOverride = "Forinthry Dungeon",
                point = {x = 237, y = 667},
            },
            ["4. Teleport to Wilderness Agility course"] = {
                nameOverride = "Wilderness Agility course",
                point = {x = 106, y = 192},
            }
        },
    },
    drakansMedallion = {
        title = "Drakan's Medallion",
        background = backgrounds.morytaniaSouth,
        icons = teleportIcons.drakansMedallion,
        entries = {
            ["1. Barrows"] = {
                point = {x = 408, y = 284}
            },
            ["2. Burgh de Rott"] = {
                point = {x = 249, y = 566}
            },
            ["3. Meiyerditch"] = {
                point = {x = 586, y = 445}
            },
            ["4. Darkmeyer"] = {
                point = {x = 552, y = 168}
            },
            ["5. Meiyerditch Laboratories"] = {
                point = {x = 595, y = 312}
            },
        },
    },
    ringOfDuelling = {
        title = "Ring of Duelling",
        background = backgrounds.runescapeSurfaceSouth,
        entries = {
            ["1. Het's Oasis"] = {
                icons = teleportIcons.relicOfHet,
                point = {x = 369, y = 161},
            },
            ["2. Castle Wars Arena"] = {
                icons = teleportIcons.castleWarsCape,
                point = {x = 110, y = 199},
            },
            ["3. The Warforge"] = {
                icons = teleportIcons.warForgeShield,
                point = {x = 112, y = 276},
            },
            ["4. Fist of Guthix"] = {
                icons = teleportIcons.fistOfGuthixOrb,
                point = {x = 283, y = 111},
            },
            ["5. Nowhere"] = {hidden = true},
        },
    },
    gamesNecklace = {
        title = "Games necklace",
        background = backgrounds.runescapeSurfaceCenter,
        entries = {
            ["1. Troll Invasion"] = {
                point = { x = 247, y = 41 },
                icons = teleportIcons.trollInvasion
            },
            ["2. Barbarian Outpost"] = {
                point = { x = 147, y = 69 },
                icons = teleportIcons.horn
            },
            ["3. Gamer's Grotto"] = {
                point = {x = 283, y = 111},
                icons = teleportIcons.dice
            },
            ["4. Agoroth"] = {
                point = {x = 110, y = 304},
                icons = teleportIcons.squid
            },
            ["5. Corporeal Beast"] = {
                point = {x = 326, y = 30},
                icons = teleportIcons.corporealBeast,
            },
            ["6. Burgh De Rott"] = {
                point = {x = 432, y = 165},
                icons = teleportIcons.sickle
            },
            ["7. Tears of Guthix"] = {
                point = {x = 341, y = 178},
                icons = teleportIcons.tearsOfGuthix
            }
        }
    },
    crystalTeleportSeed = {
        title = "Tirannwn",
        background = backgrounds.tirannwn,
        entries = {
            ["1. Lletya"] = { 
                point = { x = 348, y = 207 },
                icons = teleportIcons.elfcityTeleport[0]
            },
            ["2. Temple of Light"] = {
                point = { x = 430, y = 125 },
                icons = teleportIcons.elfcityTeleport[4]
            },

            -- Clan icons occupy the eight compass sectors around (272, 81), radius 46.
            ["3. Amlodd (Prifddinas)"] = {
                point = { x = 230, y = 63 },
                icons = teleportIcons.elfClans.amlodd
            },
            ["4. Cadarn (Prifddinas)"] = {
                point = { x = 314, y = 99 },
                icons = teleportIcons.elfClans.cadarn
            },
            ["5. Crwys (Prifddinas)"] = {
                point = { x = 314, y = 63 },
                icons = teleportIcons.elfClans.crwys
            },
            ["6. Hefin (Prifddinas)"] = {
                point = { x = 254, y = 39 },
                icons = teleportIcons.elfClans.hefin
            },
            ["7. Iorwerth (Prifddinas)"] = {
                point = { x = 254, y = 123 },
                icons = teleportIcons.elfClans.iorwerth
            },
            ["8. Ithell (Prifddinas)"] = {
                point = { x = 230, y = 99 },
                icons = teleportIcons.elfClans.ithell
            },
            ["9. Meilyr (Prifddinas)"] = {
                point = { x = 290, y = 39 },
                icons = teleportIcons.elfClans.meilyr
            },
            ["0. Trahaearn (Prifddinas)"] = {
                point = { x = 290, y = 123 },
                icons = teleportIcons.elfClans.trahaearn
            },
        }
    },
    crystalTeleportSeedPrifddinas = {
        title = "Prifddinas",
        background = backgrounds.prifddinas,
        entries = {
            ["1. Amlodd (Prifddinas)"] = {
                point = { x = 230, y = 63 },
                icons = resize(teleportIcons.elfClans.amlodd, 64)
            },
            ["2. Cadarn (Prifddinas)"] = {
                point = { x = 314, y = 99 },
                icons = resize(teleportIcons.elfClans.cadarn, 64)
            },
            ["3. Crwys (Prifddinas)"] = {
                point = { x = 314, y = 63 },
                icons = resize(teleportIcons.elfClans.crwys, 64)
            },
            ["4. Hefin (Prifddinas)"] = {
                point = { x = 254, y = 39 },
                icons = resize(teleportIcons.elfClans.hefin, 64)
            },
            ["5. Iorwerth (Prifddinas)"] = {
                point = { x = 254, y = 123 },
                icons = resize(teleportIcons.elfClans.iorwerth, 64)
            },
            ["6. Ithell (Prifddinas)"] = {
                point = { x = 230, y = 99 },
                icons = resize(teleportIcons.elfClans.ithell, 64)
            },
            ["7. Meilyr (Prifddinas)"] = {
                point = { x = 290, y = 39 },
                icons = resize(teleportIcons.elfClans.meilyr, 64)
            },
            ["8. Trahaearn (Prifddinas)"] = {
                point = { x = 290, y = 123 },
                icons = resize(teleportIcons.elfClans.trahaearn, 64)
            },
        }
    },
    passingBracelet = {
        title = "Underworld",
        background = backgrounds.city_of_um,
        entries = {
            ["1. City of Um: Hanging Gardens"] = {
                nameOverride = "Hanging Gardens",
                point = { x = 737, y = 464 },
                icons = teleportIcons.elfcityTeleport[1],
            },
            ["2. City of Um: Haunt on the Hill"] = {
                nameOverride = "Haunt on the Hill",
                point = { x = 709, y = 223 },
                icons = teleportIcons.elfcityTeleport[0],
            },
            ["3. City of Um: Reflection Pool"] = {
                nameOverride = "Reflection Pool",
                point = { x = 555, y = 800 },
                icons = teleportIcons.elfcityTeleport[3],
            },
            ["4. Nowhere"] = {
                hidden = true
            }
        }
    },
    underworldGrimoire23 = {
        title = "Underworld",
        background = backgrounds.city_of_um,
        icons = teleportIcons.underworldTeleport,
        entries = {
            ["1. Teleport to Um Smithy"] = {
                nameOverride = "Um Smithy",
                point = { x = 616, y = 377 }
            },
            ["2. Teleport to Um Ritual Site"] = {
                nameOverride = "Um Ritual Site",
                point = { x = 96, y = 590 }
            },
            ["3. Teleport to Ungael Ritual Site"] = {
                nameOverride = "Ungael Ritual Site",
                point = { x = 170, y = 165 },
                icons = teleportIcons.ungaelTeleport
            }
        }
    },
    underworldGrimoire4 = {
        title = "Underworld",
        background = backgrounds.city_of_um,
        entries = {
            ["1. Teleport to Um Smithy"] = {
                nameOverride = "Um Smithy",
                point = { x = 616, y = 377 },
                icons = teleportIcons.umSmithyTeleport
            },
            ["2. Teleport to Um Ritual Site"] = {
                nameOverride = "Um Ritual Site",
                point = { x = 96, y = 590 },
                icons = teleportIcons.underworldTeleport,
            },
            ["3. Teleport to Ungael Ritual Site"] = {
                nameOverride = "Ungael Ritual Site",
                point = { x = 170, y = 165 },
                icons = teleportIcons.ungaelTeleport
            },
            ["4. Teleport to Lupe"] = {
                nameOverride = "Lupe",
                point = { x = 371, y = 417 },
                icons = teleportIcons.lupeTeleport
            }
        }
    },
    leelasFavour = {
        title = "Menaphos",
        background = backgrounds.menaphos,
        entries = {
            ["1. Imperial District"] = {
                point = { x = 402, y = 409 },
                icons = teleportIcons.menaphosFactions.imperial
            },
            ["2. Merchant District"] = {
                point = { x = 573, y = 213 },
                icons = teleportIcons.menaphosFactions.merchant
            },
            ["3. Port District"] = {
                point = { x = 544, y = 778 },
                icons = teleportIcons.menaphosFactions.port
            },
            ["4. Worker District"] = {
                point = { x = 336, y = 168 },
                icons = teleportIcons.menaphosFactions.worker
            },
            ["5. Soul Obelisk"] = {
                point = { x = 92, y = 770 },
                hidden = true
            },
            ["6. Shifting Tombs"] = {
                point = { x = 597, y = 409 },
                icons = teleportIcons.shiftingTombs
            },
            ["7. Sophanem Slayer Dungeon"] = {
                point = { x = 825, y = 494 },
                icons = teleportIcons.sophanemSlayerDungeon
            }
        }
    },
    bigBookOPiracy = {
        title = "Pirate Islands",
        background = backgrounds.pirate_islands,
        icons = teleportIcons.bigBookOPiracy,
        entries = {
            ["1. Mos Le'Harmless."] = {
                nameOverride = "Mos Le'Harmless",
                point = { x = 120, y = 426 }
            },
            ["2. Braindeath Island."] = {
                nameOverride = "Braindeath Island",
                point = { x = 710, y = 487 }
            },
            ["3. Dragontooth Isle."] = {
                nameOverride = "Dragontooth Isle",
                point = { x = 550, y = 58 }
            },
            ["4. Harmony Island."] = {
                nameOverride = "Harmony Island",
                point = { x = 377, y = 728 }
            }
        }
    },

    
}
