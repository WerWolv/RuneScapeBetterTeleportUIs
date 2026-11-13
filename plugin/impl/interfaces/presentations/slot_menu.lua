local cleanup = require("impl/cleanup")
local SlotMenu = {}

-- Own all passive card artwork independently of the native input controls.
function SlotMenu:BeginVisuals()
    self.slotLayer = prettyui.NewComponent(ui.Layer, self.session.content, { categoryID = "auto" })
    self.slotLayer.clickthrough = true
    self.slots = {}
end

function SlotMenu:CreateSlot(row, withBackground)
    local layer = prettyui.NewComponent(ui.Layer, self.slotLayer)
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

function SlotMenu:UpdateVisuals(layout, hovered)
    self.slotLayer:MoveToFront()
    self:UpdateTooltips(hovered)
end

function SlotMenu:ReleaseVisuals()
    for _, slot in ipairs(self.slots or {}) do
        cleanup.Release(slot, "artwork")
    end

    cleanup.Release(self, "slotLayer")
    self.slots = nil
end

function SlotMenu.Create(interface, key)
    local class = interface:Extend(key)
    for name, method in pairs(SlotMenu) do
        if name ~= "Create" then class[name] = method end
    end
    return class
end

return SlotMenu
