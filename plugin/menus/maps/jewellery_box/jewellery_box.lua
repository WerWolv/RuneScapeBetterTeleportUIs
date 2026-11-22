local TeleportListMenu = require("impl/interfaces/native/teleport_list_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local categoryMap = require("impl/interfaces/presentations/category_map_menu")
local categories = require("menus/maps/jewellery_box/categories")

local JewelleryBox = categoryMap.Create(TeleportListMenu, "jewelleryBox", categories)

local jewellery = {
    duelling    = teleportIcons.jewellery.goldEmerald,
    games       = teleportIcons.jewellery.goldSapphire,
    respawn     = teleportIcons.jewellery.silverJade,
    combat      = teleportIcons.jewellery.goldDragonstone,
    enlightened = teleportIcons.jewellery.silverTopaz,
    skills      = teleportIcons.jewellery.goldDragonstone,
    glory       = teleportIcons.jewellery.goldDragonstone,
    wealth      = teleportIcons.jewellery.goldDragonstone,
    slaying     = teleportIcons.jewellery.goldEnchantedGem,
}

local function destination(buttonID, x, y, category)
    return {
        id = buttonID,
        point = { x = x, y = y },
        categories = { category },
        icons = jewellery[category],
    }
end

function JewelleryBox:Define()
    local entries = {
        ["Het's Oasis"]            = destination("hetsoasis",       369, 161, "duelling"),
        ["Castle Wars"]            = destination("castlewars",      110, 199, "duelling"),
        ["Warforge Dig Site"]      = destination("warforge",        112, 276, "duelling"),
        ["Fist of Guthix"]         = destination("fistofguthix",    280, 111, "duelling"),
        ["Troll Invasion"]         = destination("trollinvasion",   247, 41,  "games"),
        ["Barbarian Outpost"]      = destination("barbarianoutpost",147, 69,  "games"),
        ["Gamers' Grotto"]         = destination("gamersgrotto",    296, 111, "games"),
        ["Agoroth"]                = destination("agoroth",         145, 300, "games"),
        ["Corporeal Beast"]        = destination("corporealbeast",  326, 30,  "games"),
        ["Burgh de Rott"]          = destination("burghderott",     432, 165, "games"),
        ["Tears of Guthix"]        = destination("tearsofguthix",   331, 173, "games"),
        ["Lumbridge Castle"]       = destination("lumbridge",       350, 177, "respawn"),
        ["Falador Castle"]         = destination("falador",         275, 128, "respawn"),
        ["Camelot"]                = destination("camelot",         216, 93,  "respawn"),
        ["Soul Wars"]              = destination("soulwars",        53,  275, "respawn"),
        ["Burthorpe bank"]         = destination("burthorpe",       257, 73,  "respawn"),
        ["Warriors' Guild"]        = destination("warriors",        239, 70,  "combat"),
        ["Champions' Guild"]       = destination("champions",       336, 121, "combat"),
        ["Edgeville Monastery"]    = destination("monastery",       285, 80,  "combat"),
        ["Ranging Guild"]          = destination("ranging",         188, 107, "combat"),
        ["The Nexus"]              = destination("nexus",           338, 191, "enlightened"),
        ["Graveyard of Shadows"]   = destination("graveyard",       348, 45,  "enlightened"),
        ["Bandit Camp"]            = destination("banditcamp",      336, 224, "enlightened"),
        ["Fishing Guild"]          = destination("fishing",         175, 123, "skills"),
        ["Mining Guild"]           = destination("mining",          295, 135, "skills"),
        ["Crafting Guild"]         = destination("crafting",        268, 147, "skills"),
        ["Cooking Guild"]          = destination("cooking",         327, 105, "skills"),
        ["Invention Guild"]        = destination("invention",       270, 97,  "skills"),
        ["Farming Guild"]          = destination("farming",         193, 130, "skills"),
        ["Runecrafting Guild"]     = destination("runecrafting",    310, 183, "skills"),
        ["Edgeville bank"]         = destination("edgeville",       302, 86,  "glory"),
        ["Karamja"]                = destination("karamja",         254, 181, "glory"),
        ["Draynor Village"]        = destination("draynor",         308, 156, "glory"),
        ["Al Kharid"]              = destination("alkharid",        371, 196, "glory"),
        ["Miscellania"]            = destination("miscellania",     113, 17,  "wealth"),
        ["Grand Exchange"]         = destination("grandexchange",   329, 87,  "wealth"),
        ["Sumona in Pollnivneach"] = destination("sumona",          374, 234, "slaying"),
        ["Morytania Slayer Tower"] = destination("slayertower",     404, 76,  "slaying"),
        ["Fremennik Dungeon"]      = destination("slayerdungeon",   199, 28,  "slaying"),
        ["Tarn's Lair"]            = destination("tarnslair",       413, 157, "slaying"),
    }

    for name, entry in pairs(entries) do
        entry.categoryKey = name
        entry.nameOverride = name
    end

    local aliases = {
        ["Castle Wars Arena"] = "Castle Wars",
        ["The Warforge"] = "Warforge Dig Site",
        ["Warforge"] = "Warforge Dig Site",
        ["Gamer's Grotto"] = "Gamers' Grotto",
        ["Gamers Grotto"] = "Gamers' Grotto",
        ["Burgh De Rott"] = "Burgh de Rott",
        ["Lumbridge"] = "Lumbridge Castle",
        ["Falador"] = "Falador Castle",
        ["Burthorpe"] = "Burthorpe bank",
        ["Burthorpe Bank"] = "Burthorpe bank",
        ["Edgeville Monestary"] = "Edgeville Monastery", -- Typo in the game
        ["Lumbridge Swamp"] = "The Nexus",
        ["The Nexus (Lumbridge Swamp)"] = "The Nexus",
        ["South of the Graveyard of Shadows"] = "Graveyard of Shadows",
        ["Desert bandit camp entrance"] = "Bandit Camp",
        ["Bandit camp"] = "Bandit Camp",
        ["Edgeville"] = "Edgeville bank",
        ["Edgeville Bank"] = "Edgeville bank",
        ["Pollnivneach"] = "Sumona in Pollnivneach",
        ["Fremennik Slayer Dungeon"] = "Fremennik Dungeon",
    }
    for alias, name in pairs(aliases) do
        entries[alias] = entries[name]
    end

    return {
        title = "Jewellery Box",
        showTeleportNames = false,
        background = backgrounds.runescapeSurface,
        noBackgroundCrop = true,
        sizeMultiplier = 1.85,
        entries = entries,
    }
end

return JewelleryBox
