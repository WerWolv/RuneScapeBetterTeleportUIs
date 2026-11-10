local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local ModelSlotMenu = require("impl/interfaces/presentations/model_slot_menu")
local KethsiRing = ModelSlotMenu.Create(ModalChoiceMenu, "kethsiRing")

function KethsiRing:Define()
    return {
        title = "Kethsi Dragons",
        columns = 2,
        rows = 1,
        entries = {
            ["1. Adamant dragons"] = {
                nameOverride = "Adamant",
                npcID = id.NPC.ADAMANT_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 50
                },
            },
            ["2. Rune dragons"] = {
                nameOverride = "Rune",
                npcID = id.NPC.RUNE_DRAGON,
                animID = id.Seq.DRAGON_UPDATE_09_READY,
                viewDistance = 1600,
                modelOffset = {
                    x = 0,
                    y = 50
                },
            },
            ["3. Nowhere"] = {
                hidden = true
            },
        },
    }
end

return KethsiRing
