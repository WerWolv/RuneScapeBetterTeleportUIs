local cleanup = require("impl/cleanup")

local TargetHighlight = {}
TargetHighlight.__index = TargetHighlight

-- Passive, clipped decoration: never replaces the original button's input or hover style.
function TargetHighlight.Update(owner, parent, width, height, filled)
    local visual = owner.highlightVisual
    if visual ~= nil and visual.parent ~= parent then
        cleanup.Release(owner, "highlightVisual")
        visual = nil
    end
    if parent == nil then return end

    if visual == nil then
        local root = prettyui.NewComponent(ui.Layer, parent)
        root.clickthrough = true
        visual = setmetatable({ root = root, parent = parent }, TargetHighlight)
        owner.highlightVisual = visual

        if filled then
            local fill = prettyui.NewComponent(ui.Rectangle, root)
            fill:SetSize(0, 0, 1, 1)
            fill.fill = true
            fill.rgba = 0xFFFF0030
            fill.clickthrough = true
        end
        local border = prettyui.NewComponent(ui.Rectangle, root)
        border:SetSize(0, 0, 1, 1)
        border.fill = false
        border.outlineThickness = 2
        border.rgba = 0xFFFF00FF
        border.clickthrough = true
    end
    if visual.width ~= width or visual.height ~= height then
        visual.root:SetSize(width, height)
        visual.width, visual.height = width, height
    end
    visual.root:MoveToFront()
end

function TargetHighlight:Destroy()
    cleanup.Release(self, "root")
end

return TargetHighlight
