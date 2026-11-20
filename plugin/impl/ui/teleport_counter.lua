local components = require("impl/ui/components")
local cleanup = require("impl/cleanup")

local TeleportCounter = {}
TeleportCounter.__index = TeleportCounter
TeleportCounter.height = 26

function TeleportCounter.New(parent, bottom, framed)
    local root = prettyui.NewComponent(ui.Layer, parent, { categoryID = "auto" })
    root.clickthrough = true

    local panel = root
    if framed then
        -- Keep the shadow inside the root's clipping bounds, behind the inset panel.
        for offset = 4, 1, -1 do
            local shadow = prettyui.NewComponent(ui.Rectangle, root)
            shadow:SetPos(offset, offset)
            shadow:SetSize(-4, -4, 1, 1)
            shadow.fill = true
            shadow.rgba = 0x00000030
            shadow.clickthrough = true
        end
        panel = prettyui.NewComponent(ui.Layer, root)
        panel:SetSize(-4, -4, 1, 1)
        panel.clickthrough = true
    end

    local background = prettyui.NewComponent(ui.Sprite, panel)
    background:SetSize(0, 0, 1, 1)
    background.spriteID = id.Sprite.RS3_MODAL_WINDOW_CONTENT_TILE
    background.isTiling = true
    background.clickthrough = true

    if framed then
        local border = prettyui.NewComponent(ui.Rectangle, panel)
        border:SetSize(0, 0, 1, 1)
        border.fill = false
        border.outlineThickness = 1
        border.rgba = 0x897952FF
        border.clickthrough = true
    else
        -- The right edge and attached horizontal edge join the native frame.
        local left = prettyui.NewComponent(ui.Rectangle, panel)
        left:SetSize(3, 0, 0, 1)
        left.fill = true
        left.rgba = 0x897952FF
        left.clickthrough = true

        local edge = prettyui.NewComponent(ui.Rectangle, panel)
        edge:SetPos(0, bottom and 0 or TeleportCounter.height - 3)
        edge:SetSize(0, 3, 1, 0)
        edge.fill = true
        edge.rgba = 0x897952FF
        edge.clickthrough = true
    end

    local label = components.CenteredLabel(panel, id.Font.MUSEO_SANS_13PT_REGULAR)
    label:SetSize(0, 0, 1, 1)
    label.rgba = 0xFFE3A3FF

    return setmetatable({ root = root, label = label, bottom = bottom }, TeleportCounter)
end

function TeleportCounter:Layout(width, height)
    local boxWidth = math.min(190, math.max(1, width))
    self.root:SetSize(boxWidth, self.height)
    self.root:SetPos(width - boxWidth, self.bottom and height - self.height or 0)
end

function TeleportCounter:Update(remaining)
    if self.remaining ~= remaining then
        local noun = remaining == 1 and "teleport" or "teleports"
        self.label.content = string.format("%d %s remaining", remaining, noun)
        self.remaining = remaining
    end
    self.root:MoveToFront()
end

function TeleportCounter:Destroy()
    cleanup.Release(self, "root")
    self.label = nil
end

return TeleportCounter
