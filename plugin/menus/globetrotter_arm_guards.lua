local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
local GlobetrotterArmGuards = ModalChoiceMenu:Extend("globeTrotterArmGuards")

-- Format the captured scroll count using the appropriate plural form.
local function chargesRemaining(count)
    local noun = tonumber(count) == 1 and "scroll" or "scrolls"
    return string.format("- %s <sprite=4513> %s remaining", count, noun)
end

-- Define scroll destinations with live charge counts captured from native labels.
function GlobetrotterArmGuards:Define()
    return {
        title = "Teleport Scrolls",
        background = cropped(
            backgrounds.runescapeSurface, 
            {x = 0, y = 0, width = 420, height = 270}
        ),
        entries = {
            ["^1%. Grand Exchange%. %((%d+)%)$"] = {
                nameOverride = "Grand Exchange",
                description = chargesRemaining,
                point = {x = 328, y = 95},
                icons = teleportIcons.teleportScrolls.grandExchange,
            },
            ["^2%. Bandit Camp%. %((%d+)%)$"] = {
                nameOverride = "Bandit Camp",
                description = chargesRemaining,
                point = {x = 330, y = 232},
                icons = teleportIcons.teleportScrolls.banditCamp,
            },
            ["^3%. Clocktower%. %((%d+)%)$"] = {
                nameOverride = "Clocktower",
                description = chargesRemaining,
                point = {x = 162, y = 159},
                icons = teleportIcons.teleportScrolls.clockTower,
            },
            ["^4%. Gu'Tanoth%. %((%d+)%)$"] = {
                nameOverride = "Gu'Tanoth",
                description = chargesRemaining,
                point = {x = 146, y = 212},
                icons = teleportIcons.teleportScrolls.guTanoth,
            },
            ["^5%. Lighthouse%. %((%d+)%)$"] = {
                nameOverride = "Lighthouse",
                description = chargesRemaining,
                point = {x = 141, y = 45},
                icons = teleportIcons.teleportScrolls.lighthouse,
            },
            ["^6%. Fort Forinthry%. %((%d+)%)$"] = {
                nameOverride = "Fort Forinthry",
                description = chargesRemaining,
                point = {x = 372, y = 73},
                icons = teleportIcons.teleportScrolls.fortForinthry,
            },
            ["^7%. Miscellania%. %((%d+)%)$"] = {
                nameOverride = "Miscellania",
                description = chargesRemaining,
                point = {x = 30, y = 20},
                icons = teleportIcons.teleportScrolls.miscellania,
            },
            ["^8%. Phoenix Lair%. %((%d+)%)$"] = {
                nameOverride = "Phoenix Lair",
                description = chargesRemaining,
                point = {x = 81, y = 55},
                icons = teleportIcons.teleportScrolls.phoenixLair,
            },
            ["^9%. Pollnivneach%. %((%d+)%)$"] = {
                nameOverride = "Pollnivneach",
                description = chargesRemaining,
                point = {x = 380, y = 235},
                icons = teleportIcons.teleportScrolls.pollnivneach,
            },
            ["^0%. Tai Bwo Wannai%. %((%d+)%)$"] = {
                nameOverride = "Tai Bwo Wannai",
                description = chargesRemaining,
                point = {x = 223, y = 201},
                icons = teleportIcons.teleportScrolls.taiBwoWannai,
            },
        },
    }
end

return GlobetrotterArmGuards
