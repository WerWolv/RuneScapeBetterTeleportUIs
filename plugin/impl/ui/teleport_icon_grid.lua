local components = require("impl/ui/components")
local SpriteLayers = require("impl/ui/sprite_layers")
local teleportTooltip = require("impl/ui/teleport_tooltip")
local ScrollInput = require("impl/ui/scroll_input")
local cleanup = require("impl/cleanup")

local IconGrid = {}
IconGrid.__index = IconGrid

local size, gap, padding = 40, 6, 4

-- Reusable inventory-style picker for either native spell sprites or item artwork.
function IconGrid.New(parent)
    local view = prettyui.SimpleView.new(parent, { categoryID = "auto", width = 1, height = 1 })
    teleportTooltip.BindScroll(view)

    return setmetatable({
        view = view,
        root = view.root,
        slots = {},
        tooltip = teleportTooltip.Shared(view.content, view.viewport),
        onScrollWheel = ScrollInput.For(view),
    }, IconGrid)
end

function IconGrid:Build(entries, onClick)
    for index, entry in ipairs(entries) do
        local root = prettyui.NewComponent(ui.Layer, self.view.content)
        root:SetSize(size, size)
        root.clickthrough = false

        local slot = { root = root, key = entry.key, name = entry.name }
        self.slots[index] = slot

        local background = prettyui.NewComponent(ui.Sprite, root)
        background:SetSize(size, size)
        background.spriteID = id.Sprite.RS3_ICON_SLOT_40PX_1
        background.clickthrough = true

        local source = entry.icons.normal or entry.icons

        if source.objectID ~= nil then
            slot.icon = components.ItemSprite(root, source.objectID, source.objectCount or 1)
            slot.icon:SetPos(4, 4)
            slot.icon:SetSize(32, 32)
        else
            slot.artwork = SpriteLayers.New(root, source.sprite or source.image, {
                x = 4, y = 4, width = 32, height = 32,
            })
            slot.icon = slot.artwork.root
        end

        slot.icon.clickthrough = true

        slot.selection = prettyui.NewComponent(ui.Rectangle, root)
        slot.selection:SetSize(size, size)
        slot.selection.fill = false
        slot.selection.rgba = 0xF2C66DFF
        slot.selection.hidden = true
        slot.selection.clickthrough = true

        local function hover(_, x, y)
            if self.enabled then
                self.tooltip:Show(root, slot.name, x, y)
            end

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

        ScrollInput.Bind(root, self.onScrollWheel)
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

    if not enabled then
        self.tooltip:Hide()
    end

    for _, slot in ipairs(self.slots) do
        slot.root.enabled = enabled
        slot.selection.hidden = members[slot.key] ~= true
        if slot.artwork ~= nil then
            slot.artwork:SetAlpha(enabled and 1 or 0.4)
        else
            slot.icon.alpha = enabled and 1 or 0.4
        end
    end
end

function IconGrid:Destroy()
    self.enabled = false
    cleanup.Release(self, "tooltip")

    for _, slot in ipairs(self.slots) do
        cleanup.Release(slot, "artwork")
    end

    self.slots = {}
    cleanup.Release(self, "view")
end

return IconGrid
