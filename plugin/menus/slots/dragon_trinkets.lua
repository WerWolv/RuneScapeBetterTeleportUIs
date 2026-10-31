local NpcSlotMenu = require("impl/interfaces/npc_slot_menu")
local descriptions= require("definitions/descriptions")
local ChromaticDragonTrinkets = NpcSlotMenu:Extend("chromaticDragonTrinkets")
local MetallicDragonTrinkets = NpcSlotMenu:Extend("metallicDragonTrinkets")

local function description(location)

    return descriptions.Location(location)
end

function ChromaticDragonTrinkets:Define()
    return {
        title = "Chromatic Dragons",
        entries = {
            ["1. Green Dragons - Chaos Tunnels"] = {
                nameOverride = "Green Dragon",
                description = description("Chaos Tunnels"),
                npcID = id.NPC.GREEN_DRAGON5,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["2. Brutal Green Dragons - Baxtorian Falls"] = {
                nameOverride = "Brutal Green Dragon",
                description = description("Baxtorian Falls"),
                npcID = id.NPC.BRUT_GREEN_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["3. Blue Dragons - Taverley Dungeon"] = {
                nameOverride = "Blue Dragon",
                description = description("Taverley Dungeon"),
                npcID = id.NPC.BLUE_DRAGON4,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["4. Red Dragons - Brimhaven Dungeon"] = {
                nameOverride = "Red Dragon",
                description = description("Brimhaven Dungeon"),
                npcID = id.NPC.RED_DRAGON3,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["5. Black Dragons - Evil Chicken's Lair"] = {
                nameOverride = "Black Dragon",
                description = description("Evil Chicken's Lair Dungeon"),
                npcID = id.NPC.BLACK_DRAGON2,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["6. King Black Dragon - Edgeville"] = {
                nameOverride = "King Black Dragon",
                description = description("Edgeville"),
                npcID = id.NPC.KING_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_2012_KBD_READY,
                viewDistance = 3000,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["7. Queen Black Dragon - Grotworm Lair"] = {
                nameOverride = "Queen Black Dragon",
                description = description("Grotworm Lair"),
                npcID = id.NPC.QBD2_BOSS,
                animID = id.Seq.QBD2_QBD_READY,
                viewDistance = 6000,
                modelOffset = {
                    x = 0,
                    y = 50
                },
            },
            ["8. Cancel"] = {
                hidden = true
            },
        },
    }
end

function MetallicDragonTrinkets:Define()
    return {
        title = "Metallic Dragons",
        entries = {
            ["1. Bronze Dragons - Brimhaven Dungeon"] = {
                nameOverride = "Bronze Dragon",
                description = description("Brimhaven Dungeon"),
                npcID = id.NPC.BRONZE_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_METAL_DRAGON_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["2. Iron Dragons - Brimhaven Dungeon"] = {
                nameOverride = "Iron Dragon",
                description = description("Brimhaven Dungeon"),
                npcID = id.NPC.IRON_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_METAL_DRAGON_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["3. Steel Dragons - Brimhaven Dungeon"] = {
                nameOverride = "Steel Dragon",
                description = description("Brimhaven Dungeon"),
                npcID = id.NPC.STEEL_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_METAL_DRAGON_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["4. Mithril Dragons - Ancient Cavern"] = {
                nameOverride = "Mithril Dragon",
                description = description("Ancient Cavern"),
                npcID = id.NPC.BRUT_MITHRIL_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_METAL_DRAGON_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["5. Adamant Dragons - Brimhaven Adamant Dungeon"] = {
                nameOverride = "Adamant Dragon",
                description = description("Bimhaven Adamant Dungeon"),
                npcID = id.NPC.ADAMANT_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["6. Rune Dragons - World Gate"] = {
                nameOverride = "Rune Dragon",
                description = description("World Gate"),
                npcID = id.NPC.RUNE_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 75
                },
            },
            ["7. Cancel"] = {
                hidden = true
            },
        },
    }
end

return { ChromaticDragonTrinkets, MetallicDragonTrinkets }
