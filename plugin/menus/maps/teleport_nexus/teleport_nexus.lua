local PortalNexusMenu = require("impl/interfaces/native/portal_nexus_menu")
local backgrounds = require("definitions/backgrounds")
local descriptions = require("definitions/descriptions")
local categoryMap = require("impl/interfaces/presentations/category_map_menu")
local categories = require("menus/maps/teleport_nexus/categories")

local TeleportNexus = categoryMap.Create(PortalNexusMenu, "teleportNexus", categories)

-- Destinations can belong to several category filters.
local function destination(buttonID, x, y, ...)
    local memberships = { ... }

    return {
        id = buttonID,
        point = { x = x, y = y },
        categories = memberships,
    }
end

function TeleportNexus:Define()
    local entries = {
        ["South Feldip Hills"]          = destination("southfeldiphills",       115, 275, "standard"),
        ["Varrock"]                     = destination("varrock",                351, 105, "standard"),
        ["Grand Exchange"]              = destination("varrock-ge",             333, 92,  "standard"),
        ["North-East Varrock"]          = destination("varrock-church",         362, 80,  "standard"),
        ["Lumbridge"]                   = destination("lumbridge",              340, 170, "standard"),
        ["Falador"]                     = destination("falador",                272, 117, "standard"),
        ["Camelot"]                     = destination("camelot",                211, 82,  "standard"),
        ["Seers' Village"]              = destination("camelot-seers",          185, 81,  "standard"),
        ["Ardougne"]                    = destination("ardougne",               167, 139, "standard"),
        ["Watchtower"]                  = destination("watchtower",             158, 177, "standard"),
        ["Yanille"]                     = destination("watchtower-yanille",     180, 181, "standard"),
        ["Trollheim"]                   = destination("trollheim",              265, 33,  "standard"),
        ["God Wars Dungeon"]            = destination("godwars",                270, 12,  "standard"),
        ["The Heart of Gielinor"]       = destination("center",                 380, 272, "standard"),
        ["Ape Atoll"]                   = destination("apeatoll",               207, 295, "standard"),
        ["Paddewwa"]                    = destination("paddewwa",               310, 80,  "ancient"),
        ["Senntisten"]                  = destination("senntisten",             379, 110, "ancient"),
        ["Kharyrll"]                    = destination("kharyll",                423, 87,  "ancient"),
        ["Lassar"]                      = destination("lassar",                 282, 91,  "ancient"),
        ["Dareeyak"]                    = destination("dareeyak",               296, 47,  "ancient"),
        ["Carrallangar"]                = destination("carallaner",             348, 44,  "ancient"),
        ["Annakarl"]                    = destination("annakarl",               386, 16,  "ancient"),
        ["Ghorrock"]                    = destination("ghorrock",               294, 16,  "ancient"),
        ["Moonclan"]                    = destination("moonclan",               20,  18,  "lunar"),
        ["Ourania"]                     = destination("ourania",                128, 157, "lunar"),
        ["South Falador"]               = destination("southfalador",           285, 148, "lunar"),
        ["Waterbirth"]                  = destination("waterbirth",             155, 15,  "lunar"),
        ["Barbarian"]                   = destination("barbarian",              147, 69,  "lunar"),
        ["North Ardougne"]              = destination("northardougne",          164, 118, "lunar"),
        ["Khazard"]                     = destination("khazard",                185, 158, "lunar"),
        ["Fishing Guild"]               = destination("fishing",                170, 95,  "lunar"),
        ["Catherby"]                    = destination("catherby",               229, 104, "lunar"),
        ["Ice Plateau"]                 = destination("iceplateu",              316, 16,  "lunar"),
        ["Trollheim Farm"]              = destination("trollheim-farm",         250, 49,  "lunar"),
        ["Taverley"]                    = destination("taverley",               257, 97,  "standard"),
        ["Western Kharazi Jungle"]      = destination("westernkharazi",         234, 248, "lunar"),
        ["Mountain Camp"]               = destination("mountaincamp",           229, 29,  "lunar"),
        ["North-western Anachronia"]    = destination("northwesternanachronia", 472, 12,  "standard"),
        ["Eastern Anachronia"]          = destination("easternanachronia",      540, 10,  "standard"),
        ["Northern Lost Grove"]         = destination("northlostgrove",         15,  180, "standard"),
        ["Wendlewick"]                  = destination("wendlewick",             550, 125, "standard"),
        ["Marigold Farm"]               = destination("wendlewick-marigold",    568, 148, "standard"),
        ["Mazcab"]                      = destination("mazcab",                 310, 265, "standard"),
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
        showTeleportNames = false,
        background = backgrounds.runescapeSurfaceFull,
        noBackgroundCrop = true,
        sizeMultiplier = 2,

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
