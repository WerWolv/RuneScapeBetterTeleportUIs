local PortalNexusMenu = require("impl/interfaces/portal_nexus_menu")
local backgrounds = require("definitions/backgrounds")
local descriptions = require("definitions/descriptions")
local categoryMap = require("impl/ui/category_map_menu")
local categories = require("definitions/nexus_categories")

local TeleportNexus = categoryMap.Create(PortalNexusMenu, "teleportNexus", categories)

-- Destinations can belong to several category filters.
local function destination(x, y, ...)
    local memberships = { ... }

    if #memberships == 0 then
        memberships = { "standard" }
    end

    return {
        point = { x = x, y = y },
        categories = memberships,
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
        ["Paddewwa"]                    = destination(310, 80, "ancient"),
        ["Senntisten"]                  = destination(379, 110, "ancient"),
        ["Kharyrll"]                    = destination(423, 87, "ancient"),
        ["Lassar"]                      = destination(282, 91, "ancient"),
        ["Dareeyak"]                    = destination(296, 47, "ancient"),
        ["Carrallangar"]                = destination(348, 44, "ancient"),
        ["Annakarl"]                    = destination(386, 16, "ancient"),
        ["Ghorrock"]                    = destination(294, 16, "ancient"),
        ["Moonclan"]                    = destination(20, 18, "lunar"),
        ["Ourania"]                     = destination(128, 157, "lunar"),
        ["South Falador"]               = destination(285, 148, "lunar"),
        ["Waterbirth"]                  = destination(155, 15, "lunar"),
        ["Barbarian"]                   = destination(147, 69, "lunar"),
        ["North Ardougne"]              = destination(164, 118, "lunar"),
        ["Khazard"]                     = destination(185, 158, "lunar"),
        ["Fishing Guild"]               = destination(170, 95, "lunar"),
        ["Catherby"]                    = destination(229, 104, "lunar"),
        ["Ice Plateau"]                 = destination(316, 16, "lunar"),
        ["Trollheim Farm"]              = destination(250, 49, "lunar"),
        ["Taverley"]                    = destination(257, 97),
        ["Western Kharazi Jungle"]      = destination(234, 248, "lunar"),
        ["Mountain Camp"]               = destination(229, 29, "lunar"),
        ["North-western Anachronia"]    = destination(482, 32),
        ["Eastern Anachronia"]          = destination(519, 50),
        ["Northern Lost Grove"]         = destination(15, 180),
        ["Wendlewick"]                  = destination(533, 133),
        ["Marigold Farm"]               = destination(545, 165),
        ["Mazcab"]                      = destination(310, 265),
    }

    -- Use canonical names for saved assignments, independently of native aliases.
    for name, entry in pairs(entries) do
        entry.categoryKey = name
    end

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

local spells = {
    ["South Feldip Hills"]       = "MAGIC_TELEPORT_MOBILISING_ARMIES",
    ["Varrock"]                  = "MAGIC_TELEPORT_VARROCK",
    ["Grand Exchange"]           = "MAGIC_TELEPORT_VARROCK",
    ["North-East Varrock"]       = "MAGIC_TELEPORT_VARROCK",
    ["Lumbridge"]                = "MAGIC_TELEPORT_LUMBRIDGE",
    ["Falador"]                  = "MAGIC_TELEPORT_FALADOR",
    ["Camelot"]                  = "MAGIC_TELEPORT_CAMELOT",
    ["Seers' Village"]           = "MAGIC_TELEPORT_CAMELOT",
    ["Ardougne"]                 = "MAGIC_TELEPORT_ARDOUGNE",
    ["Watchtower"]               = "MAGIC_TELEPORT_WATCHTOWER",
    ["Yanille"]                  = "MAGIC_TELEPORT_WATCHTOWER",
    ["Trollheim"]                = "MAGIC_TELEPORT_TROLLHEIM",
    ["God Wars Dungeon"]         = "MAGIC_TELEPORT_GODWARS",
    ["The Heart of Gielinor"]    = "MAGIC_TELEPORT_GODWARS2",
    ["Ape Atoll"]                = "MAGIC_TELEPORT_APE_ATOLL",
    ["Paddewwa"]                 = "MAGIC_TELEPORT_EDGEVILLE",
    ["Senntisten"]               = "MAGIC_TELEPORT_DIGSITE",
    ["Kharyrll"]                 = "MAGIC_TELEPORT_CANFIS",
    ["Lassar"]                   = "MAGIC_TELEPORT_ICE_MOUNTAIN",
    ["Dareeyak"]                 = "MAGIC_TELEPORT_WESTERN_RUINS",
    ["Carrallangar"]             = "MAGIC_TELEPORT_WILDY_GRAVEYARD",
    ["Annakarl"]                 = "MAGIC_TELEPORT_DEMONIC_RUINS",
    ["Ghorrock"]                 = "MAGIC_TELEPORT_ICE_PLATEAU_ANCIENT",
    ["Moonclan"]                 = "MAGIC_TELEPORT_MOONCLAN",
    ["Ourania"]                  = "MAGIC_TELEPORT_ZMI",
    ["South Falador"]            = "MAGIC_TELEPORT_SOUTH_FALADOR",
    ["Waterbirth"]               = "MAGIC_TELEPORT_WATERBIRTH",
    ["Barbarian"]                = "MAGIC_TELEPORT_BARBARIAN",
    ["North Ardougne"]           = "MAGIC_NORTH_ARDOUGNE",
    ["Khazard"]                  = "MAGIC_TELEPORT_KHAZARD",
    ["Fishing Guild"]            = "MAGIC_TELEPORT_FISHING_GUILD",
    ["Catherby"]                 = "MAGIC_TELEPORT_CATHERBY",
    ["Ice Plateau"]              = "MAGIC_TELEPORT_ICE_PLATEAU_LUNAR",
    ["Trollheim Farm"]           = "MAGIC_TELEPORT_TROLLHEIM_FARM",
    ["Taverley"]                 = "MAGIC_TELEPORT_TAVERLEY",
    ["Western Kharazi Jungle"]   = "MAGIC_TELEPORT_KHARAZI_JUNGLE_WEST",
    ["Mountain Camp"]            = "MAGIC_TELEPORT_MOUNTAIN_CAMP",
    ["North-western Anachronia"] = "MAGIC_TELEPORT_ANACHRONIA_NORTH_WEST",
    ["Eastern Anachronia"]       = "MAGIC_TELEPORT_ANACHRONIA_EAST",
    ["Northern Lost Grove"]      = "MAGIC_TELEPORT_LOST_GROVE_NORTH",
    ["Wendlewick"]               = "MAGIC_TELEPORT_WENDLEWICK",
    ["Marigold Farm"]            = "MAGIC_TELEPORT_WENDLEWICK",
    ["Mazcab"]                   = "MAGIC_TELEPORT_MAZCAB",
}

-- Spell configs provide artwork even when the native Nexus is closed or lacks a destination.
function TeleportNexus:GetCategoryIcon(entry)
    local spell = config.Struct[assert(spells[entry.categoryKey])]
    local sprite = spell:GetParamValue(config.Param.COMBATV2_ABILITY_ICON)

    return { sprite = type(sprite) == "number" and sprite or sprite.id }
end

return TeleportNexus
