local SpiritTreeMenu = require("impl/interfaces/native/spirit_tree_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local descriptions = require("definitions/descriptions")

local SpiritTrees = MapMenu.Create(SpiritTreeMenu, "spiritTrees")

function SpiritTrees:Define()
    return {
        title = "Spirit Trees",
        background = backgrounds.runescapeSurfaceFull,
        sizeMultiplier = 1.25,
        icons = {
            image = Plugin.resources.icons.spirit_tree.normal,
            size = 36,
        },
        entries = {
            ["Tree Gnome Village"] = {
                point = { x = 136, y = 175 },
            },
            ["Tree Gnome Stronghold"] = {
                disabledDescription = descriptions.QuestRequirement("The Grand Tree"),
                point = { x = 105, y = 80 },
            },
            ["Battlefield"] = {
                point = { x = 145, y = 134 },
            },
            ["Grand Exchange"] = {
                point = { x = 329, y = 89 },
            },
            ["South Feldip Hills"] = {
                point = { x = 119, y = 276 },
            },
            ["Port Sarim"] = {
                disabledDescription = descriptions.LevelRequirement(83, descriptions.SKILL.FARMING),
                point = { x = 286, y = 157 },
            },
            ["Etceteria"] = {
                disabledDescription = descriptions.LevelRequirement(83, descriptions.SKILL.FARMING),
                point = { x = 126, y = 25 },
            },
            ["Brimhaven"] = {
                disabledDescription = descriptions.LevelRequirement(83, descriptions.SKILL.FARMING),
                point = { x = 212, y = 154 },
            },
            ["Poison Waste"] = {
                disabledDescription = descriptions.QuestRequirement("The Path of Glouphrie"),
                point = { x = 80, y = 191 },
            },
            ["Prifddinas"] = {
                disabledDescription = descriptions.QuestRequirement("Plague's End"),
                point = { x = 72, y = 135 },
            },
            ["Manor Farm"] = {
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

local function updateIcon(row)
    local icons = row.destination.icons
    local images = Plugin.resources.icons.spirit_tree

    icons.sprite = row.currentLocation and images.current or images.normal
    icons.disabled.sprite = row.currentLocation and images.current or images.disabled
end

function SpiritTrees:BeginVisuals()
    for _, row in ipairs(self.session.menu.rows) do
        row.destination.hotkey = row.native.shortcut
        row.destination.icons = { disabled = {}, size = self.definition.icons.size }
        updateIcon(row)
    end

    MapMenu.BeginVisuals(self)
end

function SpiritTrees:UpdateVisuals(layout, hovered)
    -- Refresh artwork from the adapter's current-location and availability state.
    for _, row in ipairs(self.session.menu.rows) do
        updateIcon(row)
    end

    MapMenu.UpdateVisuals(self, layout, hovered)
end

return SpiritTrees
