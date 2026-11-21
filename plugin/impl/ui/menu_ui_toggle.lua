local settings = require("impl/settings")
local cleanup = require("impl/cleanup")
local MenuUIToggle = {}
MenuUIToggle.__index = MenuUIToggle

local buttonSize = 24
local gap = 8

function MenuUIToggle.HeaderInset()
    return settings.Get("showOriginalUIToggle") and buttonSize + gap * 5 or gap
end

function MenuUIToggle:New(menu, snapshot)
    return setmetatable({
        menu = menu,
        window = snapshot.window,
        content = snapshot.content,
        scope = menu.pageGroup or menu,
        original = menu.UseOriginalUIByDefault ~= nil and menu:UseOriginalUIByDefault() or false,
    }, self)
end

function MenuUIToggle:Matches(menu, snapshot)
    return self.window == snapshot.window
        and self.content == snapshot.content
        and self.scope == (menu.pageGroup or menu)
end

function MenuUIToggle:Attach()
    self.root = prettyui.NewComponent(ui.Layer, self.window, { categoryID = "auto" })
    self.root:SetSize(0, 0, 1.0, 1.0)
    self.root.clickthrough = true

    self.button = prettyui.SpriteButton.new(self.root, "EYE", function(_, enabled)
        -- Let the controller restore the menu on its next update.
        self.original = not enabled
    end, {
        size = buttonSize,
        toggleable = true,
        disabled = self.original,
    })
end

function MenuUIToggle:Update(snapshot)
    -- Attach after the chosen presentation captures its native controls.
    if self.root == nil then
        self:Attach()
    end

    self.root.hidden = not settings.Get("showOriginalUIToggle")

    local window = self.menu.GetUIToggleWindow and self.menu:GetUIToggleWindow() or self.window
    local position, parentPosition = window.xyGlobal, self.window.xyGlobal
    local x, y = position.x - parentPosition.x + gap, position.y - parentPosition.y + gap
    local close = snapshot.closeButton

    if close ~= nil and close.visibleGlobal then
        local closePosition = close.xyGlobal
        y = closePosition.y - parentPosition.y + math.floor((close.height - buttonSize) / 2)
    end

    self.button.root:SetPos(x, math.max(0, y))
    self.root:MoveToFront()
end

function MenuUIToggle:Destroy()
    cleanup.Release(self, "button")
    cleanup.Release(self, "root")
end

return MenuUIToggle
