local PortalNexusMenu = require("impl/interfaces/portal_nexus_menu")
local backgrounds = require("definitions/backgrounds")
local descriptions = require("definitions/descriptions")

local TeleportNexus = PortalNexusMenu:Extend("teleportNexus")

local function destination(x, y)
    return {
        point = { x = x, y = y },
    }
end

function TeleportNexus:Define()
    local entries = {
        ["South Feldip Hills"]          = destination(115, 275),
        ["Varrock"]                     = destination(351, 105),
        ["Grand Exchange"]              = destination(333, 92),
        ["North-East Varrock"]          = destination(362, 80),
        ["Lumbridge"]                   = destination(340, 170),
        ["Falador"]                     = destination(272, 117),
        ["Camelot"]                     = destination(211, 82),
        ["Seers' Village"]              = destination(185, 81),
        ["Ardougne"]                    = destination(167, 139),
        ["Watchtower"]                  = destination(158, 177),
        ["Yanille"]                     = destination(180, 181),
        ["Trollheim"]                   = destination(265, 33),
        ["God Wars Dungeon"]            = destination(270, 12),
        ["The Heart of Gielinor"]       = destination(380, 272),
        ["Ape Atoll"]                   = destination(207, 295),
        ["Paddewwa"]                    = destination(310, 80),
        ["Senntisten"]                  = destination(379, 110),
        ["Kharyrll"]                    = destination(423, 87),
        ["Lassar"]                      = destination(282, 91),
        ["Dareeyak"]                    = destination(296, 47),
        ["Carrallangar"]                = destination(348, 44),
        ["Annakarl"]                    = destination(386, 16),
        ["Ghorrock"]                    = destination(294, 16),
        ["Moonclan"]                    = destination(20, 18),
        ["Ourania"]                     = destination(128, 157),
        ["South Falador"]               = destination(285, 148),
        ["Waterbirth"]                  = destination(155, 15),
        ["Barbarian"]                   = destination(147, 69),
        ["North Ardougne"]              = destination(164, 118),
        ["Khazard"]                     = destination(185, 158),
        ["Fishing Guild"]               = destination(170, 95),
        ["Catherby"]                    = destination(229, 104),
        ["Ice Plateau"]                 = destination(316, 16),
        ["Trollheim Farm"]              = destination(250, 49),
        ["Taverley"]                    = destination(257, 97),
        ["Western Kharazi Jungle"]      = destination(234, 248),
        ["Mountain Camp"]               = destination(229, 29),
        ["North-western Anachronia"]    = destination(482, 32),
        ["Eastern Anachronia"]          = destination(519, 50),
        ["Northern Lost Grove"]         = destination(15, 180),
        ["Wendlewick"]                  = destination(533, 133),
        ["Marigold Farm"]               = destination(545, 165),
        ["Mazcab"]                      = destination(310, 265),
    }

    local aliases = {
        ["The Heart"]                           = "The Heart of Gielinor",
        ["North-east Varrock"]                  = "North-East Varrock",
        ["North-Western Anachronia"]            = "North-western Anachronia",
        ["Wendlewick Farm"]                     = "Marigold Farm",
        ["Paddewwa (Edgeville)"]                = "Paddewwa",
        ["Senntisten (Varrock Dig Site)"]       = "Senntisten",
        ["Kharyrll (Canifis)"]                  = "Kharyrll",
        ["Lassar (Ice Mountain)"]               = "Lassar",
        ["Dareeyak (Western Wilderness)"]       = "Dareeyak",
        ["Carrallangar (Graveyard of Shadows)"] = "Carrallangar",
        ["Annakarl (Demonic Ruins)"]            = "Annakarl",
        ["Ghorrock (Ice Plateau)"]              = "Ghorrock",
        ["Moonclan (Lunar Isle)"]               = "Moonclan",
        ["Ourania (ZMI Altar)"]                 = "Ourania",
    }

    for alias, name in pairs(aliases) do
        local entry = entries[name]
        local location = alias:match("%((.-)%)$")

        if location ~= nil then
            entry.nameOverride = name
            entry.description = descriptions.Location(location)
        end

        entries[alias] = entry
    end

    return {
        title = "Portal Nexus",
        background = backgrounds.runescapeSurface,
        noBackgroundCrop = true,
        sizeMultiplier = 1.75,

        icons = {
            size = 32,
            hoveredSize = 36,
            shadowColor = 0x00000099,
            shadowColorHovered = 0x000000CC,
        },

        entries = entries,
    }
end

return TeleportNexus
