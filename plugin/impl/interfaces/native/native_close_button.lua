local components = require("impl/ui/components")
local cleanup = require("impl/cleanup")

local NativeCloseButton = {}
NativeCloseButton.__index = NativeCloseButton

-- Capture before resizing the host: native layout scripts can reposition the
-- close button before the plugin makes its first explicit write.
function NativeCloseButton.New(control)
    if control == nil then
        return nil
    end

    local self = setmetatable({ control = control, originals = {} }, NativeCloseButton)

    components.Walk(control, function(child)
        local position, size = child.position, child.size

        self.originals[#self.originals + 1] = {
            control = child,
            parent = child.parent,
            interfaceID = child.interfaceID,
            staticID = child.staticID,
            categoryID = child.categoryID,
            dynamicID = child.dynamicID,
            position = {
                position.x, position.y, position.xParentPc, position.yParentPc,
                position.xSelfPc, position.ySelfPc,
            },
            size = { size.width, size.height, size.widthParentPc, size.heightParentPc },
            alpha = child.alpha,
            hidden = child.hidden,
            clickthrough = child.clickthrough,
            label = child.type == ui.ComponentType.BUTTON and child.label or nil,
            spriteAlpha = child.type == ui.ComponentType.BUTTON and child.sprite.alpha or nil,
        }
    end)

    return self
end

-- Use the native action as a transparent hitbox over the replacement artwork.
-- Keep runtime sprites and styles intact so the original UI can be restored.
function NativeCloseButton:Layout(target)
    local control = self.control
    local origin, parent = target.xyGlobal, control.parent.xyGlobal

    control:SetPos(origin.x - parent.x, origin.y - parent.y)
    control:SetSize(target.width, target.height)
    control.clickthrough = false
    control.alpha = 0

    if control.type == ui.ComponentType.BUTTON then
        control.sprite.alpha = 0
        control.label = ""
    end

    for index = 2, #self.originals do
        self.originals[index].control.hidden = true
    end

    return control.isMouseOver
end

-- Restore after the host and replacement window have finished their teardown.
function NativeCloseButton:Restore()
    for _, original in ipairs(self.originals) do
        cleanup.Try("restore native close button", function()
            local current

            if original.categoryID >= 0 and original.dynamicID >= 0 then
                current = ui.Interfaces:GetComponent(
                    original.interfaceID, original.staticID, original.categoryID, original.dynamicID)
            else
                current = ui.Interfaces:GetComponent(original.interfaceID, original.staticID)
            end

            local control = original.control
            if current ~= control or control.parent ~= original.parent then
                return
            end

            control:SetPos(table.unpack(original.position))
            control:SetSize(table.unpack(original.size))
            control.alpha = original.alpha
            control.hidden = original.hidden
            control.clickthrough = original.clickthrough

            if original.spriteAlpha ~= nil then
                control.sprite.alpha = original.spriteAlpha
            end

            if original.label ~= nil then
                control.label = original.label
            end
        end)
    end

    self.originals = {}
end

return NativeCloseButton
