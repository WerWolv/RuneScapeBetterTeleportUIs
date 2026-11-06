local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local MenaphosJournal = ModalChoiceMenu:Extend("menaphosJournal")

local function chargesRemaining(count)
    local noun = tonumber(count) == 1 and "tablet" or "tablets"
    return descriptions.Text(string.format("%s <sprite=31137> teleport %s remaining", count, noun))
end

function MenaphosJournal:Define()
    return {
        title = "Menaphos",
        background = backgrounds.menaphos,
        noBackgroundCrop = true,
        entries = {
            ["^1%. Imperial district %((%d+)%)$"] = {
                point = {x = 402, y = 409},
                icons = teleportIcons.menaphosFactions.imperial,
                nameOverride = "Imperial District",
                description = chargesRemaining,
            },
            ["^2%. Merchant district %((%d+)%)$"] = {
                point = {x = 573, y = 213},
                icons = teleportIcons.menaphosFactions.merchant,
                nameOverride = "Merchant District",
                description = chargesRemaining,
            },
            ["^3%. Port district %((%d+)%)$"] = {
                point = {x = 544, y = 778},
                icons = teleportIcons.menaphosFactions.port,
                nameOverride = "Port District",
                description = chargesRemaining,
            },
            ["^4%. Worker district %((%d+)%)$"] = {
                point = {x = 336, y = 168},
                icons = teleportIcons.menaphosFactions.worker,
                nameOverride = "Worker District",
                description = chargesRemaining,
            },
            ["^5%. Sophanem Slayer Dungeon %((%d+)%)$"] = {
                point = {x = 825, y = 494},
                icons = teleportIcons.sophanemSlayerDungeon,
                nameOverride = "Sophanem Slayer Dungeon",
                description = chargesRemaining,
            },
            ["^6%. Menaphos shifting tombs %((%d+)%)$"] = {
                point = {x = 597, y = 409},
                icons = teleportIcons.shiftingTombs,
                nameOverride = "Shifting Tombs",
                description = chargesRemaining,
            },
        },
    }
end

return MenaphosJournal
