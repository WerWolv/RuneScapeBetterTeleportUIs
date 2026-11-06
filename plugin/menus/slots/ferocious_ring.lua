local NpcSlotMenu = require("impl/interfaces/npc_slot_menu")
local descriptions = require("definitions/descriptions")
local FerociousRing = NpcSlotMenu:Extend("ferociousRing")

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

function FerociousRing:Define()
    return {
        title = "Slayer Masters",
        columns = 2,
        rows = 1,
        entries = {
            ["1. Kuradal."] = {
                nameOverride = "Kuradal",
                npcID = id.NPC.SLAYER_MASTER_6_KURADAL,
                animID = id.Seq.HUMAN_READY,
                viewDistance = 400,
                modelOffset = {
                    x = 0,
                    y = 220
                },
                description = description(75, 110, "Ancient Cavern")
            },
            ["2. Morvran."] = {
                nameOverride = "Morvran",
                npcID = id.NPC.SLAYER_MASTER_7_IORWERTH,
                animID = id.Seq.ELF_2014_SLAYER_MASTER_IDLE,
                viewDistance = 400,
                modelOffset = {
                    x = 0,
                    y = 190
                },
                description = description(85, 120, "Iorwerth Clan, Prifddinas")
            },
            ["3. Nowhere."] = {
                hidden = true
            },
        },
    }
end

return FerociousRing
