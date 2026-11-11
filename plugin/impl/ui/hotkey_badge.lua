local components = require("impl/ui/components")
local userSettings = require("impl/settings")

local HotkeyBadge = {}
HotkeyBadge.__index = HotkeyBadge

function HotkeyBadge.Size(key, width, scale)
    local size = math.max(24, 12 + #tostring(key or "") * 8)

    return math.max(1, math.floor(math.min(width, size * (scale or 1))))
end

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

    return setmetatable({
        root = root,
        background = background,
        label = label,
        hidden = true,
    }, HotkeyBadge)
end

-- Menus supply their anchor and state; all badge styling and placement lives here.
function HotkeyBadge:Update(anchor, options)
    options = options or {}
    local root = self.root
    local hidden = options.hidden == true or not anchor.visibleGlobal
        or self.label.content == "" or not (options.forceVisible == true or userSettings.Get("showTeleportHotkeys"))

    if self.hidden ~= hidden then
        root.hidden = hidden
        self.hidden = hidden
    end

    if hidden then
        return
    end

    local width = options.width or anchor.width
    local size = HotkeyBadge.Size(self.label.content, width, options.scale)
    local x, y = width - size / 2, -size / 2

    if options.inset ~= nil then
        local inset = options.inset
        size = math.max(1, math.min(size, width - inset * 2, anchor.height - inset * 2))
        x, y = width - size - inset, inset
    end

    if options.offset ~= nil then
        x = (width - size) / 2 + (options.offset.x or 0)
        y = ((options.height or anchor.height) - size) / 2 + (options.offset.y or 0)
    end

    local parent = root.parent

    if parent == anchor.parent then
        x, y = anchor.x + x, anchor.y + y
    elseif parent ~= anchor then
        local position, parentPosition = anchor.xyGlobal, parent.xyGlobal
        x, y = position.x - parentPosition.x + x, position.y - parentPosition.y + y
    end

    if self.size ~= size then
        root:SetSize(size, size)
        self.size = size
    end

    if self.x ~= x or self.y ~= y then
        root:SetPos(x, y)
        self.x, self.y = x, y
    end

    local disabled = options.disabled

    if disabled == nil then
        disabled = anchor.enabled == false
    end

    if self.disabled ~= disabled then
        self.label.rgba = disabled and 0x9D978AFF or 0xFFE3A3FF
        self.disabled = disabled
    end
    self:SetAlpha(disabled and 0.6 or 1)

    if not options.preserveOrder then
        self:MoveToFront()
    end
end

-- Native layers do not apply their opacity to the graphics they contain.
function HotkeyBadge:SetAlpha(alpha)
    if self.alpha == alpha then
        return
    end

    self.alpha = alpha
    self.background.alpha = alpha
    self.label.alpha = alpha
end

function HotkeyBadge:Hide()
    if not self.hidden then
        self.root.hidden = true
        self.hidden = true
    end
end

function HotkeyBadge:MoveToFront()
    self.root:MoveToFront()
end

function HotkeyBadge:Destroy()
    self.root:Destroy()
end

return HotkeyBadge
