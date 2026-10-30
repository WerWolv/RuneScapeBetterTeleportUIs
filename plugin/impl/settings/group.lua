local text = require("impl/text")
local Group = {}
Group.__index = Group

function Group:New(definition, settings)
    return setmetatable({ definition = definition, settings = settings }, self)
end

-- Separate content hosts keep anchored controls inside the group's indented width.
function Group:Mount(page, y)
    self.view = prettyui.SimpleView.new(page.content, {
        x = 14, y = y, width = -28, widthAnchor = 1, height = 1,
        scrollable = false, _onScrollWheel = page._onScrollWheel,
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

    local contentY = heading.y + heading.height + 4
    self.content = prettyui.SimpleView.new(self.view.content, {
        x = 20, y = contentY, width = -20, widthAnchor = 1, height = 1,
        scrollable = false, _onScrollWheel = page._onScrollWheel,
        layout = { padding = 0, startY = 0, rowGap = 4 },
    })
    for _, setting in ipairs(self.settings) do
        setting:Mount(self.content)
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
    if self.view ~= nil then self.view:Refresh() end
    if self.content ~= nil then self.content:Refresh() end
end

function Group:Unmount()
    -- Destroy widgets while their setting instances still retain their control state.
    if self.content ~= nil then pcall(function() self.content:Destroy() end) end
    if self.view ~= nil then pcall(function() self.view:Destroy() end) end
    for _, setting in ipairs(self.settings) do
        setting:Unmount()
    end
    self.content, self.view = nil, nil
end

return Group
