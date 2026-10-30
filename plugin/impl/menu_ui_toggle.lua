local settings = require("impl/settings")
local MenuUIToggle = {}
MenuUIToggle.__index = MenuUIToggle

local buttonSize = 24
local gap = 8
local hookID = "teleportMapsUIToggle"

function MenuUIToggle:New(menu, snapshot)
    return setmetatable({
        window = snapshot.window,
        content = snapshot.content,
        scope = menu.pageGroup or menu,
        original = false,
    }, self)
end

function MenuUIToggle:Matches(menu, snapshot)
    return self.window == snapshot.window
        and self.content == snapshot.content
        and self.scope == (menu.pageGroup or menu)
end

function MenuUIToggle:Attach()
    self.root = ui.Layer.new(self.window)
    self.root:SetSize(0, 0, 1.0, 1.0)
    self.root.clickthrough = true

    self.button = ui.Sprite.new(self.root)
    self.button:SetSize(buttonSize, buttonSize)
    self.button.spriteID = id.Sprite.RS3_ICON_WARDROBE_EFFECTS_24PX_2
    self.button.clickthrough = false

    self.button:Subscribe(ui.Hook.ONMOUSEOVER, hookID, function()
        self.button.spriteID = id.Sprite.RS3_ICON_WARDROBE_EFFECTS_24PX_3
        return true
    end)

    self.button:Subscribe(ui.Hook.ONMOUSELEAVE, hookID, function()
        self.button.spriteID = self.original and id.Sprite.RS3_ICON_WARDROBE_EFFECTS_24PX_4 or id.Sprite.RS3_ICON_WARDROBE_EFFECTS_24PX_2
        return true
    end)

    self.button:Subscribe(ui.Hook.ONCLICK, hookID, function()
        -- Let the controller restore the menu on its next update.
        self.original = not self.original
        return false
    end)
end

function MenuUIToggle:Update(snapshot)
    self.root.hidden = not settings.Get("showOriginalUIToggle")

    local y = gap
    local close = snapshot.closeButton

    if close ~= nil and close.visibleGlobal then
        local position = close.xyGlobal
        local windowPosition = self.window.xyGlobal

        y = position.y - windowPosition.y + math.floor((close.height - buttonSize) / 2)
    end

    self.button:SetPos(gap, math.max(0, y))
    self.root:MoveToFront()
end

function MenuUIToggle:Destroy()
    if self.root ~= nil then
        pcall(function()
            self.root:Destroy()
        end)
        self.root = nil
    end

    self.button = nil
end

return MenuUIToggle
