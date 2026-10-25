local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local DungeoneeringCapePage1 = ModalChoiceMenu:Extend("dungeoneeringCapePage1")
local DungeoneeringCapePage2 = ModalChoiceMenu:Extend("dungeoneeringCapePage2")
local DungeoneeringCapePage3 = ModalChoiceMenu:Extend("dungeoneeringCapePage3")

local function description(level, location)
    return descriptions.LevelRequirement(level, descriptions.SKILL.DUNGEONEERING) .. 
           descriptions.Location(location)
end

-- Define ring of duelling destinations and its hidden cancel option.
function DungeoneeringCapePage1:Define()
    return {
        title = "Resource Dungeons",
        background = backgrounds.runescapeSurface,
        entries = {
            ["1. Edgeville Dungeon chaos druids dungeon"] = {
                nameOverride = "Chaos druids dungeon",
                description = description(10, "Edgeville Dungeon"),
                point = {x = 304, y = 87},
                icons = teleportIcons.dungeoneeringDungeon.frozen,
            },
            ["2. Dwarven mine hidden mine"] = {
                point = {x = 270, y = 88},
                nameOverride = "Hidden mine",
                description = description(15, "Dwarven mine"),

                icons = teleportIcons.dungeoneeringDungeon.frozen
            },
            ["3. Edgeville hill giant dungeon"] = {
                nameOverride = "Hill giant dungeon",
                description = description(20, "Edgeville Dungeon"),

                point = {x = 335, y = 104},
                icons = teleportIcons.dungeoneeringDungeon.frozen
            },
            ["4. Karamja Volcano lesser demon dungeon"] = {
                nameOverride = "Lesser demon dungeon",
                description = description(25, "Karamja Volcano"),

                point = {x = 236, y = 179},
                icons = teleportIcons.dungeoneeringDungeon.abandoned
            },
            ["5. Daemonheim woodcutting island dungeon"] = {
                nameOverride = "Woodcutting island dungeon",
                description = description(30, "Daemonheim Peninsula"),
                point = {x = 424, y = 51},
                icons = teleportIcons.dungeoneeringDungeon.abandoned
            },
            ["6. Waterfall fire giant dungeon"] = {
                nameOverride = "Fire giant dungeon",
                description = description(35, "Baxtorian Falls Cave"),
                point = {x = 142, y = 97},
                icons = teleportIcons.dungeoneeringDungeon.furnished
            },
            ["7. Mining Guild hidden mine"] = {
                nameOverride = "Mining Guild",
                description = description(45, "Dwarven mine"),
                point = {x = 288, y = 130},
                icons = teleportIcons.dungeoneeringDungeon.furnished
            },
            ["8. Braindeath Island"] = {
                nameOverride = "'Rum'-geon",
                description = description(50, "Braindeath Island"),               
                point = {x = 457, y = 273},
                icons = teleportIcons.dungeoneeringDungeon.furnished
            },
            ["9. Taverley hellhound dungeon"] = {
                nameOverride = "Hellhound Dungeon",
                description = description(55, "Taverley Dungeon"),
                point = {x = 242, y = 116},
                icons = teleportIcons.dungeoneeringDungeon.furnished
            },
            ["0. More..."] = {
                nameOverride = "Next",
                icons = teleportIcons.nextArrow,
                point = {x = 560 - 24, y = 290},
            }
        },
    }
end

function DungeoneeringCapePage2:Define()
    return {
        title = "Resource Dungeons",
        background = backgrounds.runescapeSurface,
        entries = {
            ["1. Taverley blue dragon dungeon"] = {
                nameOverride = "Blue dragon dungeon",
                description = description(60, "Taverley Dungeon"),
                point = {x = 252, y = 116},
                icons = teleportIcons.dungeoneeringDungeon.abandoned
            },
            ["2. Varrock moss giant dungeon"] = {
                nameOverride = "Moss giant dungeon",
                description = description(65, "Varrock Sewers"),
                point = {x = 342, y = 94},
                icons = teleportIcons.dungeoneeringDungeon.abandoned
            },
            ["3. Dragontooth celestial dragon dungeon"] = {
                nameOverride = "Celestial dragon dungeon",
                description = description(67, "Dragontooth Isle"),
                point = {x = 501, y = 69},
                icons = teleportIcons.dungeoneeringDungeon.abandoned
            },
            ["4. Chaos Tunnels black demon dungeon"] = {
                nameOverride = "Black demon dungeon",
                description = description(70, "Chaos Tunnels"),
                point = {x = 292, y = 59},
                icons = teleportIcons.dungeoneeringDungeon.occult
            },
            ["5. Al Kharid hidden mine"] = {
                nameOverride = "Hidden mine",
                description = description(75, "Al Kharid Mine"),
                point = {x = 369, y = 148},
                icons = teleportIcons.dungeoneeringDungeon.occult
            },
            ["6. Brimhaven metal dragon dungeon"] = {
                nameOverride = "Metal Dragon Dungeon",
                description = description(80, "Brimhaven Dungeon"),
                point = {x = 207, y = 183},
                icons = teleportIcons.dungeoneeringDungeon.occult
            },
            ["7. Polypore Dungeon"] = {
                nameOverride = "Polypore Dungeon",
                description = description(82, "Polypore Dungeon"),
                point = {x = 398, y = 134},
                icons = teleportIcons.dungeoneeringDungeon.occult
            },
            ["8. Ice Dungeon frost dragon dungeon"] = {
                nameOverride = "Frost dragon dungeon",
                description = description(85, "Ice Dungeon"),
                point = {x = 280, y = 194},
                icons = teleportIcons.dungeoneeringDungeon.occult
            },
            ["9. Kal'gerion demon dungeon"] = {
                nameOverride = "Kal'gerion demon dungeon",
                description = description(90, "Daemonheim Peninsula"),
                point = {x = 394, y = 35},
                icons = teleportIcons.dungeoneeringDungeon.occult
            },
            ["0. More..."] = {
                nameOverride = "Next",
                icons = teleportIcons.nextArrow,
                point = {x = 560 - 24, y = 290},
            }
        },
    }
end

function DungeoneeringCapePage3:Define()
    return {
        title = "Resource Dungeons",
        background = backgrounds.runescapeSurface,
        entries = {
            ["1. Gorajo hoardstalker dungeon"] = {
                nameOverride = "Gorajo hoardstalker dungeon",
                description = description(95, "Prifddinas"),
                point = {x = 71, y = 146},
                icons = teleportIcons.dungeoneeringDungeon.warped
            },
            ["2. Morytania slayer tower dungeon"] = {
                nameOverride = "Slayer tower dungeon",
                description = description(100, "Morytania"),
                point = {x = 413, y = 74},
                icons = teleportIcons.dungeoneeringDungeon.warped
            },
            ["3. Edimmu dungeon"] = {
                nameOverride = "Edimmu dungeon",
                description = description(115, "Prifddinas"),
                point = {x = 61, y = 109},
                icons = teleportIcons.dungeoneeringDungeon.warped
            },
            ["4. Back"] = {
                nameOverride = "Next",
                icons = teleportIcons.nextArrow,
                point = {x = 560 - 24, y = 290},
            }
        },
    }
end

return { DungeoneeringCapePage1, DungeoneeringCapePage2, DungeoneeringCapePage3 }
