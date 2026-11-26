local SpiritTreeMenu = require("impl/interfaces/native/spirit_tree_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local descriptions = require("definitions/descriptions")

local SpiritTrees = MapMenu.Create(SpiritTreeMenu, "spiritTrees")

local function treeIcon(variant, size)
    return {
        image = Plugin.resources.icons.spirit_tree[variant or "normal"],
        size = size or 58,
    }
end

function SpiritTrees:Define()
    return {
        title = "Spirit Trees",
        background = backgrounds.runescapeSurfaceFull,
        sizeMultiplier = 1.7,
        icons = treeIcon(),
        entries = {
            ["Tree Gnome Village"] = {
                icons = treeIcon("village", 65),
                point = { x = 136, y = 175 },
            },
            ["Tree Gnome Stronghold"] = {
                icons = treeIcon("stronghold", 65),
                disabledDescription = descriptions.QuestRequirement("The Grand Tree"),
                point = { x = 105, y = 80 },
            },
            ["Battlefield"] = {
                point = { x = 145, y = 134 },
            },
            ["Grand Exchange"] = {
                icons = treeIcon("grand_exchange"),
                point = { x = 335, y = 79 },
            },
            ["South Feldip Hills"] = {
                icons = treeIcon("feldip"),
                point = { x = 119, y = 260 },
            },
            ["Port Sarim"] = {
                icons = treeIcon("port_sarim"),
                disabledDescription = descriptions.LevelRequirement(83, descriptions.SKILL.FARMING),
                point = { x = 286, y = 147 },
            },
            ["Etceteria"] = {
                icons = treeIcon("etceteria"),
                disabledDescription = descriptions.LevelRequirement(83, descriptions.SKILL.FARMING),
                point = { x = 126, y = 25 },
            },
            ["Brimhaven"] = {
                icons = treeIcon("brimhaven"),
                disabledDescription = descriptions.LevelRequirement(83, descriptions.SKILL.FARMING),
                point = { x = 212, y = 154 },
            },
            ["Poison Waste"] = {
                icons = treeIcon("poison_waste"),
                disabledDescription = descriptions.QuestRequirement("The Path of Glouphrie"),
                point = { x = 80, y = 181 },
            },
            ["Prifddinas"] = {
                icons = treeIcon("prifddinas"),
                disabledDescription = descriptions.QuestRequirement("Plague's End"),
                point = { x = 72, y = 125 },
            },
            ["Manor Farm"] = {
                icons = treeIcon("manor_farm"),
                disabledDescription = descriptions.LevelRequirement(83, descriptions.SKILL.FARMING),
                point = { x = 180, y = 113 },
            },
            ["Player-owned house"] = {
                disabledDescription = descriptions.Text("Needs to be built first")
                    .. descriptions.LevelRequirement(83, descriptions.SKILL.FARMING)
                    .. descriptions.LevelRequirement(75, descriptions.SKILL.CONSTRUCTION),
                point = { x = 60, y = 290 },
            },
        },
    }
end

function SpiritTrees:GetDescription(row)
    if row.currentLocation then
        return row.destination.description
    end

    return SpiritTreeMenu.GetDescription(self, row)
end

function SpiritTrees:BeginVisuals()
    for _, row in ipairs(self.session.menu.rows) do
        row.destination.hotkey = row.native.shortcut
    end

    MapMenu.BeginVisuals(self)
end

return SpiritTrees
