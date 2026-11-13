local SlotMenu = require("impl/interfaces/presentations/slot_menu")
local ButtonIcon = require("impl/ui/button_icon")
local HotkeyBadge = require("impl/ui/hotkey_badge")
local SpriteLayers = require("impl/ui/sprite_layers")
local components = require("impl/ui/components")
local text = require("impl/text")
local NativeLayout = require("impl/interfaces/native/native_layout")

local ModelSlotMenu = {}

local slotSize, rowGap, inset = 112, 8, 12
local modelInset = 6

-- The model cards identify the choices without the native selection prompt.
function ModelSlotMenu:UpdateTitle()
    self.interface.UpdateTitle(self)

    local title = self.session.title

    if title ~= nil then
        NativeLayout.Set(title.control, "alpha", 0)
    end
end

-- NPC/item shortcuts retain existing definitions; modelID accepts any ModelType.
local function hasModel(definition)
    return definition.npcID ~= nil or definition.objectID ~= nil or definition.modelID ~= nil
end

function ModelSlotMenu:ValidateDestination(definition)
    local sources = (definition.npcID ~= nil and 1 or 0)
        + (definition.objectID ~= nil and 1 or 0)
        + (definition.modelID ~= nil and 1 or 0)

    if sources > 1 then
        return false, "needs only one of npcID, objectID or modelID"
    end

    if definition.modelType ~= nil and definition.modelID == nil then
        return false, "needs modelID when modelType is specified"
    end

    if sources == 1 or definition.icons ~= nil or self.definition.icons ~= nil then
        return true
    end

    return false, "needs npcID, objectID, modelID or navigation artwork"
end

-- Build passive model cards; the original native rows remain the only click targets.
function ModelSlotMenu:BeginVisuals()
    SlotMenu.BeginVisuals(self)
    self.modelLayout, self.appliedModelLayout = nil, nil
    self.modelRectangles = {}

    local targets = {}

    for _, row in ipairs(self.session.rows) do
        local rectangle = { entry = row }
        targets[row] = rectangle
        self.modelRectangles[#self.modelRectangles + 1] = rectangle
    end

    for _, row in ipairs(self.session.menu.rows) do
        local destination = row.destination

        if not destination.hidden then
            local slot = self:CreateSlot(row, hasModel(destination))
            slot.targetRectangle = targets[row]
            slot.hotkeyOptions = { preserveOrder = true }

            local layer = slot.layer
            slot.hotkey = HotkeyBadge.New(
                self.slotLayer,
                row.native and row.native.shortcut or text.Hotkey(row.name)
            )

            if hasModel(destination) then
                -- Clip model drawing to the slot interior, excluding its border and name label.
                local viewport = prettyui.NewComponent(ui.Layer, layer)
                viewport.clickthrough = true
                slot.viewport = viewport

                local model = prettyui.NewComponent(ui.Model, viewport)
                model.clickthrough = true

                if destination.npcID ~= nil then
                    model:SetModel(ui.ModelType.NPC_MODEL, destination.npcID)
                elseif destination.objectID ~= nil then
                    model:SetAssociatedObject(destination.objectID, destination.quantity or 1)
                else
                    model:SetModel(
                        destination.modelType or ui.ModelType.MODEL,
                        destination.modelID,
                        destination.secondaryModelID
                    )
                end

                model.modelWidth = slotSize
                model.modelHeight = slotSize
                model.viewDistance = destination.viewDistance or 600

                if destination.animID ~= nil then
                    model.animID = destination.animID
                end

                for _, property in ipairs({ "rotation", "worldOffset" }) do
                    if destination[property] ~= nil then
                        local value = model[property]
                        local configured = destination[property]
                        value.x, value.y, value.z = configured.x or 0, configured.y or 0, configured.z or 0
                        model[property] = value
                    end
                end

                if destination.orthographic ~= nil then
                    model.orthographic = destination.orthographic
                end

                slot.model = model

                slot.label = components.CenteredLabel(layer, id.Font.MUSEO_SANS_11PT_REGULAR)
                slot.label.maxLines = 0
            else
                local icons = destination.icons
                local source = ButtonIcon.Source(icons, false, row.disabled, row.locked)
                local width, height = ButtonIcon.Dimensions(icons)
                slot.artwork = SpriteLayers.New(layer, source.sprite or source.image, {
                    width = width,
                    height = height,
                })
                slot.icon = slot.artwork.root
            end
        end
    end
end

-- Menus can set columns and rows; the default keeps both Slayer Cape pages the same size.
function ModelSlotMenu:CalculateLayout()
    local session = self.session
    local columns = self.definition.columns or 5
    local rows = math.max(self.definition.rows or 2, math.ceil(#self.slots / columns))
    local gridWidth = columns * slotSize + inset * 2
    local availableWidth = (session.layoutWidth or session.layoutParent.width) - session.left - session.right - 16
    local availableHeight = (session.layoutHeight or session.layoutParent.height) - session.top - session.bottom - 16
    local cached = self.modelLayout

    if cached ~= nil and cached.availableWidth == availableWidth and cached.availableHeight == availableHeight
        and cached.columns == columns and cached.rows == rows then
        return cached.layout
    end

    local scale = math.max(0.01, math.min(1, availableWidth / gridWidth))
    local nameHeight, artworkHeight, verticalGap

    -- Text does not scale with the models. Wrap at the displayed width and reserve its full height.
    while true do
        local width = math.max(1, math.floor(slotSize * scale))
        nameHeight, verticalGap = 0, 0

        for _, slot in ipairs(self.slots) do
            if slot.label ~= nil then
                local font = config.Font.FromID(slot.label.font)
                local lines = font:SplitString(self:GetDisplayName(slot.row), width, false, false, false)
                slot.label.content = table.concat(lines, "<br>")
                local height = font:GetStringHeightAndLineCount(
                    slot.label.content, width, font.baseline, false, false, false
                )
                local padding = 0

                if #lines > 1 then
                    padding = 4
                    verticalGap = rowGap
                end

                nameHeight = math.max(nameHeight, height + padding)
            end
        end

        artworkHeight = rows * slotSize + (rows - 1) * verticalGap + inset * 2
        local fittedScale = math.max(0.01, math.min(scale, (availableHeight - rows * nameHeight) / artworkHeight))

        if fittedScale >= scale then
            break
        end

        scale = fittedScale
    end

    local gridHeight = artworkHeight + rows * nameHeight / scale

    local layout = {
        width = math.max(1, math.floor(gridWidth * scale)),
        height = math.max(1, math.floor(gridHeight * scale)),
        scale = scale,
        columns = columns,
        gridWidth = gridWidth,
        gridHeight = gridHeight,
        labelHeight = nameHeight / scale,
        rowGap = verticalGap,
    }

    self.modelLayout = {
        availableWidth = availableWidth,
        availableHeight = availableHeight,
        columns = columns,
        rows = rows,
        layout = layout,
    }

    return layout
end

-- Align each full card, including its name, with its client-owned teleport operation.
function ModelSlotMenu:ApplyLayout(layout)
    self:LayoutWindow(layout.width, layout.height)

    local resized = self.appliedModelLayout ~= layout

    if resized then
        self.slotLayer:SetSize(layout.width, layout.height)
    end

    local origin = self.slotLayer.xyGlobal
    local rectangles = self.modelRectangles

    for _, rectangle in ipairs(rectangles) do
        rectangle.x, rectangle.y, rectangle.width, rectangle.height = origin.x, origin.y, 0, 0
    end

    local function scaled(value)
        return math.floor(value * layout.scale)
    end

    for slotIndex, slot in ipairs(self.slots) do
        local row = slot.row
        local destination = row.destination
        local index = slotIndex - 1
        local x = inset + (index % layout.columns) * slotSize
        local y = inset + math.floor(index / layout.columns) * (slotSize + layout.labelHeight + layout.rowGap)
        local width, height = slotSize, slotSize + layout.labelHeight

        local iconWidth, iconHeight

        if slot.model == nil then
            iconWidth, iconHeight = ButtonIcon.Dimensions(destination.icons)

            if destination.anchor == "bottomRight" then
                x = layout.gridWidth - inset - iconWidth
                y = layout.gridHeight - inset - iconHeight
                width, height = iconWidth, iconHeight
            end
        end

        -- Model animation advances in the client. Only resize/reposition its
        -- component when the card layout changes, rather than invalidating it every Draw.
        if resized then
            if slot.model ~= nil then
                slot.background:SetSize(scaled(slotSize), scaled(slotSize))
                slot.viewport:SetPos(scaled(modelInset), scaled(modelInset))
                slot.viewport:SetSize(scaled(slotSize - modelInset * 2), scaled(slotSize - modelInset * 2))
                slot.model:SetPos(0, 0)
                slot.model:SetSize(slot.viewport.width, slot.viewport.height)

                local offset = destination.modelOffset
                local screenOffset = slot.model.screenOffset
                screenOffset.x = scaled(offset and offset.x or 0)
                screenOffset.y = scaled(offset and offset.y or 0)
                screenOffset.z = 0
                slot.model.screenOffset = screenOffset

                slot.label:SetPos(0, scaled(slotSize))
                slot.label:SetSize(scaled(width), scaled(layout.labelHeight))
            else
                slot.icon:SetSize(scaled(iconWidth), scaled(iconHeight))

                if destination.anchor == "bottomRight" then
                    slot.icon:SetPos(0, 0)
                else
                    slot.icon:SetPos(scaled((slotSize - iconWidth) / 2), scaled((slotSize - iconHeight) / 2))
                end
            end

            slot.layer:SetPos(scaled(x), scaled(y))
            slot.layer:SetSize(scaled(width), scaled(height))
        end

        local rectangle = slot.targetRectangle

        if rectangle ~= nil then
            rectangle.x, rectangle.y = origin.x + scaled(x), origin.y + scaled(y)
            rectangle.width, rectangle.height = scaled(width), scaled(height)
        end
    end

    self.appliedModelLayout = layout
    self:LayoutRows(rectangles, layout.width, layout.height)
end

function ModelSlotMenu:GetHovered()
    for _, row in ipairs(self.session.rows) do
        if not row.destination.hidden and row.click.visibleGlobal and row.click.isMouseOver then
            return row.name
        end
    end
end

-- Use native availability and hover for card styling and the existing PrettyUI tooltips.
function ModelSlotMenu:UpdateVisuals(layout, hovered)
    for _, slot in ipairs(self.slots) do
        local row = slot.row
        local dimmed = row.disabled
        local highlighted = row.name == hovered

        if slot.label ~= nil then
            if slot.highlighted ~= highlighted then
                slot.label.rgba = highlighted and 0xFFFFFFFF or 0xFFE3A3FF
            end
        else
            local icons = row.destination.icons
            local source
            source, dimmed = ButtonIcon.Source(icons, highlighted, row.disabled, row.locked)

            local image = source.sprite or source.image

            if slot.image ~= image then
                slot.artwork:SetSprite(image)
                slot.image = image
            end

            slot.artwork:SetAlpha(dimmed and 0.4 or 1)
        end

        if slot.dimmed ~= dimmed then
            slot.layer.alpha = dimmed and 0.4 or 1
            slot.dimmed = dimmed
        end

        local options = slot.hotkeyOptions
        options.scale, options.inset = layout.scale, math.floor(4 * layout.scale)
        options.disabled, options.hidden = row.disabled, row.locked
        slot.hotkey:Update(slot.layer, options)

        if slot.background ~= nil and slot.highlighted ~= highlighted then
            slot.background.rgb = highlighted and 0xFFFFFF or 0xC0C0C0
        end

        slot.highlighted = highlighted
    end

    SlotMenu.UpdateVisuals(self, layout, hovered)
end

function ModelSlotMenu:ReleaseVisuals()
    SlotMenu.ReleaseVisuals(self)
    self.modelLayout, self.appliedModelLayout, self.modelRectangles = nil, nil, nil
end

function ModelSlotMenu.Create(interface, key)
    local class = SlotMenu.Create(interface, key)

    for name, method in pairs(ModelSlotMenu) do
        if name ~= "Create" then
            class[name] = method
        end
    end

    return class
end

return ModelSlotMenu
