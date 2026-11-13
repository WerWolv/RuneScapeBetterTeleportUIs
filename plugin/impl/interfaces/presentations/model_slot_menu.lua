local SlotMenu = require("impl/interfaces/presentations/slot_menu")
local ButtonIcon = require("impl/ui/button_icon")
local HotkeyBadge = require("impl/ui/hotkey_badge")
local SpriteLayers = require("impl/ui/sprite_layers")
local components = require("impl/ui/components")
local ScrollInput = require("impl/ui/scroll_input")
local text = require("impl/text")
local cleanup = require("impl/cleanup")
local defaultStyles = require("definitions/model_slot_styles")
local ModelSlotStyle = require("impl/ui/model_slot_style")

local ModelSlotMenu = {}

local slotSize, rowGap, inset = 112, 8, 12
local modelInset = 6
local scrollbarWidth = 16
local hoverHookID = "teleportModelHover"

local function interfaceScale()
    local options = game and game.options
    local scale = options and options.InterfaceScale
    return math.max(1, tonumber(scale and scale.setting) or 100) / 100
end

function ModelSlotMenu:ShowLabels()
    return self.definition.showLabels ~= false
end

function ModelSlotMenu:GetSlotStyle(row, hovered)
    local styles = self.definition.slotStyles or defaultStyles
    return row.disabled and styles.disabled or row.name == hovered and styles.hovered or styles.normal
end

function ModelSlotMenu:GetLabelStyle()
    return self.definition.labelStyle or defaultStyles.label
end

function ModelSlotMenu:InvalidateVisualLayout()
    self.modelLayout = nil
end

-- NPC/item shortcuts retain existing definitions; modelID accepts any ModelType.
local function hasModel(definition)
    return definition.npcID ~= nil or definition.objectID ~= nil or definition.modelID ~= nil
end

function ModelSlotMenu:ValidateDestination(definition)
    local sources = (definition.npcID ~= nil and 1 or 0)
        + (definition.objectID ~= nil and 1 or 0)
        + (definition.modelID ~= nil and 1 or 0)
        + (definition.placeholderText ~= nil and 1 or 0)

    if sources > 1 then
        return false, "needs only one of npcID, objectID, modelID or placeholderText"
    end

    if definition.modelType ~= nil and definition.modelID == nil then
        return false, "needs modelID when modelType is specified"
    end

    if definition.placeholderText ~= nil
        and (type(definition.placeholderText) ~= "string" or definition.placeholderText == "") then
        return false, "needs nonempty placeholderText"
    end

    if sources == 1 or definition.icons ~= nil or self.definition.icons ~= nil then
        return true
    end

    return false, "needs npcID, objectID, modelID, placeholderText or navigation artwork"
end

-- Available cards retain native actions; adapters can block unavailable cards.
function ModelSlotMenu:BeginVisuals()
    SlotMenu.BeginVisuals(self)
    local labelStyle = self:GetLabelStyle()
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
            local card = hasModel(destination) or destination.placeholderText ~= nil
            local slot = self:CreateSlot(row, card)
            slot.targetRectangle = targets[row]
            slot.hotkeyOptions = { preserveOrder = true }

            local layer = slot.layer
            if self.blockDisabledClicks then
                row.inputBlocker = layer
                slot.tooltipTarget = row.click
                slot.tooltipTitle = self:GetDisplayName(row)
                slot.tooltipDescription = self:GetDescription(row)
            end
            slot.hotkey = HotkeyBadge.New(
                self.slotParent,
                row.native and row.native.shortcut or text.Hotkey(row.name)
            )

            if card then
                -- Clip card artwork to the slot interior; captions are drawn above it.
                local viewport = prettyui.NewComponent(ui.Layer, layer)
                viewport.clickthrough = true
                slot.viewport = viewport

                if destination.placeholderText ~= nil then
                    slot.placeholder = components.CenteredLabel(viewport, destination.placeholderFont or labelStyle.font)
                    slot.placeholder.content = destination.placeholderText
                else
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
                end

                if self.definition.overlayLabels then
                    slot.labelBackground = prettyui.NewComponent(ui.Rectangle, layer)
                    slot.labelBackground.fill = true
                    slot.labelBackground.rgba = labelStyle.backgroundRGBA
                    slot.labelBackground.clickthrough = true
                end
                slot.label = components.CenteredLabel(layer, labelStyle.font)
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

    if self.scrollView ~= nil then
        local view = self.scrollView
        local menu = self
        local setScrollPosition = view.SetScrollPosition

        function view.SetScrollPosition(scrollView, position)
            local previous = scrollView.scrollY
            local result = setScrollPosition(scrollView, position)

            if previous ~= scrollView.scrollY then
                -- Native targets are repositioned on the next layout pass.
                menu:UpdateTooltips(nil)
            end

            return result
        end

        self.onScrollWheel = ScrollInput.For(view)
        ScrollInput.Bind(self.slotLayer, self.onScrollWheel)
        self:BindScrollInput(self.onScrollWheel)

        -- Calibrate screen pixels from unscrolled native targets. This also
        -- accounts for OS scaling beyond the client's interface-scale setting.
        self.hoverControls = { view.viewport }
        for _, row in ipairs(self.session.rows) do
            self.hoverControls[#self.hoverControls + 1] = row.click
        end
        local function calibrate(control, x, y)
            local mouse = Mouse and Mouse.GetPosition()
            if mouse ~= nil and type(x) == "number" and type(y) == "number" then
                local origin = control.xyGlobal
                local mouseX, mouseY = origin.x + x, origin.y + y
                local scale
                -- Prefer X: vertical target positions can change during a wheel burst.
                if math.abs(mouseX) >= 32 then
                    scale = mouse.x / mouseX
                elseif math.abs(mouseY) >= 32 then
                    scale = mouse.y / mouseY
                end
                if scale ~= nil and scale > 0 then
                    self.hoverScale, self.hoverInterfaceScale = scale, interfaceScale()
                end
            end
            return true
        end
        for _, control in ipairs(self.hoverControls) do
            control:Subscribe(ui.Hook.ONMOUSEOVER, hoverHookID, calibrate)
            control:Subscribe(ui.Hook.ONMOUSEREPEAT, hoverHookID, calibrate)
        end
    end
end

-- Menus can set columns and rows; otherwise use a fixed minimum grid size.
function ModelSlotMenu:CalculateLayout()
    local session = self.session
    local columns = self.definition.columns or 5
    local rows = self.definition.rows or 2
    local totalRows = math.max(rows, math.ceil(#self.slots / columns))

    if not self.definition.scrollable then
        rows = totalRows
    end

    local scrollWidth = self.definition.scrollable and scrollbarWidth or 0
    local showLabels = self:ShowLabels()
    local overlayLabels = self.definition.overlayLabels == true
    local labelStyle = self:GetLabelStyle()
    local rightInset = self.definition.rightInset or inset
    local gridWidth = columns * slotSize + inset * 2
    local availableWidth = (session.layoutWidth or session.layoutParent.width)
        - session.left - session.right - 16 - scrollWidth
    local availableHeight = (session.layoutHeight or session.layoutParent.height) - session.top - session.bottom - 16
    local cached = self.modelLayout

    if cached ~= nil and cached.availableWidth == availableWidth and cached.availableHeight == availableHeight
        and cached.columns == columns and cached.rows == rows and cached.totalRows == totalRows
        and cached.scrollWidth == scrollWidth and cached.showLabels == showLabels
        and cached.overlayLabels == overlayLabels and cached.labelStyle == labelStyle
        and cached.rightInset == rightInset then
        return cached.layout
    end

    local scale = math.max(0.01, math.min(1, availableWidth / gridWidth))
    local nameHeight, artworkHeight, verticalGap, rowLabelHeights

    -- Text does not scale with the models. Wrap at the displayed width and reserve its full height.
    while true do
        local width = math.max(1, math.floor(slotSize * scale))
        if overlayLabels then
            width = math.max(1, math.floor(slotSize * scale)
                - math.ceil(labelStyle.inset * scale) * 2 - labelStyle.paddingX * 2)
        end
        nameHeight, verticalGap = 0, 0
        rowLabelHeights = {}

        for index, slot in ipairs(self.slots) do
            if slot.label ~= nil then
                slot.label.hidden = not showLabels
                slot.labelTextHeight = 0
            end
            if slot.labelBackground ~= nil then
                slot.labelBackground.hidden = not showLabels
            end

            if slot.label ~= nil and showLabels then
                local font = config.Font.FromID(slot.label.font)
                local lines = font:SplitString(self:GetDisplayName(slot.row), width, false, false, false)
                slot.label.content = table.concat(lines, "<br>")
                local height = font:GetStringHeightAndLineCount(
                    slot.label.content, width, font.baseline, false, false, false
                )
                local padding = 0

                if #lines > 1 and not self.definition.scrollable and not overlayLabels then
                    padding = 4
                    verticalGap = rowGap
                end

                slot.labelTextHeight = height
                if not overlayLabels then
                    nameHeight = math.max(nameHeight, height + padding)
                    local row = math.ceil(index / columns)
                    rowLabelHeights[row] = math.max(rowLabelHeights[row] or 0, height)
                end
            end
        end

        artworkHeight = rows * slotSize + (rows - 1) * verticalGap + inset * 2
        local fittedScale = math.max(0.01, math.min(scale, (availableHeight - rows * nameHeight) / artworkHeight))
        if self.definition.scrollable then
            -- Labels extend the scrollable content rather than shrinking the models.
            fittedScale = math.max(0.01, math.min(scale, availableHeight / artworkHeight))
        end

        if fittedScale >= scale then
            break
        end

        scale = fittedScale
    end

    local gridHeight = artworkHeight + rows * nameHeight / scale
    local contentHeight = (inset * 2 + totalRows * slotSize + (totalRows - 1) * verticalGap) * scale
        + totalRows * nameHeight
    local cardRows

    if self.definition.scrollable then
        cardRows = {}
        local top = inset
        for index = 1, totalRows do
            local labelHeight = (rowLabelHeights[index] or 0) / scale
            cardRows[index] = { top = top, labelHeight = labelHeight }
            top = top + slotSize + labelHeight
            if index == rows then
                gridHeight = math.min(top + inset, availableHeight / scale)
            end
        end
        contentHeight = (top + inset) * scale
    end

    local rightTrim = self.definition.scrollable and math.floor((inset - rightInset) * scale) or 0
    local layout = {
        width = math.max(1, math.floor(gridWidth * scale) - rightTrim) + scrollWidth,
        height = math.max(1, math.floor(gridHeight * scale)),
        contentHeight = math.ceil(contentHeight),
        cardRows = cardRows,
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
        totalRows = totalRows,
        scrollWidth = scrollWidth,
        showLabels = showLabels,
        overlayLabels = overlayLabels,
        labelStyle = labelStyle,
        rightInset = rightInset,
        layout = layout,
    }

    return layout
end

-- Align each full card, including its name, with its client-owned teleport operation.
function ModelSlotMenu:ApplyLayout(layout)
    self:LayoutWindow(layout.width, layout.height)
    local labelStyle = self:GetLabelStyle()

    local resized = self.appliedModelLayout ~= layout

    if resized then
        self.slotLayer:SetSize(layout.width, layout.height)
    end

    local origin = self.slotLayer.xyGlobal
    local rectangles = self.modelRectangles
    local originX, originY = origin.x, origin.y
    local clipX, clipY, clipWidth, clipHeight

    if self.scrollView ~= nil then
        local view = self.scrollView

        if resized then
            view:SetSize(layout.width, layout.height)
            view:SetContentHeight(layout.contentHeight)
            view:SetScrollPosition(view.scrollY)
        end

        local position = view.viewport.xyGlobal
        clipX, clipY = position.x, position.y
        clipWidth, clipHeight = view.viewport.width, view.viewport.height
        originX = position.x + view.content.x
        originY = position.y + view.content.y - view.scrollY
    end

    for _, rectangle in ipairs(rectangles) do
        rectangle.x, rectangle.y, rectangle.width, rectangle.height = originX, originY, 0, 0
    end

    local function scaled(value)
        return math.floor(value * layout.scale)
    end

    for slotIndex, slot in ipairs(self.slots) do
        local row = slot.row
        if self.blockDisabledClicks then
            local target = row.disabled and slot.layer or row.click
            local title = self:GetDisplayName(row)
            local description = self:GetDescription(row)

            if slot.tooltipTarget ~= target or slot.tooltipTitle ~= title or slot.tooltipDescription ~= description then
                -- The inert card receives hover/wheel events instead of invoking
                -- the unavailable native action. Keep cursor tracking on its owner.
                local tooltip = self.session.tooltips[row.name]
                if tooltip ~= nil then
                    tooltip:Destroy()
                    self.session.tooltips[row.name] = nil
                    self:AttachTooltip(row, target)
                end
                -- Destroy restores the old tooltip target's clickthrough value.
                slot.layer.clickthrough = not row.disabled
                slot.tooltipTarget = target
                slot.tooltipTitle = title
                slot.tooltipDescription = description
            end
        end
        local destination = row.destination
        local index = slotIndex - 1
        local cardRow = layout.cardRows and layout.cardRows[math.floor(index / layout.columns) + 1]
        local labelHeight = cardRow and cardRow.labelHeight or layout.labelHeight
        local x = inset + (index % layout.columns) * slotSize
        local y = cardRow and cardRow.top
            or inset + math.floor(index / layout.columns) * (slotSize + labelHeight + layout.rowGap)
        local width, height = slotSize, slotSize + labelHeight

        local iconWidth, iconHeight

        if slot.label == nil then
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
            if slot.label ~= nil then
                slot.background:SetSize(scaled(slotSize), scaled(slotSize))
                slot.viewport:SetPos(scaled(modelInset), scaled(modelInset))
                slot.viewport:SetSize(scaled(slotSize - modelInset * 2), scaled(slotSize - modelInset * 2))
                if slot.model ~= nil then
                    slot.model:SetPos(0, 0)
                    slot.model:SetSize(slot.viewport.width, slot.viewport.height)

                    local offset = destination.modelOffset
                    local screenOffset = slot.model.screenOffset
                    screenOffset.x = scaled(offset and offset.x or 0)
                    screenOffset.y = scaled(offset and offset.y or 0)
                    screenOffset.z = 0
                    slot.model.screenOffset = screenOffset
                end

                if slot.labelBackground ~= nil then
                    local left = math.ceil(labelStyle.inset * layout.scale)
                    local bottom = scaled(slotSize) - left
                    local stripWidth = math.max(0, scaled(slotSize) - left * 2)
                    local stripHeight = math.min(math.max(0, bottom - left),
                        slot.labelTextHeight + labelStyle.paddingY * 2)
                    slot.labelBackground:SetPos(left, bottom - stripHeight)
                    slot.labelBackground:SetSize(stripWidth, stripHeight)
                    slot.labelBackground:MoveToFront()
                    slot.label:SetPos(left + labelStyle.paddingX, bottom - stripHeight + labelStyle.paddingY)
                    slot.label:SetSize(math.max(1, stripWidth - labelStyle.paddingX * 2),
                        math.max(1, stripHeight - labelStyle.paddingY * 2))
                    slot.label:MoveToFront()
                else
                    slot.label:SetPos(0, scaled(slotSize))
                    slot.label:SetSize(scaled(width), scaled(labelHeight))
                end
                if slot.placeholder ~= nil then
                    local placeholderHeight = slot.viewport.height
                    if slot.labelBackground ~= nil and not slot.labelBackground.hidden then
                        placeholderHeight = math.max(1, slot.labelBackground.y - slot.viewport.y)
                    end
                    slot.placeholder:SetPos(0, 0)
                    slot.placeholder:SetSize(slot.viewport.width, placeholderHeight)
                end
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
            local left, top = originX + scaled(x), originY + scaled(y)
            local right, bottom = left + scaled(width), top + scaled(height)

            if clipX ~= nil then
                left, top = math.max(left, clipX), math.max(top, clipY)
                right, bottom = math.min(right, clipX + clipWidth), math.min(bottom, clipY + clipHeight)
            end

            rectangle.x, rectangle.y = left, top
            rectangle.width, rectangle.height = math.max(0, right - left), math.max(0, bottom - top)
        end
    end

    self.appliedModelLayout = layout
    self:LayoutRows(rectangles, layout.width, layout.height)
end

function ModelSlotMenu:GetHovered()
    local mouse = self.scrollView ~= nil and Mouse and Mouse.GetPosition()
    if mouse then
        if not self.slotLayer.visibleGlobal or self.scrollView.dragStart ~= nil then
            return nil
        end

        local scale = interfaceScale()
        if self.hoverInterfaceScale == scale then
            scale = self.hoverScale
        end
        local x, y = mouse.x / scale, mouse.y / scale
        -- Wheel bursts can move a card into view without fresh native hover
        -- events. Use the same clipped rectangles as the native action hitboxes.
        for _, rectangle in ipairs(self.modelRectangles) do
            if x >= rectangle.x and y >= rectangle.y
                and x < rectangle.x + rectangle.width and y < rectangle.y + rectangle.height then
                local row = rectangle.entry
                local tooltip = self.session.tooltips[row.name]
                if tooltip ~= nil then
                    local target = row.disabled and row.inputBlocker or row.click
                    local origin = target.xyGlobal
                    tooltip.cursorX, tooltip.cursorY = x - origin.x, y - origin.y
                end
                return row.name
            end
        end
        return nil
    end

    for _, row in ipairs(self.session.rows) do
        local target = row.disabled and row.inputBlocker or row.click
        if not row.destination.hidden and target.visibleGlobal and target.isMouseOver then
            return row.name
        end
    end
end

-- Render the menu-selected appearance without interpreting interface-specific states.
function ModelSlotMenu:UpdateVisuals(layout, hovered)
    for _, slot in ipairs(self.slots) do
        local row = slot.row
        local highlighted = row.name == hovered and not row.disabled

        if slot.label ~= nil then
            ModelSlotStyle.Apply(slot, self:GetSlotStyle(row, hovered))
        else
            local icons = row.destination.icons
            local source, dimmed = ButtonIcon.Source(icons, highlighted, row.disabled, row.locked)

            local image = source.sprite or source.image

            if slot.image ~= image then
                slot.artwork:SetSprite(image)
                slot.image = image
            end

            slot.artwork:SetAlpha(dimmed and 0.4 or 1)
        end

        local options = slot.hotkeyOptions
        options.scale, options.inset = layout.scale, math.floor(4 * layout.scale)
        options.disabled, options.hidden = row.disabled, row.locked
        slot.hotkey:Update(slot.layer, options)

        slot.highlighted = highlighted
    end

    SlotMenu.UpdateVisuals(self, layout, hovered)
end

function ModelSlotMenu:ReleaseVisuals()
    for _, control in ipairs(self.hoverControls or {}) do
        cleanup.Try("unsubscribe model hover", function()
            control:Unsubscribe(ui.Hook.ONMOUSEOVER, hoverHookID)
            control:Unsubscribe(ui.Hook.ONMOUSEREPEAT, hoverHookID)
        end)
    end
    self.hoverControls, self.hoverScale, self.hoverInterfaceScale = nil, nil, nil
    if self.blockDisabledClicks then
        cleanup.Try("release card tooltips", function()
            self:ReleaseTooltips()
        end)
    end
    SlotMenu.ReleaseVisuals(self)
    self.modelLayout, self.appliedModelLayout, self.modelRectangles = nil, nil, nil
    self.onScrollWheel = nil
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
