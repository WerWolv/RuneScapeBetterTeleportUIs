local SpiritTreeMenu = require("impl/interfaces/native/spirit_tree_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local NativeLayout = require("impl/interfaces/native/native_layout")
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
    if row.disabled and not row.currentLocation and row.destination.disabledDescription ~= nil then
        return row.destination.disabledDescription
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
    self.tooltipProbes = {}
end

function SpiritTrees:ApplyLayout(layout)
    MapMenu.ApplyLayout(self, layout)

    local origin = self.backgroundView.layer.xyGlobal

    for _, rectangle in ipairs(self.session.rowRectangles) do
        local row = rectangle.entry
        local probe = self.tooltipProbes[row.name]

        if probe == nil then
            local control = prettyui.NewComponent(ui.Layer, self.backgroundView.layer)
            control.enabled = true
            probe = {
                control = control,
                target = row.click,
                description = self:GetDescription(row),
            }
            self.tooltipProbes[row.name] = probe
        end

        local control = probe.control
        local x, y = math.floor(rectangle.x - origin.x), math.floor(rectangle.y - origin.y)

        control.hidden = not row.disabled or row.destination.hidden
            or rectangle.width == 0 or rectangle.height == 0
        control.clickthrough = not row.disabled

        if probe.x ~= x or probe.y ~= y then
            control:SetPos(x, y)
            probe.x, probe.y = x, y
        end

        if probe.width ~= rectangle.width or probe.height ~= rectangle.height then
            control:SetSize(rectangle.width, rectangle.height)
            probe.width, probe.height = rectangle.width, rectangle.height
        end

        -- An inert hover target handles unavailable rows without enabling their
        -- native actions. Available rows retain their original action owner.
        NativeLayout.Set(row.click, "clickthrough", row.disabled)

        local target = row.disabled and control or row.click
        local description = self:GetDescription(row)

        if probe.target ~= target or probe.description ~= description then
            local tooltip = self.session.tooltips[row.name]

            if tooltip ~= nil then
                tooltip:Destroy()
                self.session.tooltips[row.name] = nil
            end

            self:AttachTooltip(row, target)
            probe.target, probe.description = target, description

            -- Tooltip teardown restores the old target's clickthrough value.
            NativeLayout.Set(row.click, "clickthrough", row.disabled)
            control.clickthrough = not row.disabled
        end
    end
end

function SpiritTrees:GetHovered()
    for _, row in ipairs(self.session.menu.rows) do
        local probe = self.tooltipProbes[row.name]

        if row.disabled and probe ~= nil and probe.control.visibleGlobal and probe.control.isMouseOver then
            return row.name
        end
    end

    return MapMenu.GetHovered(self)
end

function SpiritTrees:UpdateVisuals(layout, hovered)
    -- Refresh artwork from the adapter's current-location and availability state.
    for _, row in ipairs(self.session.menu.rows) do
        updateIcon(row)
    end

    MapMenu.UpdateVisuals(self, layout, hovered)
end

function SpiritTrees:ReleaseVisuals()
    MapMenu.ReleaseVisuals(self)
    self.tooltipProbes = nil
end

return SpiritTrees
