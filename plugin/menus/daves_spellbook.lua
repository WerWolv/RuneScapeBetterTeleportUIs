local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local cropped = require("definitions/artwork_variants").Cropped
local DavesSpellbook = ModalChoiceMenu:Extend("davesSpellbook")

-- Format the captured chipped tablet count using the appropriate plural form.
local function tabletsRemaining(count)
    local noun = tonumber(count) == 1 and "tablet" or "tablets"
    return descriptions.Text(string.format("%s <sprite=1824> teleport %s left", count, noun))
end

function DavesSpellbook:Define()
    return {
        title = "'Chipped' Teleport Tablets",
        background = cropped(
            backgrounds.runescapeSurface, 
            { x = 80, y = 60, width = 320, height = 170 }
        ),
        entries = {
            ["^1%. Watchtower %((%d+)%)$"] = {
                nameOverride = "Observatory",
                description = tabletsRemaining,
                point = {x = 123, y = 176},
                icons = teleportIcons.chippedTeleportTablets.watchtower,
            },
            ["^2%. Camelot %((%d+)%)$"] = {
                nameOverride = "Catherby docks",
                description = tabletsRemaining,
                point = {x = 224, y = 104},
                icons = teleportIcons.chippedTeleportTablets.camelot,
            },
            ["^3%. Falador %((%d+)%)$"] = {
                nameOverride = "Southern Falador gate",
                description = tabletsRemaining,
                point = {x = 286, y = 142},
                icons = teleportIcons.chippedTeleportTablets.falador,
            },
            ["^4%. Ardougne %((%d+)%)$"] = {
                nameOverride = "West Ardougne",
                description = tabletsRemaining,
                point = {x = 147, y = 141},
                icons = teleportIcons.chippedTeleportTablets.ardougne,
            },
            ["^5%. Lumbridge %((%d+)%)$"] = {
                nameOverride = "Lumbridge Swamp",
                description = tabletsRemaining,
                point = {x = 338, y = 182},
                icons = teleportIcons.chippedTeleportTablets.lumbridge,
            },
            ["^6%. Varrock %((%d+)%)$"] = {
                nameOverride = "Varrock Museum",
                description = tabletsRemaining,
                point = {x = 355, y = 92},
                icons = teleportIcons.chippedTeleportTablets.varrock,
            },
        },
    }
end

return DavesSpellbook
