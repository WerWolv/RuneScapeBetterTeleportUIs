local cleanup = require("impl/cleanup")
local ContentLayer = require("impl/ui/content_layer")

local SlotMenu = {}

-- Own all passive card artwork independently of the native input controls.
function SlotMenu:BeginVisuals()
    if self.definition.scrollable then
        self.slotMount = ContentLayer.New(self.session.content)
        self.slotLayer = self.slotMount.root
    else
        self.slotLayer = prettyui.NewComponent(ui.Layer, self.session.content, { categoryID = "auto" })
    end
    self.slotLayer.clickthrough = true
    self.slots = {}
    self.slotParent = self.slotLayer

    if self.definition.scrollable then
        self.scrollView = prettyui.SimpleView.new(self.slotLayer, {
            width = 1,
            height = 1,
            scrollStep = 32,
            layout = {
                padding = 0,
                startY = 0,
                rowGap = 0,
            },
        })
        self.scrollView.root.clickthrough = true
        self.scrollView.viewport.clickthrough = true
        self.scrollView.content.clickthrough = true
        self.slotParent = self.scrollView.content
    end
end

function SlotMenu:CreateSlot(row, withBackground)
    local layer = prettyui.NewComponent(ui.Layer, self.slotParent)
    layer.clickthrough = true

    local slot = {
        row = row,
        layer = layer,
    }

    self.slots[#self.slots + 1] = slot

    if withBackground then
        local background = prettyui.NewComponent(ui.Sprite, layer)
        background.spriteID = id.Sprite.RS3_INV_ICON_SLOT
        background.clickthrough = true
        slot.background = background
    end

    return slot
end

-- Explicit positions come first. Ties and unpositioned slots retain their original order.
-- Sort only presentation slots: native row order still owns availability and shortcuts.
function SlotMenu:SortSlots()
    local originalOrder = {}
    for index, slot in ipairs(self.slots) do
        originalOrder[slot] = index
    end
    table.sort(self.slots, function(left, right)
        local leftPosition = left.row.destination.position or math.huge
        local rightPosition = right.row.destination.position or math.huge
        if leftPosition ~= rightPosition then
            return leftPosition < rightPosition
        end
        return originalOrder[left] < originalOrder[right]
    end)
end

function SlotMenu:UpdateVisuals(layout, hovered)
    self.slotLayer:MoveToFront()
    self:UpdateTooltips(hovered)
end

function SlotMenu:ReleaseVisuals()
    for _, slot in ipairs(self.slots or {}) do
        cleanup.Release(slot, "artwork")
    end

    cleanup.Release(self, "scrollView")
    if self.slotMount ~= nil then
        cleanup.Release(self, "slotMount")
        self.slotLayer = nil
    else
        cleanup.Release(self, "slotLayer")
    end
    self.slots, self.slotParent = nil, nil
end

function SlotMenu.Create(interface, key)
    local class = interface:Extend(key)

    for name, method in pairs(SlotMenu) do
        if name ~= "Create" then
            class[name] = method
        end
    end

    return class
end

return SlotMenu
