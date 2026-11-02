local Page = {}
Page.__index = Page

-- Each page keeps its controls alive while navigation only changes visibility.
function Page.New(parent, groups, navigationParent, previous)
    local root = ui.Layer.new(parent)
    root:SetSize(0, 0, 1, 1)
    root.clickthrough = true
    root.hidden = previous ~= nil

    local self = setmetatable({
        root = root, groups = groups, previous = previous, details = {},
        navigationParent = navigationParent,
    }, Page)
    self.view = prettyui.SimpleView.new(root, {
        width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        layout = { padding = 0, startY = 0 },
    })

    if previous ~= nil then
        self.back = prettyui.SpriteButton.new(navigationParent, "BACK", function() self:Back() end, {
            x = -34, y = 8, xAnchor = 1, width = 26, height = 26,
        })
        self.back.root.hidden = true
    end

    return self
end

function Page:Mount()
    local y = 8
    for _, group in ipairs(self.groups) do
        y = group:Mount(self.view, y, function(setting)
            if not self.closed then self.details[setting]:Show() end
        end)
        for _, setting in ipairs(group.settings) do
            if setting.details ~= nil then
                local page = Page.New(self.root.parent, setting.details, self.navigationParent, self)
                self.details[setting] = page
                page:Mount()
            end
        end
    end
    self.view:SetContentHeight(y)
    self:Refresh()
end

function Page:Show()
    if self.closed then return end
    if self.previous ~= nil then self.previous:Hide() end
    self.root.hidden = false
    self:Refresh()
end

function Page:Back()
    if self.closed or self.previous == nil then return end
    self:Hide()
    self.previous:Show()
end

function Page:Hide()
    self.root.hidden = true
    if self.back ~= nil then self.back.root.hidden = true end
end

function Page:Refresh()
    if self.closed then return end
    -- Navigation lives over the tab bar, so mirror the active page's visibility.
    if self.back ~= nil then
        self.back.root.hidden = not self.root.visibleGlobal
        if not self.back.root.hidden then self.back.root:MoveToFront() end
    end
    self.view:Refresh()
    for _, group in ipairs(self.groups) do group:Refresh() end
    for _, page in pairs(self.details) do page:Refresh() end
end

function Page:Destroy()
    if self.closed then return end
    self.closed = true
    for _, page in pairs(self.details) do pcall(function() page:Destroy() end) end
    for _, group in ipairs(self.groups) do group:Unmount() end
    if self.back ~= nil then pcall(function() self.back:Destroy() end) end
    pcall(function() self.view:Destroy() end)
    pcall(function() self.root:Destroy() end)
    self.details = {}
end

return Page
