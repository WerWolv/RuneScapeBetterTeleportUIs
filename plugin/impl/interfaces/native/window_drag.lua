local cleanup = require("impl/cleanup")
local MenuUIToggle = require("impl/ui/menu_ui_toggle")
local WindowDragOutline = require("impl/ui/window_drag_outline")

local WindowDrag = {}
WindowDrag.__index = WindowDrag
local hookID = "teleportMapsWindowDrag"
local dragHooks = {
    ui.Hook.ONCLICK,
    ui.Hook.ONCLICKREPEAT,
    ui.Hook.ONHOLD,
    ui.Hook.ONRELEASE,
    ui.Hook.ONDRAG,
    ui.Hook.ONDRAGCOMPLETE,
}

-- Own title-bar input and placement without running native window-drag scripts.
-- Adapters opt in when their host's saved placement belongs to another interface.
function WindowDrag.New(session)
    local self = setmetatable({ session = session, guarded = {} }, WindowDrag)
    session.windowDrag = self

    self:Guard(session.window)

    for _, frame in ipairs(session.frame) do
        self:Guard(frame.control)
    end

    if session.title ~= nil then
        self:Guard(session.title.control)
    end

    self.surface = ui.Layer.new(session.tooltipLayer.parent)
    self.surface.clickthrough = false
    self.surface.hidden = true

    self.surface:Subscribe(ui.Hook.ONCLICK, function(component, x, y)
        if var.VarPlayer.TOPLEVEL_V2_CUSTOMIZATION_LOCK.value ~= 0 then
            return false
        end

        local origin = component.xyGlobal
        local mouseX, mouseY = origin.x + x, origin.y + y
        local raw = Mouse.GetPosition()
        local scale = math.max(1, tonumber(game.options.InterfaceScale.setting) or 100) / 100

        -- Calibrate raw screen pixels against native interface coordinates,
        -- including OS scaling. Subsequent hooks can retain the press origin.
        if raw ~= nil then
            if math.abs(mouseX) >= math.max(32, math.abs(mouseY)) then
                scale = raw.x / mouseX
            elseif math.abs(mouseY) >= 32 then
                scale = raw.y / mouseY
            end
        end

        local position = session.hostContainers[1].xyGlobal
        self.drag = {
            x = position.x,
            y = position.y,
            originX = origin.x,
            originY = origin.y,
            mouseX = mouseX,
            mouseY = mouseY,
            raw = raw,
            scale = scale > 0 and scale or 1,
        }

        -- Keep receiving held/release input even when the pointer leaves the header.
        component:SetPos(0, 0)
        component:SetSize(0, 0, 1.0, 1.0)
        component:MoveToFront()
        self.bounds = nil

        cleanup.Release(self, "outline")
        self.outline = WindowDragOutline.New(component.parent)
        self.outline:Update(session.window)
        return false
    end)

    self.surface:Subscribe(ui.Hook.ONHOLD, function(_, x, y)
        self:Move(x, y)
        return false
    end)

    local function finish(_, x, y)
        self:Move(x, y)
        self.drag = nil
        self:Update()
        return false
    end

    self.surface:Subscribe(ui.Hook.ONRELEASE, finish)
    self.surface:Subscribe(ui.Hook.ONDRAGCOMPLETE, finish)

    return self
end

function WindowDrag:Guard(control)
    for _, guarded in ipairs(self.guarded) do
        if guarded == control then
            return
        end
    end

    self.guarded[#self.guarded + 1] = control

    for _, hook in ipairs(dragHooks) do
        control:Subscribe(hook, hookID, function()
            return false
        end)
    end
end

function WindowDrag:Move(x, y)
    local drag = self.drag

    if drag == nil then
        return
    end

    local raw = Mouse.GetPosition()
    local dx, dy

    if raw ~= nil and drag.raw ~= nil then
        dx, dy = (raw.x - drag.raw.x) / drag.scale, (raw.y - drag.raw.y) / drag.scale
    elseif type(x) == "number" and type(y) == "number" then
        dx, dy = drag.originX + x - drag.mouseX, drag.originY + y - drag.mouseY
    else
        return
    end

    -- Native writes happen in the tracked layout pass, never inside input hooks.
    self.session.windowPosition = { x = math.floor(drag.x + dx), y = math.floor(drag.y + dy) }
end

function WindowDrag:Update()
    local locked = var.VarPlayer.TOPLEVEL_V2_CUSTOMIZATION_LOCK.value ~= 0

    if self.locked ~= locked then
        local cursor = config.Cursor.TOPLEVEL_V2_MOVE
        local cursorID = type(cursor) == "number" and cursor or cursor.id
        self.surface.opConfig:ClearOpCursors()
        self.surface.cursorConfig.mouseOverCursor = locked and -1 or cursorID

        if not locked then
            self.surface.opConfig:SetOpCursor(0, cursorID)
        end

        self.locked = locked
    end

    if self.drag ~= nil then
        if not locked then
            self.outline:Update(self.session.window)
            return
        end

        self.drag = nil
    end

    cleanup.Release(self, "outline")

    local session = self.session
    local window, surface = session.window, self.surface
    local origin, parent = window.xyGlobal, surface.parent.xyGlobal
    local left = MenuUIToggle.HeaderInset()
    local right = window.width

    if session.close ~= nil and session.close.control.visibleGlobal then
        right = right - session.close.right - session.close.width
    end

    local x, y = origin.x + left - parent.x, origin.y - parent.y
    local width, height = math.max(0, right - left), session.top
    local bounds = self.bounds

    if bounds == nil or bounds.x ~= x or bounds.y ~= y or bounds.width ~= width or bounds.height ~= height then
        surface:SetPos(x, y)
        surface:SetSize(width, height)
        surface.hidden = width == 0
        surface:MoveToFront()
        self.bounds = { x = x, y = y, width = width, height = height }
    end
end

function WindowDrag:Destroy()
    self.drag = nil
    cleanup.Release(self, "outline")
    cleanup.Release(self, "surface")

    for _, control in ipairs(self.guarded) do
        for _, hook in ipairs(dragHooks) do
            cleanup.Try("remove window drag hook", function()
                control:Unsubscribe(hook, hookID)
            end)
        end
    end

    self.guarded = {}
end

return WindowDrag
