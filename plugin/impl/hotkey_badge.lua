local components = require("impl/components")
local userSettings = require("impl/settings")
local HotkeyBadge = {}
HotkeyBadge.__index = HotkeyBadge

-- Keep badges beside their anchors so the offset artwork is not clipped by the button.
function HotkeyBadge.New(parent, key)
    local root = ui.Layer.new(parent)
    root.clickthrough = true
    root.hidden = true

    local background = ui.Sprite.new(root)
    background:SetSize(0, 0, 1.0, 1.0)
    background.spriteID = id.Sprite.AIF_RING_BTN_LEGACY_0
    background.clickthrough = true

    local label = components.CenteredLabel(root, id.Font.MUSEO_SANS_13PT_BOLD)
    label:SetSize(0, 0, 0.97, 1.0)
    label.content = key ~= nil and tostring(key) or ""

    return setmetatable({ root = root, label = label }, HotkeyBadge)
end

-- Menus supply their anchor and state; all badge styling and placement lives here.
function HotkeyBadge:Update(anchor, options)
    options = options or {}
    local root = self.root
    root.hidden = options.hidden == true or not anchor.visibleGlobal
        or self.label.content == "" or not userSettings.Get("showTeleportHotkeys")

    if root.hidden then
        return
    end

    local width = options.width or anchor.width
    local size = math.max(24, 12 + #self.label.content * 8)
    size = math.max(1, math.floor(math.min(width, size * (options.scale or 1))))

    local position = anchor.xyGlobal
    local parentPosition = root.parent.xyGlobal
    root:SetSize(size, size)
    root:SetPos(
        position.x - parentPosition.x + width - size / 2,
        position.y - parentPosition.y - size / 2
    )

    local disabled = options.disabled
    if disabled == nil then
        disabled = anchor.enabled == false
    end

    root.alpha = disabled and 0.6 or 1
    self.label.rgba = disabled and 0x9D978AFF or 0xFFE3A3FF
    self:MoveToFront()
end

function HotkeyBadge:Hide()
    self.root.hidden = true
end

function HotkeyBadge:MoveToFront()
    self.root:MoveToFront()
end

function HotkeyBadge:Destroy()
    self.root:Destroy()
end

return HotkeyBadge
