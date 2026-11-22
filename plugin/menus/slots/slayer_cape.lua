local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local ModelSlotMenu = require("impl/interfaces/presentations/model_slot_menu")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local SlayerCapePage1 = ModelSlotMenu.Create(ModalChoiceMenu, "slayerCapePage1")
local SlayerCapePage2 = ModelSlotMenu.Create(ModalChoiceMenu, "slayerCapePage2")

local distance = 400
local offset = {
    x = 0,
    y = 280,
}

local function description(slayerLevel, combatLevel, location)
    local result = ""

    if slayerLevel > 0 then
        result = result .. descriptions.LevelRequirement(slayerLevel, descriptions.SKILL.SLAYER)
    end

    if combatLevel > 0 then
        result = result .. descriptions.CombatLevel(combatLevel)
    end

    return result .. descriptions.Location(location)
end

function SlayerCapePage1:Define()
    return {
        title = "Slayer Masters",
        showTitle = false,
        entries = {
            ["1. Mandrith"] = {
                id = "mandrith",
                npcID = id.NPC.BOUNTY_MANDRITH,
                animID = id.Seq.HUMAN_READY,
                viewDistance = 500,
                modelOffset = {
                    x = 0,
                    y = 250
                },
                description = description(95, 120, "Level 55 " .. descriptions.Sprite(id.Sprite.HEADICONS_PK_INTERFACE_7) .. " Wilderness")
            },
            ["2. Laniakea"] = {
                id = "laniakea",
                npcID = id.NPC.SLAYER_MASTER_8_DINO_ISLAND,
                animID = id.Seq.DINO_SLAYER_MASTER_IDLE,
                viewDistance = distance,
                modelOffset = offset,
                description = description(90, 120, "Xolo City, Anachronia")
            },
            ["3. Morvran"] = {
                id = "morvran",
                npcID = id.NPC.SLAYER_MASTER_7_IORWERTH,
                animID = id.Seq.ELF_2014_SLAYER_MASTER_IDLE,
                viewDistance = distance,
                modelOffset = {
                    x = 0,
                    y = 240
                },
                description = description(85, 120, "Iorwerth Clan, Prifddinas")
            },
            ["4. Kuradal"] = {
                id = "kuradal",
                npcID = id.NPC.SLAYER_MASTER_6_KURADAL,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(75, 110, "Ancient Cavern")
            },
            ["5. Lapalok"] = {
                id = "lapalok",
                npcID = id.NPC.SLAYER_MASTER_5_LAPALOK,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(85, 100, "Shilo Village, Karamja")
            },
            ["5. Duradel"] = {
                id = "duradel",
                npcID = id.NPC.SLAYER_MASTER_5_DURADEL,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(85, 100, "Shilo Village, Karamja")
            },
            ["6. Sumona"] = {
                id = "sumona",
                npcID = id.NPC.SMKI_SUMONA,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(35, 90, "Pollnivneach, Kharidian Desert")
            },
            ["7. Chaeldar"] = {
                id = "chealdar",
                npcID = id.NPC.SLAYER_MASTER_4,
                animID = id.Seq.FAIRYKIT_FAIRY_QUEEN_READY,
                viewDistance = distance,
                modelOffset = {
                    x = 0,
                    y = 300,
                },
                description = description(0, 75, "Zanaris")
            },
            ["8. Mazchna"] = {
                id = "mazchna",
                npcID = id.NPC.SLAYER_MASTER_2_MAZCHNA,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(0, 50, "Canifis, Morytania")
            },
            ["9. The Raptor"] = {
                id = "raptor",
                npcID = id.NPC.SLAYER_MASTER_2A_FORT_SLAYER,
                animID = id.Seq.SIGHERO_RAPTOR_CASUAL_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(10, 35, "Fort Forinthry")
            },
            ["0. Next page"] = {
                id = "next",
                anchor = "bottomRight",
                nameOverride = "Next",
                icons = teleportIcons.nextArrow,
            },
        },
    }
end

function SlayerCapePage2:Define()
    return {
        title = "Slayer Masters",
        showTitle = false,
        entries = {
            ["1. Vannaka"] = {
                id = "vannaka",
                npcID = id.NPC.SLAYER_MASTER_3,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(0, 30, "Edgeville")
            },
            ["2. Jacquelyn"] = {
                id = "jacquelyn",
                npcID = id.NPC.SLAYER_MASTER_1A_JACQUELYN,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(0, 0, "Lumbridge")
            },
            ["3. Spria"] = {
                id = "spria",
                npcID = id.NPC.SLAYER_MASTER_1_SPRIA,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(0, 0, "Burthorpe")
            },
            ["3. Turael"] = {
                id = "turael",
                npcID = id.NPC.SLAYER_MASTER_1_TUREAL,
                animID = id.Seq.HUMAN_READY,
                viewDistance = distance,
                modelOffset = offset,
                description = description(0, 0, "Burthorpe")
            },
            ["4. Previous page"] = {
                id = "back",
                anchor = "bottomRight",
                nameOverride = "Next",
                icons = teleportIcons.nextArrow,
                point = { x = 100, y = 100 }
            }
        },
    }
end

return { SlayerCapePage1, SlayerCapePage2 }
