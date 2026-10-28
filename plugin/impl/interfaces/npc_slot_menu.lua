local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local userSettings = require("impl/settings")
local NpcSlotMenu = ModalChoiceMenu:Extend()

local columns, slotSize, labelHeight, gap, inset = 5, 112, 24, 8, 8
local gridWidth = columns * slotSize + (columns - 1) * gap + inset * 2
local gridHeight = 2 * (slotSize + labelHeight) + gap + inset * 2
local modelInset = 6

-- The model cards identify the choices without the native selection prompt.
function NpcSlotMenu:UpdateTitle()
    ModalChoiceMenu.UpdateTitle(self)

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
    self.slotLayer = ui.Layer.new(self.session.content)
    self.slotLayer.clickthrough = true
    self.slots = {}

    for _, row in ipairs(self.session.menu.rows) do
        local destination = row.destination
        local layer = ui.Layer.new(self.slotLayer)
        layer.clickthrough = true

        local slot = {
            row = row,
            layer = layer,
        }

        self.slots[#self.slots + 1] = slot

        if destination.npcID ~= nil then
            local background = ui.Sprite.new(layer)
            background.spriteID = id.Sprite.RS3_INV_ICON_SLOT
            background.clickthrough = true
            slot.background = background

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

            local label = ui.Text.new(layer)
            label.font = id.Font.MUSEO_SANS_13PT_REGULAR
            label:AlignTo(ui.AlignMode.CENTRE)
            label.isShadowed = true
            label.maxLines = 1
            label.clickthrough = true
            slot.label = label
        else
            local sprite = ui.Sprite.new(layer)
            local icons = destination.icons
            sprite.spriteID = (row.locked and icons.locked or icons.normal or icons).sprite
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
            local size = destination.icons.size or 48

            slot.icon:SetSize(scaled(size), scaled(size))

            if destination.anchor == "bottomRight" then
                x = gridWidth - inset - size
                y = gridHeight - inset - size
                width, height = size, size
                slot.icon:SetPos(0, 0)
            else
                slot.icon:SetPos(scaled((slotSize - size) / 2), scaled((slotSize - size) / 2))
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
            local name = row.destination.nameOverride or row.name:gsub("^%d+%.%s*", "")
            local hotkey = row.name:match("^(%d+)%.")

            if not row.locked and hotkey ~= nil and userSettings.Get("showTeleportHotkeys") then
                name = hotkey .. ". " .. name
            end

            slot.label.content = name
            slot.label.rgba = row.name == hovered and 0xFFFFFFFF or 0xFFE3A3FF
        else
            local icons = row.destination.icons
            local normal = icons.normal or icons
            local source = row.locked and (icons.locked or normal)
                or (not row.disabled and row.name == hovered and (icons.hovered or normal) or normal)

            slot.icon.spriteID = source.sprite
        end

        slot.layer.alpha = row.disabled and 0.4 or 1

        if slot.background ~= nil then
            slot.background.rgb = row.name == hovered and 0xFFFFFF or 0xC0C0C0
        end
    end

    self.slotLayer:MoveToFront()

    for name, tooltip in pairs(self.session.tooltips) do
        if name == hovered then
            tooltip:Show()
        else
            tooltip:Hide()
        end
    end
end

function NpcSlotMenu:ReleaseVisuals()
    if self.slotLayer ~= nil then
        pcall(function()
            self.slotLayer:Destroy()
        end)
    end

    self.slotLayer, self.slots = nil, nil
end

return NpcSlotMenu
