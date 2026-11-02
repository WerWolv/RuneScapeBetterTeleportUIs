local components = require("impl/components")
local teleportTooltip = require("impl/teleport_tooltip")

local IconGrid = {}
IconGrid.__index = IconGrid

local size, gap, padding = 40, 6, 4

-- Reusable inventory-style picker for either native spell sprites or item artwork.
function IconGrid.New(parent)
    local view = prettyui.SimpleView.new(parent, { width = 1, height = 1 })
    teleportTooltip.BindScroll(view)

    return setmetatable({
        view = view,
        root = view.root,
        slots = {},
        tooltip = teleportTooltip.Shared(view.content, view.viewport),
    }, IconGrid)
end

function IconGrid:Build(entries, onClick)
    for index, entry in ipairs(entries) do
        local root = ui.Layer.new(self.view.content)
        root:SetSize(size, size)
        root.clickthrough = false

        local slot = { root = root, key = entry.key, name = entry.name }
        self.slots[index] = slot

        local background = ui.Sprite.new(root)
        background:SetSize(size, size)
        background.spriteID = id.Sprite.RS3_ICON_SLOT_40PX_1
        background.clickthrough = true

        local source = entry.icons.normal or entry.icons

        if source.objectID ~= nil then
            slot.icon = components.ItemSprite(root, source.objectID, source.objectCount or 1)
            slot.icon:SetPos(4, 4)
            slot.icon:SetSize(32, 32)
        else
            slot.artwork = prettyui.Sprite.new(root, source.sprite or source.image, {
                x = 4, y = 4, width = 32, height = 32,
            })
            slot.icon = slot.artwork.root
        end

        slot.icon.clickthrough = true

        slot.selection = ui.Rectangle.new(root)
        slot.selection:SetSize(size, size)
        slot.selection.fill = false
        slot.selection.rgba = 0xF2C66DFF
        slot.selection.hidden = true
        slot.selection.clickthrough = true

        local function hover(_, x, y)
            if self.enabled then self.tooltip:Show(root, slot.name, x, y) end
            return true
        end
        root:Subscribe(ui.Hook.ONMOUSEOVER, hover)
        root:Subscribe(ui.Hook.ONMOUSEREPEAT, hover)
        root:Subscribe(ui.Hook.ONMOUSELEAVE, function()
            self.tooltip:Hide(root)
            return true
        end)
        root:Subscribe(ui.Hook.ONCLICK, function()
            if self.enabled then
                onClick(index)
            end
            return false
        end)

        for _, control in ipairs({ root, background, slot.icon, slot.selection }) do
            control:Subscribe(ui.Hook.ONSCROLLWHEEL, self.view._onScrollWheel)
        end
    end
end

function IconGrid:Layout(x, y, width, height)
    self.root:SetPos(x, y)
    self.view:SetSize(width, height)

    -- Reserve scrollbar space consistently so a resize cannot oscillate between column counts.
    local columns = math.max(1, math.floor((width - padding * 2 - 16 + gap) / (size + gap)))

    for index, slot in ipairs(self.slots) do
        slot.root:SetPos(
            padding + ((index - 1) % columns) * (size + gap),
            padding + math.floor((index - 1) / columns) * (size + gap)
        )
    end

    local rows = math.ceil(#self.slots / columns)
    self.view:SetContentHeight(padding * 2 + rows * (size + gap) - gap)
end

function IconGrid:SetSelection(members, enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled
        self.view:SetScrollable(enabled)
    end

    if not enabled then self.tooltip:Hide() end

    for _, slot in ipairs(self.slots) do
        slot.root.enabled = enabled
        slot.selection.hidden = members[slot.key] ~= true
        slot.icon.alpha = enabled and 1 or 0.4
    end
end

function IconGrid:Destroy()
    self.enabled = false
    self.tooltip:Destroy()
    for _, slot in ipairs(self.slots) do
        if slot.artwork ~= nil then
            slot.artwork:Destroy()
        end
    end

    self.slots = {}
    self.view:Destroy()
end

return IconGrid
