local ModelSlotMenu = require("impl/interfaces/presentations/model_slot_menu")
local HotkeyBadge = require("impl/ui/hotkey_badge")

local PortalSlotMenu = {}

function PortalSlotMenu:GetSlotStyle(row, hovered)
    if row.assignedPortal ~= nil then
        return self.definition.slotStyles.assigned
    end

    return ModelSlotMenu.GetSlotStyle(self, row, hovered)
end

function PortalSlotMenu:UpdateVisuals(layout, hovered)
    ModelSlotMenu.UpdateVisuals(self, layout, hovered)

    for _, slot in ipairs(self.slots) do
        local assignment = slot.row.assignedPortal

        if assignment ~= nil then
            local label = self.definition.portalLabels[assignment]

            if slot.portalBadge == nil then
                slot.portalBadge = HotkeyBadge.New(slot.layer, label)
                slot.portalBadgeOptions = { forceVisible = true, disabled = false, preserveOrder = true }
            end

            if slot.portalAssignment ~= assignment then
                slot.portalBadge.label.content = label
                slot.portalAssignment = assignment
            end

            local options = slot.portalBadgeOptions
            options.scale, options.inset = layout.scale, math.ceil(6 * layout.scale)
            slot.portalBadge:Update(slot.layer, options)
            slot.hotkey:Hide()
        elseif slot.portalBadge ~= nil then
            slot.portalBadge:Hide()
        end
    end
end

function PortalSlotMenu.Create(interface, key)
    local class = ModelSlotMenu.Create(interface, key)

    for name, method in pairs(PortalSlotMenu) do
        if name ~= "Create" then
            class[name] = method
        end
    end

    return class
end

return PortalSlotMenu
