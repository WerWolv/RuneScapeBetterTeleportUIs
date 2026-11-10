local FairyRingMenu = require("impl/interfaces/native/fairy_ring_menu")
local NativeLayout = require("impl/interfaces/native/native_layout")
local components = require("impl/ui/components")
local cleanup = require("impl/cleanup")
local text = require("impl/text")
local settings = require("impl/settings")

local FairyRingMapLayout = {}
FairyRingMapLayout.__index = FairyRingMapLayout

local component = FairyRingMenu.Component
local overflow = 48
local hiddenArtwork = {
    "COMBINATIONS_BG", "INSTRUCTIONS_BG", "TUT_TEXT_1", "TUT_TEXT_2", "TUT_TEXT_3",
    "LOG_BG", "LOG_CONTAINER_TOP", "SCROLLBAR", "QUICK_TELE",
    "LINE_DARK_TOP", "LINE_LIGHT_TOP", "LINE_DARK_BOTTOM", "LINE_LIGHT_BOTTOM",
}

local function setRect(control, x, y, width, height)
    local origin = control.parent.xyGlobal
    NativeLayout.SetPos(control, math.floor(x - origin.x), math.floor(y - origin.y))
    NativeLayout.SetSize(control, math.max(0, math.floor(width)), math.max(0, math.floor(height)))
end

-- Grow clipping ancestors without reparenting controls or copying their hooks.
local function expandAncestors(control, window)
    local chain, parent = {}, control.parent

    while parent ~= nil and parent ~= window do
        chain[#chain + 1] = parent
        parent = parent.parent
    end

    local origin = window.xyGlobal

    for index = #chain, 1, -1 do
        local ancestor = chain[index]
        setRect(ancestor, origin.x, origin.y, window.width, window.height)
        NativeLayout.Set(ancestor, "clickthrough", true)

        if components.IsCollection(ancestor) and ancestor.scrollable then
            NativeLayout.SetScrollSize(ancestor, window.width, window.height)
            NativeLayout.SetScrollPos(ancestor, 0, 0)
        end
    end
end

local function raiseBranch(control, window)
    while control ~= nil and control ~= window do
        control:MoveToFront()
        control = control.parent
    end
end

function FairyRingMapLayout.New(session)
    local wheels = component("COMBINATIONS")
    local sidebarWidth = math.max(240, wheels.width + 40)

    local self = setmetatable({
        session = session,
        wheels = wheels,
        wheelWidth = wheels.width,
        wheelHeight = wheels.height,
        sidebarWidth = sidebarWidth,
        sidebarExpansion = sidebarWidth - math.max(240, wheels.width + 16),
    }, FairyRingMapLayout)

    -- The transparent top band keeps overflowing mushrooms inside the draggable host.
    session.top = session.top + overflow

    for _, frame in ipairs(session.frame) do
        frame.top = frame.top + overflow
    end

    if session.title ~= nil then
        session.title.top = session.title.top + overflow
    end

    if session.close ~= nil then
        session.close.top = session.close.top + overflow
    end

    return self
end

-- Watch identities and source data, not the plugin-owned hitbox geometry. Native
-- log rebuilds/sorting also restore background/favourite row heights or positions.
-- Comparing this small signature avoids restoring hundreds of controls per Draw.
local function rowState(previous)
    local state = previous or {}
    local unchanged = true

    for index, name in ipairs(FairyRingMenu.logColumns) do
        local column = component(name)
        local old = previous and previous[index]

        if previous and (old == nil or old.control ~= column) then
            return nil
        end

        local entry = old or {
            control = column,
            children = {},
        }
        local count = 0

        if column ~= nil then
            column:IterateDynamicComponents(function(control)
                count = count + 1

                if not unchanged then
                    return false
                end

                local child = old and old.children[count]

                if old and (child == nil or child.control ~= control) then
                    unchanged = false
                    return false
                end

                local kind = child and child.kind or control.type
                local content = kind == ui.ComponentType.LABEL and control.content or nil
                local sprite = kind == ui.ComponentType.SPRITE and control.spriteID or nil
                local positioned = name == "BG_BUILD" or name == "FAVOURITE_BUILD"
                local y = positioned and control.y or nil
                local height = positioned and control.height or nil
                local hidden, visible = control.hidden, control.visible

                if child ~= nil then
                    unchanged = child.content == content and child.sprite == sprite
                        and child.y == y and child.height == height
                        and child.hidden == hidden and child.visible == visible
                else
                    entry.children[count] = {
                        control = control,
                        kind = kind,
                        content = content,
                        sprite = sprite,
                        y = y,
                        height = height,
                        hidden = hidden,
                        visible = visible,
                    }
                end

                return false
            end)
        end

        if not unchanged or old and count ~= #old.children then
            return nil
        end

        state[index] = entry
    end

    return state
end

-- Restore before rediscovery when source rows change. Stable frames retain the
-- native hitboxes and cached destinations, including while the pointer moves.
function FairyRingMapLayout:ReadRows()
    local aliases = settings.Get("fairyRingAliases")

    if self.rows ~= nil and self.aliases == aliases and self.rowState ~= nil and rowState(self.rowState) ~= nil then
        return self.rows
    end

    self:RestoreRows()

    local rows = FairyRingMenu.ReadLogRows()
    self.rowLayout = NativeLayout.New(self.session.menu.snapshot.logContent)

    -- Shortcut labels follow the favourite sprites, rather than sharing their IDs.
    local favourites = component("FAVOURITE_BUILD")

    if favourites ~= nil then
        favourites:IterateDynamicComponents(function(number)
            if number.type == ui.ComponentType.LABEL and number.visible and not number.hidden then
                local centre = number.y + number.height / 2

                for _, row in ipairs(rows) do
                    if row.star ~= nil and centre >= row.star.y and centre < row.star.y + row.star.height then
                        row.shortcut = text.Clean(number.content)
                        break
                    end
                end
            end

            return false
        end)
    end

    self.rows, self.aliases = rows, aliases

    return rows
end

function FairyRingMapLayout:Layout(layout)
    local session = self.session
    local window = session.window
    local origin = window.xyGlobal

    setRect(session.content, origin.x, origin.y, window.width, window.height)
    expandAncestors(self.wheels, window)
    local wheelInset = (layout.sidebarWidth - self.wheelWidth) / 2
    setRect(
        self.wheels,
        origin.x + session.left + layout.width + wheelInset,
        origin.y,
        self.wheelWidth,
        self.wheelHeight
    )

    for _, name in ipairs(hiddenArtwork) do
        local control = component(name)

        if control ~= nil then
            NativeLayout.Set(control, "hidden", true)
        end
    end

    return math.max(0, self.wheelHeight - session.top) + 8
end

function FairyRingMapLayout:UpdatePointer(view, hovered)
    local session = self.session
    local window = session.window
    local origin = window.xyGlobal
    local x, y, width, height = origin.x, origin.y, 0, 0

    if hovered ~= nil then
        x, y, width, height = view:TargetRectangle(hovered)
    end

    local click = hovered and hovered.row.click
    local previous = self.pointer

    if previous ~= nil and previous.layout == self.rowLayout and previous.click == click
        and previous.x == x and previous.y == y and previous.width == width and previous.height == height
        and previous.windowX == origin.x and previous.windowY == origin.y
        and previous.windowWidth == window.width and previous.windowHeight == window.height
        and (click == nil or click.width == width and click.height == height and not click.clickthrough) then
        return
    end

    self.rowLayout:Track(function()
        -- Only the hovered destination owns a live native hitbox. Zero-sized
        -- siblings and zero spacing also support native stacking panels.
        for _, name in ipairs(FairyRingMenu.logColumns) do
            local column = component(name)

            if column ~= nil then
                expandAncestors(column, window)

                if column.type == ui.ComponentType.PANEL then
                    NativeLayout.Set(column, "spacing", 0)
                end

                if hovered ~= nil and name == "TEXT_CLICK" then
                    setRect(column, x, y, width, height)
                else
                    setRect(column, origin.x, origin.y, 0, 0)
                end

                NativeLayout.Set(column, "clickthrough", true)
                column:IterateDynamicComponents(function(control)
                    local active = hovered ~= nil and control == hovered.row.click
                    NativeLayout.Set(control, "alpha", 0)
                    NativeLayout.Set(control, "clickthrough", not active)
                    NativeLayout.SetPos(control, 0, 0)
                    NativeLayout.SetSize(
                        control,
                        active and hovered.target.width or 0,
                        active and hovered.target.height or 0
                    )

                    return false
                end)
            end
        end
    end)

    if self.rowState == nil then
        self.rowState = rowState()
    end

    self.pointer = {
        layout = self.rowLayout,
        click = click,
        x = x,
        y = y,
        width = width,
        height = height,
        windowX = origin.x,
        windowY = origin.y,
        windowWidth = window.width,
        windowHeight = window.height,
    }

    view.root:MoveToBack()
    raiseBranch(self.wheels, window)

    -- Raise the click branch above overlapping wheel/instruction wrappers,
    -- without reordering individual rows inside their native panel.
    if hovered ~= nil and hovered.row.click ~= nil then
        raiseBranch(hovered.row.click.parent, window)
    end

    if session.close ~= nil then
        session.close.control:MoveToFront()
    end
end

function FairyRingMapLayout:RestoreRows()
    cleanup.Release(self, "rowLayout", "Restore")
    self.rows, self.rowState, self.pointer = nil, nil, nil
end

function FairyRingMapLayout:Destroy()
    self:RestoreRows()

    local border = component("MAINMODAL_WINDOW_BORDER")

    if border ~= nil then
        border:MoveToFront()
    end

    -- The native close button can be a sibling of the border. Restoring the
    -- frame above the content must not leave that button covered by the frame.
    local close = component("MAINMODAL_WINDOW_CLOSE_BUTTON")

    if close ~= nil then
        raiseBranch(close, self.session.window)
    end
end

return FairyRingMapLayout
