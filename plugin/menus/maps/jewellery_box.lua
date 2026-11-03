local TeleportListMenu = require("impl/interfaces/teleport_list_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local categoryMap = require("impl/category_map_menu")
local categories = require("definitions/jewellery_box_categories")

local JewelleryBox = categoryMap.Create(TeleportListMenu, "jewelleryBox", categories)

local jewellery = {
    duelling = teleportIcons.ringOfDuelling,
    games = teleportIcons.gamesNecklace,
    respawn = teleportIcons.ringOfRespawn,
    combat = teleportIcons.combatBracelet,
    enlightened = teleportIcons.enlightenedAmulet,
    skills = teleportIcons.skillsNecklace,
    glory = teleportIcons.amuletOfGlory,
    wealth = teleportIcons.ringOfWealth,
    slaying = teleportIcons.ringOfSlaying,
}

local function destination(x, y, category)
    return {
        point = { x = x, y = y },
        categories = { category },
        icons = jewellery[category],
    }
end

function JewelleryBox:Define()
    local entries = {
        ["Het's Oasis"]            = destination(369, 161, "duelling"),
        ["Castle Wars"]            = destination(110, 199, "duelling"),
        ["Warforge Dig Site"]      = destination(112, 276, "duelling"),
        ["Fist of Guthix"]         = destination(280, 111, "duelling"),
        ["Troll Invasion"]         = destination(247, 41, "games"),
        ["Barbarian Outpost"]      = destination(147, 69, "games"),
        ["Gamers' Grotto"]         = destination(293, 111, "games"),
        ["Agoroth"]                = destination(110, 304, "games"),
        ["Corporeal Beast"]        = destination(326, 30, "games"),
        ["Burgh de Rott"]          = destination(432, 165, "games"),
        ["Tears of Guthix"]        = destination(331, 178, "games"),
        ["Lumbridge Castle"]       = destination(350, 177, "respawn"),
        ["Falador Castle"]         = destination(275, 128, "respawn"),
        ["Camelot"]                = destination(216, 93, "respawn"),
        ["Soul Wars"]              = destination(58, 267, "respawn"),
        ["Burthorpe bank"]         = destination(257, 73, "respawn"),
        ["Warriors' Guild"]        = destination(239, 70, "combat"),
        ["Champions' Guild"]       = destination(336, 121, "combat"),
        ["Edgeville Monastery"]    = destination(290, 87, "combat"),
        ["Ranging Guild"]          = destination(188, 107, "combat"),
        ["The Nexus"]              = destination(338, 191, "enlightened"),
        ["Graveyard of Shadows"]   = destination(348, 45, "enlightened"),
        ["Bandit Camp"]            = destination(336, 224, "enlightened"),
        ["Fishing Guild"]          = destination(175, 123, "skills"),
        ["Mining Guild"]           = destination(295, 135, "skills"),
        ["Crafting Guild"]         = destination(268, 147, "skills"),
        ["Cooking Guild"]          = destination(327, 105, "skills"),
        ["Invention Guild"]        = destination(273, 97, "skills"),
        ["Farming Guild"]          = destination(190, 130, "skills"),
        ["Runecrafting Guild"]     = destination(310, 183, "skills"),
        ["Edgeville bank"]         = destination(302, 86, "glory"),
        ["Karamja"]                = destination(254, 181, "glory"),
        ["Draynor Village"]        = destination(308, 156, "glory"),
        ["Al Kharid"]              = destination(371, 196, "glory"),
        ["Miscellania"]            = destination(113, 17, "wealth"),
        ["Grand Exchange"]         = destination(329, 87, "wealth"),
        ["Sumona in Pollnivneach"] = destination(374, 234, "slaying"),
        ["Morytania Slayer Tower"] = destination(404, 76, "slaying"),
        ["Fremennik Dungeon"]      = destination(199, 28, "slaying"),
        ["Tarn's Lair"]            = destination(416, 157, "slaying"),
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
        background = backgrounds.runescapeSurface,
        noBackgroundCrop = true,
        sizeMultiplier = 1.75,
        entries = entries,
    }
end

return JewelleryBox
