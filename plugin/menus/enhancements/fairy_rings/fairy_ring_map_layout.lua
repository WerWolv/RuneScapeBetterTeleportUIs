local FairyRingMenu = require("impl/interfaces/fairy_ring_menu")
local NativeLayout = require("impl/native_layout")
local components = require("impl/ui/components")
local cleanup = require("impl/cleanup")
local text = require("impl/text")

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
    control:SetPos(math.floor(x - origin.x), math.floor(y - origin.y))
    control:SetSize(math.max(0, math.floor(width)), math.max(0, math.floor(height)))
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
        ancestor.clickthrough = true

        if components.IsCollection(ancestor) and ancestor.scrollable then
            ancestor:SetScrollSize(window.width, window.height)
            ancestor:SetScrollPos(0, 0)
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

-- Restore rows before discovery so sorting and native log rebuilds stay live.
function FairyRingMapLayout:ReadRows()
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

    return rows
end

function FairyRingMapLayout:Layout(layout)
    local session = self.session
    local window = session.window
    local origin = window.xyGlobal

    setRect(session.content, origin.x, origin.y, window.width, window.height)
    expandAncestors(self.wheels, window)
    local wheelInset = (layout.sidebarWidth - self.wheelWidth) / 2
    setRect(self.wheels, origin.x + session.left + layout.width + wheelInset, origin.y,
        self.wheelWidth, self.wheelHeight)

    for _, name in ipairs(hiddenArtwork) do
        local control = component(name)

        if control ~= nil then
            control.hidden = true
        end
    end

    return math.max(0, self.wheelHeight - session.top) + 8
end

function FairyRingMapLayout:UpdatePointer(view, hovered)
    local session = self.session
    local window = session.window
    local origin = window.xyGlobal

    self.rowLayout:Apply(function()
        -- Only the hovered destination owns a live native hitbox. Zero-sized
        -- siblings and zero spacing also support native stacking panels.
        for _, name in ipairs(FairyRingMenu.logColumns) do
            local column = component(name)

            if column ~= nil then
                expandAncestors(column, window)

                if column.type == ui.ComponentType.PANEL then
                    column.spacing = 0
                end

                if hovered ~= nil and name == "TEXT_CLICK" then
                    setRect(column, view:TargetRectangle(hovered))
                else
                    setRect(column, origin.x, origin.y, 0, 0)
                end

                column.clickthrough = true
                column:IterateDynamicComponents(function(control)
                    control.alpha = 0
                    control.clickthrough = true
                    control:SetPos(0, 0)
                    control:SetSize(0, 0)
                    return false
                end)
            end
        end

        if hovered ~= nil and hovered.row.click ~= nil then
            local control, target = hovered.row.click, hovered.target
            control:SetPos(0, 0)
            control:SetSize(target.width, target.height)
            control.clickthrough = false
        end
    end)

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
