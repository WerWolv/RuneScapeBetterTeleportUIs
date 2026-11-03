local text = require("impl/text")
local ScrollInput = require("impl/ui/scroll_input")

local Group = {}
Group.__index = Group

function Group:New(definition, settings)
    return setmetatable({ definition = definition, settings = settings }, self)
end

-- Separate content hosts keep anchored controls inside the group's indented width.
function Group:Mount(page, y)
    self.page, self.y = page, y

    if self.definition.fillHeight then
        page:SetScrollable(false)
    end

    self.view = prettyui.SimpleView.new(page.content, {
        x = 14, y = y, width = -28, widthAnchor = 1, height = 1,
        scrollable = false,
        layout = { padding = 0, startY = 0 },
    })

    local onScrollWheel = ScrollInput.For(page)
    ScrollInput.For(self.view, 32, onScrollWheel)

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

    local contentY = heading.y + heading.height + 4
    self.contentY = contentY

    local indent = self.definition.fillHeight and 0 or 20

    self.content = prettyui.SimpleView.new(self.view.content, {
        x = indent, y = contentY, width = -indent, widthAnchor = 1, height = 1,
        scrollable = false,
        layout = { padding = 0, startY = 0, rowGap = 4 },
    })
    ScrollInput.For(self.content, 32, onScrollWheel)

    for _, setting in ipairs(self.settings) do
        setting:Mount(self.content)
    end

    ScrollInput.Bind(self.view.root, ScrollInput.For(self.view))

    if self.definition.fillHeight then
        self:Refresh()

        return page.root.height
    end

    local height = self.content.contentHeight

    self.content.root:SetHeight(height)
    self.content:Refresh()
    self.view:SetContentHeight(contentY + height)
    self.view.root:SetHeight(contentY + height)
    self.view:Refresh()

    return y + contentY + height + 12
end

function Group:Refresh()
    if self.definition.fillHeight and self.view ~= nil then
        local height = math.max(1, self.page.root.height - self.y - 12)
        local contentHeight = math.max(1, height - self.contentY)

        self.view.root:SetHeight(height)
        self.view:SetContentHeight(height)
        self.content.root:SetHeight(contentHeight)
        self.content:SetContentHeight(contentHeight)

        for _, setting in ipairs(self.settings) do
            setting:Layout(self.content.content.width, contentHeight)
        end

        self.page:SetContentHeight(self.page.root.height)

        return
    end

    if self.view ~= nil then
        self.view:Refresh()
    end

    if self.content ~= nil then
        self.content:Refresh()
    end
end

function Group:Unmount()
    local content, view = self.content, self.view
    self.content, self.view, self.page = nil, nil, nil

    -- Destroy widgets while their setting instances still retain their control state.
    if content ~= nil then
        pcall(function()
            content:Destroy()
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

return Group
