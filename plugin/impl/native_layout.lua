local NativeLayout = {}
NativeLayout.__index = NativeLayout

local collections = {
    [ui.ComponentType.LAYER]          = true,
    [ui.ComponentType.PANEL]          = true,
    [ui.ComponentType.GRID]           = true,
    [ui.ComponentType.PAGED_LAYER]    = true,
    [ui.ComponentType.PAGED_CAROUSEL] = true,
    [ui.ComponentType.GROUP_BOX]      = true,
}

local positionFields = { "x", "y", "xParentPc", "yParentPc", "xSelfPc", "ySelfPc" }
local sizeFields     = { "width", "height", "widthParentPc", "heightParentPc" }

-- Copy raw layout values, including relative anchors, without retaining mutable UI value objects.
local function readState(control)
    local position, size = control.position, control.size
    local state = {
        alpha = control.alpha,
        clickthrough = control.clickthrough,
    }

    for _, field in ipairs(positionFields) do
        state[field] = position[field]
    end

    for _, field in ipairs(sizeFields) do
        state[field] = size[field]
    end

    if control.type == ui.ComponentType.LABEL then
        state.content = control.content
    end

    if control.type == ui.ComponentType.GROUP_BOX then
        state.header = control.headerText.content
    end

    return state
end

-- Capture native control identities before plugin-owned visuals are added to the window.
function NativeLayout.New(root)
    local self = setmetatable({ controls = {}, changes = {} }, NativeLayout)
    local visited = {}

    local function visit(control)
        local key = table.concat({control.interfaceID, control.staticID, control.categoryID, control.dynamicID}, ":")
        if visited[key] then
            return false
        end

        visited[key] = true
        self.controls[#self.controls + 1] = {
            control = control,
            parent = control.parent,
        }

        if collections[control.type] then
            control:IterateStaticComponents(visit)
            control:IterateDynamicComponents(visit)
        end
        
        return false
    end

    visit(root)

    return self
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
                        change = { original = {}, applied = {} }
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

    if restored.alpha then
        control.alpha = state.alpha
    end

    if restored.clickthrough then
        control.clickthrough = state.clickthrough
    end

    if restored.content then
        control.content = state.content
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
            pcall(function()
                if entry.control.parent == entry.parent then
                    restore(entry.control, change)
                end
            end)
        end
    end

    self.changes = {}
end

return NativeLayout
