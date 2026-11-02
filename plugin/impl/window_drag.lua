local WindowDrag = {}
WindowDrag.__index = WindowDrag

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, math.max(minimum, maximum)))
end

-- A passive native fullmodal host has no drag handler. Capture on a sibling layer
-- so the input surface stays stationary while its window moves underneath it.
function WindowDrag.New(frame)
    local root = ui.Layer.new(frame.parent)
    root.hidden = true
    root.clickthrough = false
    root.cursorConfig.mouseOverCursor = id.Cursor.TOPLEVEL_V2_MOVE
    local self = setmetatable({ root = root, frame = frame }, WindowDrag)

    root:Subscribe(ui.Hook.ONCLICK, function(component, x, y)
        local mouse = Mouse.GetPosition()
        if self.closed or mouse == nil then return false end
        local origin = component.xyGlobal
        local expectedX, expectedY = origin.x + x, origin.y + y
        -- Hook coordinates use interface units; raw mouse positions can include
        -- both interface and OS scaling. Calibrate at the stationary click target.
        local scale
        if math.abs(expectedX) >= math.max(32, math.abs(expectedY)) then
            scale = mouse.x / expectedX
        elseif math.abs(expectedY) >= 32 then
            scale = mouse.y / expectedY
        end
        if scale == nil or scale <= 0 then scale = 1 end
        local windowPosition, parentPosition = self.window.xyGlobal, frame.parent.xyGlobal
        self.start = {
            x = mouse.x, y = mouse.y, left = frame.x, top = frame.y, scale = scale,
            -- The host can be wider than the displayed map. Bound its visible window,
            -- so spare host space doesn't prevent dragging a fullscreen-hosted dialog.
            minX = frame.x + parentPosition.x - windowPosition.x,
            minY = frame.y + parentPosition.y - windowPosition.y,
        }
        root:SetPos(0, 0)
        root:SetSize(0, 0, 1, 1)
        root:MoveToFront()
        return false
    end)

    root:Subscribe(ui.Hook.ONHOLD, function()
        local start, mouse = self.start, Mouse.GetPosition()
        if self.closed or start == nil or mouse == nil then return false end
        frame:SetPos(
            math.floor(clamp(start.left + (mouse.x - start.x) / start.scale,
                start.minX, start.minX + frame.parent.width - self.window.width)),
            math.floor(clamp(start.top + (mouse.y - start.y) / start.scale,
                start.minY, start.minY + frame.parent.height - self.window.height))
        )
        return false
    end)

    local function stop()
        self.start = nil
        if not self.closed and self.window ~= nil then
            self:Layout(self.window, self.header, self.height)
        end
        return false
    end
    root:Subscribe(ui.Hook.ONRELEASE, stop)
    root:Subscribe(ui.Hook.ONDRAGCOMPLETE, stop)
    return self
end

function WindowDrag:Layout(window, header, height)
    self.window, self.header, self.height = window, header, height
    local root = self.root
    root.hidden = not window.visibleGlobal
    if self.start == nil then
        local origin, parent = window.xyGlobal, root.parent.xyGlobal
        root:SetPos(origin.x - parent.x + header.left, origin.y - parent.y)
        root:SetSize(math.max(1, window.width - header.left - header.right), height)
    end
    root:MoveToFront()
end

function WindowDrag:Destroy()
    if self.closed then return end
    self.closed, self.start = true, nil
    self.root:Destroy()
end

return WindowDrag
