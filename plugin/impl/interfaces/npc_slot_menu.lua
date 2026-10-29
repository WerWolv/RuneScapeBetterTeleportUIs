local SlotMenu = require("impl/interfaces/slot_menu")
local ButtonIcon = require("impl/button_icon")
local components = require("impl/components")
local text = require("impl/text")
local userSettings = require("impl/settings")
local NpcSlotMenu = SlotMenu:Extend()

local columns, slotSize, labelHeight, gap, inset = 5, 112, 24, 8, 8
local gridWidth = columns * slotSize + (columns - 1) * gap + inset * 2
local gridHeight = 2 * (slotSize + labelHeight) + gap + inset * 2
local modelInset = 6

-- The model cards identify the choices without the native selection prompt.
function NpcSlotMenu:UpdateTitle()
    SlotMenu.UpdateTitle(self)

    local title = self.session.title

    if title ~= nil then
        title.control.alpha = 0
    end
end

-- Cards use NPCs or navigation artwork rather than map coordinates.
function NpcSlotMenu:ValidateDestination(definition)
    if definition.npcID ~= nil or definition.icons ~= nil then
        return true
    end

    return false, "needs an NPC ID or navigation artwork"
end

-- Build passive model cards; the original native rows remain the only click targets.
function NpcSlotMenu:BeginVisuals()
    SlotMenu.BeginVisuals(self)

    for _, row in ipairs(self.session.menu.rows) do
        local destination = row.destination
        local slot = self:CreateSlot(row, destination.npcID ~= nil)
        local layer = slot.layer

        if destination.npcID ~= nil then
            -- Clip model drawing to the slot interior, excluding its border and name label.
            local viewport = ui.Layer.new(layer)
            viewport.clickthrough = true
            slot.viewport = viewport

            local model = ui.Model.new(viewport)
            model.clickthrough = true
            model:SetModel(ui.ModelType.NPC_MODEL, destination.npcID)
            model.modelWidth = slotSize
            model.modelHeight = slotSize
            model.viewDistance = destination.viewDistance or 600

            if destination.animID ~= nil then
                model.animID = destination.animID
            end

            slot.model = model

            slot.label = components.CenteredLabel(layer, id.Font.MUSEO_SANS_13PT_REGULAR)
        else
            local sprite = ui.Sprite.new(layer)
            local icons = destination.icons
            sprite.spriteID = ButtonIcon.Source(icons, false, row.disabled, row.locked).sprite
            sprite.clickthrough = true
            slot.icon = sprite
        end
    end
end

-- Keep both pages the same size, shrinking the complete card layout for smaller viewports.
function NpcSlotMenu:CalculateLayout()
    local session = self.session
    local scale = math.max(0.01, math.min(1,
        (session.parent.width - session.left - session.right - 16) / gridWidth,
        (session.parent.height - session.top - session.bottom - 16) / gridHeight))

    return {
        width = math.max(1, math.floor(gridWidth * scale)),
        height = math.max(1, math.floor(gridHeight * scale)),
        scale = scale,
    }
end

-- Align each full card, including its name, with its client-owned teleport operation.
function NpcSlotMenu:ApplyLayout(layout)
    self:LayoutWindow(layout.width, layout.height)
    self.slotLayer:SetSize(layout.width, layout.height)

    local origin = self.slotLayer.xyGlobal
    local function scaled(value)
        return math.floor(value * layout.scale)
    end

    for slotIndex, slot in ipairs(self.slots) do
        local row = slot.row
        local destination = row.destination
        local index = slotIndex - 1
        local x = inset + (index % columns) * (slotSize + gap)
        local y = inset + math.floor(index / columns) * (slotSize + labelHeight + gap)
        local width, height = slotSize, slotSize + labelHeight

        if slot.model ~= nil then
            slot.background:SetSize(scaled(slotSize), scaled(slotSize))
            slot.viewport:SetPos(scaled(modelInset), scaled(modelInset))
            slot.viewport:SetSize(scaled(slotSize - modelInset * 2), scaled(slotSize - modelInset * 2))
            slot.model:SetPos(0, 0)
            slot.model:SetSize(slot.viewport.width, slot.viewport.height)

            local offset = destination.modelOffset or { x = 0, y = 0 }
            local screenOffset = slot.model.screenOffset
            screenOffset.x = scaled(offset.x or 0)
            screenOffset.y = scaled(offset.y or 0)
            screenOffset.z = 0
            slot.model.screenOffset = screenOffset

            slot.label:SetPos(0, scaled(slotSize))
            slot.label:SetSize(scaled(width), scaled(labelHeight))
        else
            local iconWidth, iconHeight = ButtonIcon.Dimensions(destination.icons)

            slot.icon:SetSize(scaled(iconWidth), scaled(iconHeight))

            if destination.anchor == "bottomRight" then
                x = gridWidth - inset - iconWidth
                y = gridHeight - inset - iconHeight
                width, height = iconWidth, iconHeight
                slot.icon:SetPos(0, 0)
            else
                slot.icon:SetPos(scaled((slotSize - iconWidth) / 2), scaled((slotSize - iconHeight) / 2))
            end
        end

        slot.layer:SetPos(scaled(x), scaled(y))
        slot.layer:SetSize(scaled(width), scaled(height))

        if not row.locked then
            self:HideRowArtwork(row)
            self:LayoutRow(row, origin.x + scaled(x), origin.y + scaled(y), scaled(width), scaled(height))
        end
    end
end

function NpcSlotMenu:GetHovered()
    for _, row in ipairs(self.session.rows) do
        if row.click.visibleGlobal and row.click.isMouseOver then
            return row.name
        end
    end
end

-- Use native availability and hover for card styling and the existing PrettyUI tooltips.
function NpcSlotMenu:UpdateVisuals(layout, hovered)
    for _, slot in ipairs(self.slots) do
        local row = slot.row
        if slot.label ~= nil then
            local name = self:GetDisplayName(row)
            local hotkey = text.Hotkey(row.name)

            if not row.locked and hotkey ~= nil and userSettings.Get("showTeleportHotkeys") then
                name = hotkey .. ". " .. name
            end

            slot.label.content = name
            slot.label.rgba = row.name == hovered and 0xFFFFFFFF or 0xFFE3A3FF
        else
            local icons = row.destination.icons
            local source = ButtonIcon.Source(icons, row.name == hovered, row.disabled, row.locked)

            slot.icon.spriteID = source.sprite
        end

        slot.layer.alpha = row.disabled and 0.4 or 1

        if slot.background ~= nil then
            slot.background.rgb = row.name == hovered and 0xFFFFFF or 0xC0C0C0
        end
    end

    SlotMenu.UpdateVisuals(self, layout, hovered)
end

return NpcSlotMenu
