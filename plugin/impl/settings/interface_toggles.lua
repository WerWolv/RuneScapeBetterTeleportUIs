local text = require("impl/text")
local ScrollInput = require("impl/ui/scroll_input")
local teleportTooltip = require("impl/ui/teleport_tooltip")
local cleanup = require("impl/cleanup")
local constants = require("definitions/constants")

local InterfaceToggles = {}
InterfaceToggles.__index = InterfaceToggles

local rowHeight = 48
local rowColours = { 0x171512E8, 0x28241FE8 }

local function canSpawnItems()
    return constants.debugMode and type(ExecuteConsoleCommand) == "function"
end

function InterfaceToggles:New(definition, settings)
    return setmetatable({ definition = definition, settings = settings }, self)
end

function InterfaceToggles:CreateItemSlot(parent, setting, list)
    local object = config.Obj.FromID(setting.definition.item)
    local slot = prettyui.ItemSlot.new(parent, object, { x = 8, y = 4, clickthrough = false })
    local root = slot.root

    root:Subscribe(ui.Hook.ONMOUSELEAVE, function()
        if self.list == list then
            self.itemTooltip:Hide(root)
        end
        return true
    end)
    root:Subscribe(ui.Hook.ONCLICK, function()
        if self.list == list and root.visibleGlobal and canSpawnItems() then
            ExecuteConsoleCommand("!give " .. object.configName .. " 1")
        end
        return false
    end)

    return slot
end

-- This widget owns the table, item slots, toggles and cogs; settings keep their saved keys.
function InterfaceToggles:Mount(page, y, openDetails)
    self.page, self.y = page, y

    page:SetScrollable(false)
    self.view = prettyui.SimpleView.new(page.content, {
        x = 14, y = y, width = -28, widthAnchor = 1, height = 1,
        scrollable = false,
        layout = { padding = 0, startY = 0 },
    })

    local heading = self.view:AddTitle({ text = self.definition.label, height = 24, marginTop = 0, marginBottom = 0 })

    if not text.IsBlank(self.definition.description) then
        heading = self.view:AddText({
            text = self.definition.description,
            font = id.Font.MUSEO_SANS_11PT_REGULAR,
            colour = 0xAFA79AFF,
            shadowed = false,
            marginBottom = 0,
        })
    end

    self.contentY = heading.y + heading.height + 4

    local entries = {}

    for index, setting in ipairs(self.settings) do
        assert(setting.definition.type == "boolean", "Interface toggles require boolean settings")

        entries[index] = {
            id = setting.definition.key,
            text = "",
            enabled = false,
            backgroundColour = rowColours[(index - 1) % #rowColours + 1],
        }
    end

    local list = prettyui.List.new(self.view.content, {
        y = self.contentY, width = 0, widthAnchor = 1, height = 1,
        entryHeight = rowHeight, entries = entries,
    })

    self.list, self.rows = list, {}
    teleportTooltip.BindScroll(list)
    self.itemTooltip = teleportTooltip.Shared(self.view.content, list.viewport)

    local scroll = ScrollInput.For(list, 12)
    local function onScrollWheel(component, delta)
        scroll(component, delta)
        return false
    end

    -- PrettyUI's existing row/background/scrollbar hooks dispatch through this method.
    -- Replace their full-row scrolling, rather than adding a second listener to them.
    list._OnScrollWheel = function(_, component, delta)
        return onScrollWheel(component, delta)
    end

    for index, setting in ipairs(self.settings) do
        local row = list.rows[index]
        row.label.hidden = true

        local control = prettyui.CheckboxButton.new(row.root, {
            { text = setting.definition.label, value = setting.definition.key, selected = setting:Get() },
        }, {
            x = 56, y = 13, width = -96, widthAnchor = 1,
            onChange = function(_, _, _, selected)
                if self.list == list then
                    setting:Set(selected)
                end
            end,
        })

        setting.control = control
        self.rows[index] = { control = control }
        ScrollInput.Bind(control.root, onScrollWheel)

        -- World interfaces may have no representative inventory item.
        if setting.definition.item ~= nil then
            self.rows[index].item = self:CreateItemSlot(row.root, setting, list)
            ScrollInput.Bind(self.rows[index].item.root, onScrollWheel)
        end

        if setting.details ~= nil then
            self.rows[index].button = prettyui.SimpleButton.new(row.root, id.Sprite.RS3_ICON_SETTINGS_17PX_0, function()
                if self.list == list then
                    openDetails(setting.definition.key)
                end
            end, {
                x = -32, y = 11, xAnchor = 1, width = 26, height = 26, iconSize = 17,
            })
            ScrollInput.Bind(self.rows[index].button.root, onScrollWheel)
        end
    end

    self:Refresh()

    return page.root.height
end

function InterfaceToggles:Refresh()
    if self.view == nil then
        return
    end

    local height = math.max(1, self.page.root.height - self.y - 12)

    self.view.root:SetHeight(height)
    self.view:SetContentHeight(height)
    self.list:SetSize(self.view.content.width, math.max(1, height - self.contentY))
    self.page:SetContentHeight(self.page.root.height)
end

function InterfaceToggles:Unmount()
    local view, list, rows = self.view, self.list, self.rows

    self.view, self.list, self.rows, self.page = nil, nil, nil, nil
    cleanup.Release(self, "itemTooltip")

    for _, row in ipairs(rows or {}) do
        cleanup.Release(row, "item")
        pcall(function()
            row.control:Destroy()
        end)

        if row.button ~= nil then
            pcall(function()
                row.button:Destroy()
            end)
        end
    end

    if list ~= nil then
        pcall(function()
            list:Destroy()
        end)
    end

    if view ~= nil then
        pcall(function()
            view:Destroy()
        end)
    end

    for _, setting in ipairs(self.settings) do
        setting:Unmount()
    end
end

return InterfaceToggles
