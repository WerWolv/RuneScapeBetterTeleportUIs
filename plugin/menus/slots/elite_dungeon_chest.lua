local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local ModelSlotMenu = require("impl/interfaces/presentations/model_slot_menu")
local EliteDungeonChest = ModelSlotMenu.Create(ModalChoiceMenu, "eliteDungeonChest")

function EliteDungeonChest:Define()
    return {
        title = "Elite Dungeons",
        minimumMatches = 3,
        showTitle = false,
        columns = 4,
        rows = 1,
        entries = {
            ["^%d%. Temple of Aminishi"] = {
                nameOverride = "Temple of Aminishi",
                position = 1,
                possiblyMissing = true,
                npcID = id.NPC.DUNGEON_AMINISHI_BOSS3_NORMAL,
                animID = id.Seq.DUNGEON_AMINISHI_EVIL_SEIRYU_HEAD_IDLE,
                viewDistance = 5500,
                modelOffset = {
                    x = 0,
                    y = 90
                },
            },
            ["^%d%. Dragonkin Laboratory"] = {
                nameOverride = "Dragonkin Laboratory",
                position = 2,
                possiblyMissing = true,
                npcID = id.NPC.DUNGEON_DRAGONFORT_BOSS3,
                animID = id.Seq.DUNGEON_WILDERNESS_ASTELLARN_IDLE,
                viewDistance = 2500,
                modelOffset = {
                    x = 0,
                    y = 60
                },
            },
            ["^%d%. The Shadow Reef"] = {
                nameOverride = "Shadow Reef",
                position = 3,
                possiblyMissing = true,
                npcID = id.NPC.DUNGEON_ULTHVEN_BOSS3,
                animID = id.Seq.DUNGEON_ULTHVEN_AMBASSADOR_IDLE,
                viewDistance = 1200,
                modelOffset = {
                    x = 0,
                    y = 230
                },
            },
            ["^%d%. The Zamorakian Undercity"] = {
                nameOverride = "Zamorakian Undercity",
                position = 4,
                possiblyMissing = true,
                npcID = id.NPC.EGWD_ZAMORAK_BOSS,
                animID = id.Seq.ZAMORAK_IDLE,
                viewDistance = 2000,
                modelOffset = {
                    x = 0,
                    y = 210
                },
            },
        },
    }
end

return EliteDungeonChest
