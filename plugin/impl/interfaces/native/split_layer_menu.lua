local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local NativeLayout = require("impl/interfaces/native/native_layout")
local native = require("impl/interfaces/native/native_helpers")
local text = require("impl/text")

local SplitLayerMenu = ModalChoiceMenu:Extend()

local function component(menu, name)
    local componentID = name and id.Component[menu.nativeInterface.prefix .. name]

    return componentID and ui.Interfaces:GetComponent(componentID) or nil
end

local function isWithin(control, parent)
    if parent == nil then
        return false
    end

    while control ~= nil and control ~= parent do
        control = control.parent
    end

    return control ~= nil
end

-- A native button template has one input control and a fixed-size artwork block
-- in a sibling layer. IDs pair the template instances, never the destinations.
function SplitLayerMenu:ReadInterface()
    local definition = self.nativeInterface
    local window = component(self, definition.window)

    if window == nil or not window.visibleGlobal then
        return nil
    end

    local content = component(self, definition.content)
    local controls = component(self, definition.controls)
    local build = component(self, definition.build)

    if not isWithin(content, window) or not isWithin(controls, content)
        or build == nil or build.parent ~= controls.parent then
        self:ReportMatch({
            "Not matched: missing sibling input/artwork layers inside the window content.",
            "content=" .. tostring(content) .. ", controls=" .. tostring(controls) .. ", build=" .. tostring(build),
            "controls.parent=" .. tostring(controls and controls.parent)
                .. ", build.parent=" .. tostring(build and build.parent),
        })
        return nil
    end

    local labels = {}

    build:IterateDynamicComponents(function(label)
        if label.parent == build and not label.hidden and label.type == ui.ComponentType.LABEL then
            labels[label.categoryID] = labels[label.categoryID] or {}
            labels[label.categoryID][label.dynamicID] = label
        end

        return false
    end)

    local failures, rowsByID = {}, {}
    local rows, reason = native.ReadDynamicRows(controls, function(control)
        if control.type ~= ui.ComponentType.LABEL and control.type ~= ui.ComponentType.BUTTON then
            failures[#failures + 1] = "Unexpected input type " .. tostring(control.type) .. " at " .. control.dynamicID
            return nil
        end

        local category = labels[control.categoryID]
        local label = category and category[control.dynamicID * definition.artworkStride + definition.labelOffset]
        local name = label and text.Clean(label.content) or ""

        if name == "" then
            failures[#failures + 1] = "Input " .. control.categoryID .. ":" .. control.dynamicID
                .. " expects label " .. (control.dynamicID * definition.artworkStride + definition.labelOffset)
                .. (label == nil and " (missing)" or " (blank)")
            return nil
        end

        local row = {
            row = control,
            click = control,
            labels = { [name] = true },
            label = label,
            labelContent = label.content,
        }
        rowsByID[control.categoryID] = rowsByID[control.categoryID] or {}
        rowsByID[control.categoryID][control.dynamicID] = row
        return row
    end)

    if rows == nil then
        local lines = { "Not matched: " .. reason .. " input/artwork pairs in " .. definition.controls .. "." }

        for index = 1, math.min(5, #failures) do
            lines[#lines + 1] = failures[index]
        end

        self:ReportMatch(lines)
        return nil
    end

    local containers, parent = {}, controls

    while parent ~= content do
        table.insert(containers, 1, parent)
        parent = parent.parent
    end

    table.insert(containers, 1, content)

    local artwork = { build }

    for _, name in ipairs(definition.hide or {}) do
        local control = component(self, name)

        if control ~= nil then
            artwork[#artwork + 1] = control
        end
    end

    return {
        window = window,
        content = content,
        nativeRows = rows,
        rowsByID = rowsByID,
        closeButton = component(self, definition.close),
        controls = controls,
        build = build,
        containers = containers,
        artwork = artwork,
    }
end

-- A rejected selection can rebuild the dynamic rows while both static layers
-- survive. Validate just the input/label pairs, not the whole artwork subtree.
function SplitLayerMenu:HasCurrentRows(snapshot)
    local controls = component(self, self.nativeInterface.controls)
    local build = component(self, self.nativeInterface.build)
    if controls ~= snapshot.controls or build ~= snapshot.build
        or controls.parent ~= snapshot.containers[#snapshot.containers - 1]
        or build.parent ~= controls.parent then
        return false
    end

    local count, current = 0, true
    controls:IterateDynamicComponents(function(control)
        if control.parent == controls and not control.hidden then
            count = count + 1
            local category = snapshot.rowsByID[control.categoryID]
            local row = category and category[control.dynamicID]
            local label = build:GetChild(control.categoryID,
                control.dynamicID * self.nativeInterface.artworkStride + self.nativeInterface.labelOffset)

            if row == nil or control ~= row.click or label ~= row.label
                or label.hidden or label.content ~= row.labelContent then
                current = false
                return true
            end
        end
        return false
    end)
    return current and count == #snapshot.nativeRows
end

function SplitLayerMenu:GetSnapshot()
    local cached = rawget(self, "interfaceSnapshot")
    local snapshot = ModalChoiceMenu.GetSnapshot(self)

    if cached ~= nil and snapshot == cached.snapshot and not self:HasCurrentRows(snapshot) then
        self:InvalidateSnapshot()
        return ModalChoiceMenu.GetSnapshot(self)
    end

    return snapshot
end

function SplitLayerMenu:Matches(snapshot)
    if self.session ~= nil and self.session.menu.snapshot == snapshot then
        return true
    end

    if not ModalChoiceMenu.Matches(self, snapshot) then
        return false
    end

    local previous = self.session.menu.snapshot

    if snapshot.build ~= previous.build or snapshot.controls ~= previous.controls then
        return false
    end

    for index, row in ipairs(snapshot.nativeRows) do
        if row.label ~= previous.nativeRows[index].label then
            return false
        end
    end

    return true
end

function SplitLayerMenu:IsDisabled(row)
    return row.click.enabled == false or ModalChoiceMenu.IsDisabled(self, row)
end

function SplitLayerMenu:LayoutRowContainers()
    -- LayoutRows sizes the cached container chain without a second ancestor walk.
end

function SplitLayerMenu:LayoutRows(rectangles, width, height)
    local snapshot = self.session.menu.snapshot

    for _, control in ipairs(snapshot.artwork) do
        NativeLayout.Set(control, "hidden", true)
    end

    -- Remove the client's list scroll offset before positioning the original
    -- input controls. Artwork remains readable for discovery while hidden.
    for _, control in ipairs(snapshot.containers) do
        if control ~= self.session.content then
            NativeLayout.SetPos(control, 0, 0)
            NativeLayout.SetSize(control, width, height)
            NativeLayout.Set(control, "clickthrough", true)
        end

        if control.scrollable then
            NativeLayout.SetScrollSize(control, width, height)
            NativeLayout.SetScrollPos(control, 0, 0)
        end
    end

    -- Each paired row is its own action owner. Apply its final hitbox directly,
    -- so clipped cards never toggle clickthrough twice during an idle frame.
    for _, rectangle in ipairs(rectangles) do
        local control = rectangle.entry.click
        local origin = control.parent.xyGlobal

        NativeLayout.SetPos(control, math.floor(rectangle.x - origin.x), math.floor(rectangle.y - origin.y))
        NativeLayout.SetSize(control, rectangle.width, rectangle.height)
        self:HideRowArtwork(rectangle.entry)
        NativeLayout.Set(control, "clickthrough", rectangle.width <= 0 or rectangle.height <= 0
            or self.blockDisabledClicks == true and rectangle.entry.disabled)
    end
end

return SplitLayerMenu
