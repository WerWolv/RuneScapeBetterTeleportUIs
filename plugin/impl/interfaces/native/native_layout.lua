local components = require("impl/ui/components")
local cleanup = require("impl/cleanup")

local NativeLayout = {}
NativeLayout.__index = NativeLayout
local activeLayout

local positionFields = { "x", "y", "xParentPc", "yParentPc", "xSelfPc", "ySelfPc" }
local sizeFields     = { "width", "height", "widthParentPc", "heightParentPc" }

-- Copy raw layout values, including relative anchors, without retaining mutable UI value objects.
local function readState(control)
    local position, size = control.position, control.size
    local state = {
        rgb = control.rgb,
        alpha = control.alpha,
        clickthrough = control.clickthrough,
        hidden = control.hidden,
        enabled = control.enabled,
    }

    for _, field in ipairs(positionFields) do
        state[field] = position[field]
    end

    for _, field in ipairs(sizeFields) do
        state[field] = size[field]
    end

    if components.IsCollection(control) and control.scrollable then
        state.scrollX, state.scrollY = control.scrollX, control.scrollY
        state.scrollWidth, state.scrollHeight = control.scrollWidth, control.scrollHeight
    end

    if control.type == ui.ComponentType.PANEL then
        state.spacing = control.spacing
    end

    if control.type == ui.ComponentType.LABEL then
        state.content = control.content
        state.font = control.font
        state.maxLines = control.maxLines
    end

    if control.type == ui.ComponentType.GROUP_BOX then
        state.header = control.headerText.content
    end

    return state
end

-- Capture native control identities before plugin-owned visuals are added to the window.
function NativeLayout.FromControls(controls)
    local self = setmetatable({
        controls = {},
        changes = {},
        byKey = {},
        tracked = setmetatable({}, { __mode = "k" }),
    }, NativeLayout)

    for _, control in ipairs(controls) do
        local key = components.Key(control)

        if self.byKey[key] == nil then
            local entry = {
                control = control,
                parent = control.parent,
            }
            self.controls[#self.controls + 1] = entry
            self.byKey[key] = entry
            self.tracked[control] = entry
        end
    end

    return self
end

local function trackedEntry(layout, control)
    local entry = layout.tracked[control]

    if entry == nil then
        -- GetComponent/iteration can return distinct Lua wrappers for the same
        -- native component. Their table keys differ even when __eq says equal.
        entry = layout.byKey[components.Key(control)]

        if entry ~= nil and entry.control == control then
            layout.tracked[control] = entry
        else
            entry = nil
        end
    end

    return entry
end

local function record(context, control, field, previous, current)
    if previous == current then
        return
    end

    local entry

    while context ~= nil do
        entry = trackedEntry(context.layout, control)

        if entry ~= nil then
            break
        end

        context = context.parent
    end

    if context == nil then
        return
    end

    local layout = context.layout
    control = entry.control
    local change = layout.changes[control]

    if change == nil then
        change = {
            original = {},
            applied = {},
        }
        layout.changes[control] = change
    end

    if change.applied[field] == nil or change.applied[field] ~= previous then
        change.original[field] = previous
    end

    change.applied[field] = current
end

-- Write-through tracking avoids two complete UI snapshots on every Draw. Only
-- properties actually written belong to this layout; native updates remain live.
function NativeLayout:Track(callback)
    local previous = activeLayout
    activeLayout = {
        layout = self,
        parent = previous,
    }

    local ok, message = pcall(callback)
    activeLayout = previous

    if not ok then
        error(message, 0)
    end
end

function NativeLayout.Set(control, field, value)
    local previous = field == "header" and control.headerText.content or control[field]

    if previous == value then
        return
    end

    local ok, message = pcall(function()
        if field == "header" then
            control.headerText.content = value
        else
            control[field] = value
        end
    end)
    local current = field == "header" and control.headerText.content or control[field]
    record(activeLayout, control, field, previous, current)

    if not ok then
        error(message, 0)
    end
end

local function setValues(control, property, fields, values, method)
    local source = property and control[property] or control
    local before = {}

    for index, field in ipairs(fields) do
        before[index] = source[field]
    end

    local ok, message = pcall(method, control, table.unpack(values))
    local current = property and control[property] or control

    for index, field in ipairs(fields) do
        record(activeLayout, control, field, before[index], current[field])
    end

    if not ok then
        error(message, 0)
    end
end

function NativeLayout.SetPos(control, x, y, xParentPc, yParentPc, xSelfPc, ySelfPc)
    xParentPc, yParentPc, xSelfPc, ySelfPc = xParentPc or 0, yParentPc or 0, xSelfPc or 0, ySelfPc or 0
    local position = control.position

    if position.x == x and position.y == y
        and position.xParentPc == xParentPc and position.yParentPc == yParentPc
        and position.xSelfPc == xSelfPc and position.ySelfPc == ySelfPc then
        return
    end

    setValues(control, "position", positionFields, { x, y, xParentPc, yParentPc, xSelfPc, ySelfPc }, control.SetPos)
end

-- Once native dragging takes over, its complete position (including anchors)
-- belongs to the client. Do not restore fragments of a previously loaded position.
function NativeLayout:PreservePosition(control)
    local entry = trackedEntry(self, control)
    local change = entry and self.changes[entry.control]

    if change ~= nil then
        for _, field in ipairs(positionFields) do
            change.original[field], change.applied[field] = nil, nil
        end
    end
end

function NativeLayout.SetSize(control, width, height, widthParentPc, heightParentPc)
    widthParentPc, heightParentPc = widthParentPc or 0, heightParentPc or 0
    local size = control.size

    if size.width == width and size.height == height
        and size.widthParentPc == widthParentPc and size.heightParentPc == heightParentPc then
        return
    end

    setValues(control, "size", sizeFields, { width, height, widthParentPc, heightParentPc }, control.SetSize)
end

local scrollPositionFields, scrollSizeFields = { "scrollX", "scrollY" }, { "scrollWidth", "scrollHeight" }

function NativeLayout.SetScrollPos(control, x, y)
    if control.scrollX == x and control.scrollY == y then
        return
    end

    setValues(control, nil, scrollPositionFields, { x, y }, control.SetScrollPos)
end

function NativeLayout.SetScrollSize(control, width, height)
    if control.scrollWidth == width and control.scrollHeight == height then
        return
    end

    setValues(control, nil, scrollSizeFields, { width, height }, control.SetScrollSize)
end

-- Capture a complete subtree when the caller does not already have explicit controls.
function NativeLayout.New(root)
    local controls = {}

    components.Walk(root, function(control)
        controls[#controls + 1] = control
    end)

    return NativeLayout.FromControls(controls)
end

-- Track only fields changed by this layout pass, including partial changes if rendering fails.
function NativeLayout:Apply(callback)
    local before = {}

    for _, entry in ipairs(self.controls) do
        local ok, state = pcall(readState, entry.control)

        if ok then
            before[entry.control] = state
        end
    end

    local ok, message = pcall(callback)

    for _, entry in ipairs(self.controls) do
        local control  = entry.control
        local previous = before[control]
        local readable, current = pcall(readState, control)

        if previous ~= nil and readable then
            for field, value in pairs(current) do
                if previous[field] ~= value then
                    local change = self.changes[control]

                    if change == nil then
                        change = {
                            original = {},
                            applied = {},
                        }
                        self.changes[control] = change
                    end

                    -- A client update between passes becomes the new value to restore.
                    if change.applied[field] == nil or change.applied[field] ~= previous[field] then
                        change.original[field] = previous[field]
                    end

                    change.applied[field] = value
                end
            end
        end
    end

    if not ok then
        error(message, 0)
    end
end

-- Restore only values still equal to our last write, preserving the next menu's client updates.
local function restore(control, change)
    local state = readState(control)
    local restored = {}

    for field, value in pairs(change.applied) do
        if state[field] == value then
            state[field] = change.original[field]
            restored[field] = true
        end
    end

    local positionChanged, sizeChanged = false, false

    for _, field in ipairs(positionFields) do
        positionChanged = positionChanged or restored[field]
    end

    for _, field in ipairs(sizeFields) do
        sizeChanged = sizeChanged or restored[field]
    end

    if sizeChanged then
        control.size = ui.Size.new(state.width, state.height, state.widthParentPc, state.heightParentPc)
    end

    if positionChanged then
        control.position = ui.Pos.new(
            state.x, state.y,
            state.xParentPc, state.yParentPc,
            state.xSelfPc, state.ySelfPc
        )
    end

    if restored.scrollWidth or restored.scrollHeight then
        control:SetScrollSize(state.scrollWidth, state.scrollHeight)
    end

    if restored.scrollX or restored.scrollY then
        control:SetScrollPos(state.scrollX, state.scrollY)
    end

    if restored.spacing then
        control.spacing = state.spacing
    end

    if restored.rgb then
        control.rgb = state.rgb
    end

    if restored.alpha then
        control.alpha = state.alpha
    end

    if restored.clickthrough then
        control.clickthrough = state.clickthrough
    end

    if restored.hidden then
        control.hidden = state.hidden
    end

    if restored.enabled then
        control.enabled = state.enabled
    end

    if restored.content then
        control.content = state.content
    end

    if restored.font then
        control.font = state.font
    end

    if restored.maxLines then
        control.maxLines = state.maxLines
    end

    if restored.header then
        control.headerText.content = state.header
    end
end

-- Release overrides on surviving controls without touching replaced or reparented components.
function NativeLayout:Restore()
    for _, entry in ipairs(self.controls) do
        local change = self.changes[entry.control]

        if change ~= nil then
            cleanup.Try("restore native layout", function()
                if entry.control.parent == entry.parent then
                    restore(entry.control, change)
                end
            end)
        end
    end

    self.changes = {}
end

return NativeLayout
