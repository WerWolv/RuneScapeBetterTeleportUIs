local ContentLayer = require("impl/ui/content_layer")
local cleanup = require("impl/cleanup")

local Page = {}
Page.__index = Page

-- Each page keeps its controls alive while navigation only changes visibility.
function Page.New(parent, groups, navigationParent, previous)
    local self = setmetatable({
        mountParent = parent,
        groups = groups,
        mountedGroups = {},
        previous = previous,
        details = {},
        navigationParent = navigationParent,
    }, Page)

    local ok, message = pcall(function()
        self.mount = ContentLayer.New(parent)
        local root = self.mount.root
        self.root = root
        root.hidden = previous ~= nil

        self.view = prettyui.SimpleView.new(root, {
            width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
            layout = { padding = 0, startY = 0 },
        })

        if previous ~= nil then
            self.back = prettyui.SpriteButton.new(navigationParent, "BACK", function()
                self:Back()
            end, {
                x = -34, y = 8, xAnchor = 1, width = 26, height = 26,
            })
            self.back.root.hidden = true
        end
    end)

    if not ok then
        self:Destroy()
        error(message, 0)
    end

    return self
end

function Page:Mount()
    local y = 8

    for _, group in ipairs(self.groups) do
        -- Register before Mount so partially constructed groups are also released.
        self.mountedGroups[#self.mountedGroups + 1] = group
        y = group:Mount(self.view, y, function(key)
            if not self.closed then
                self.details[key]:Show()
            end
        end)

        for _, setting in ipairs(group.settings) do
            if setting.details ~= nil then
                -- Reuse the managed handle so PrettyUI retains its allocation context.
                local page = Page.New(self.mountParent, setting.details, self.navigationParent, self)
                self.details[setting.definition.key] = page
                page:Mount()
            end
        end
    end

    self.view:SetContentHeight(y)
    self:Refresh()
end

function Page:Show()
    if self.closed then
        return
    end

    if self.previous ~= nil then
        self.previous:Hide()
    end

    self.root.hidden = false
    self:Refresh()
end

function Page:Back()
    if self.closed or self.previous == nil then
        return
    end

    self:Hide()
    self.previous:Show()
end

function Page:Hide()
    self.root.hidden = true

    if self.back ~= nil then
        self.back.root.hidden = true
    end
end

function Page:Refresh()
    if self.closed then
        return
    end

    -- Navigation lives over the tab bar, so mirror the active page's visibility.
    if self.back ~= nil then
        self.back.root.hidden = not self.root.visibleGlobal

        if not self.back.root.hidden then
            self.back.root:MoveToFront()
        end
    end

    self.view:Refresh()

    for _, group in ipairs(self.groups) do
        group:Refresh()
    end

    for _, page in pairs(self.details) do
        page:Refresh()
    end
end

function Page:Destroy()
    if self.closed then
        return
    end

    self.closed = true

    for _, page in pairs(self.details) do
        pcall(function()
            page:Destroy()
        end)
    end

    for _, group in ipairs(self.mountedGroups) do
        cleanup.Try("unmount settings group", function()
            group:Unmount()
        end)
    end

    cleanup.Release(self, "back")
    cleanup.Release(self, "view")
    cleanup.Release(self, "mount")

    self.root = nil
    self.mountParent = nil
    self.details = {}
    self.mountedGroups = {}
end

return Page
