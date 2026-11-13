local cleanup = require("impl/cleanup")

local WindowDragOutline = {}
WindowDragOutline.__index = WindowDragOutline

local function createFrame(parent, prefix, thickness)
    local layer = prettyui.NewComponent(ui.Layer, parent, { categoryID = "auto" })
    layer.clickthrough = true
    local frame = { layer = layer, thickness = thickness, parts = {} }

    -- Native feedback artwork has left corners/edges; mirror those on the right.
    for _, part in ipairs({
        { "topLeft", 0 },
        { "top", 1, true },
        { "topRight", 0, false, true },
        { "left", 2, true },
        { "right", 2, true, true },
        { "bottomLeft", 4 },
        { "bottom", 5, true },
        { "bottomRight", 4, false, true },
    }) do
        local sprite = prettyui.NewComponent(ui.Sprite, layer)
        sprite.spriteID = id.Sprite[prefix .. part[2]]
        sprite.clickthrough = true
        sprite.isTiling = part[3] == true
        sprite.isFlippedHorizontally = part[4] == true
        frame.parts[part[1]] = sprite
    end

    return frame
end

local function layoutFrame(frame, x, y, width, height)
    if frame.x ~= x or frame.y ~= y then
        frame.layer:SetPos(x, y)
        frame.x, frame.y = x, y
    end

    if frame.width == width and frame.height == height then
        return
    end

    frame.layer:SetSize(width, height)
    local border = math.min(frame.thickness, math.floor(width / 2), math.floor(height / 2))

    local function place(name, left, top, w, h)
        frame.parts[name]:SetPos(left, top)
        frame.parts[name]:SetSize(w, h)
    end

    place("topLeft", 0, 0, border, border)
    place("topRight", width - border, 0, border, border)
    place("bottomLeft", 0, height - border, border, border)
    place("bottomRight", width - border, height - border, border, border)
    place("top", border, 0, width - border * 2, border)
    place("bottom", border, height - border, width - border * 2, border)
    place("left", 0, border, border, height - border * 2)
    place("right", width - border, border, border, height - border * 2)
    frame.width, frame.height = width, height
end

function WindowDragOutline.New(parent)
    local layer = prettyui.NewComponent(ui.Layer, parent, { categoryID = "auto" })
    layer:SetSize(0, 0, 1.0, 1.0)
    layer.clickthrough = true
    layer:MoveToFront()
    return setmetatable({ layer = layer }, WindowDragOutline)
end

-- The origin stays fixed; the active outline follows the final fitted window.
function WindowDragOutline:Update(window)
    local position, parent = window.xyGlobal, self.layer.xyGlobal
    local x, y = position.x - parent.x, position.y - parent.y

    if self.origin == nil then
        self.origin = createFrame(self.layer, "RS3_FEEDBACK_POSITION_FRAME_", 10)
        layoutFrame(self.origin, x, y, window.width, window.height)
    end

    if self.active == nil then
        self.active = createFrame(self.layer, "RS3_FEEDBACK_FINAL_FRAME_", 8)
    end

    layoutFrame(self.active, x, y, window.width, window.height)
end

function WindowDragOutline:Destroy()
    cleanup.Release(self, "layer")
    self.origin, self.active = nil, nil
end

return WindowDragOutline
