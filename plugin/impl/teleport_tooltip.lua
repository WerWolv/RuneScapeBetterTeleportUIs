local text = require("impl/text")

local teleportTooltip = {}
local maxWidth = 240
local paddingX, paddingY = 8, 5
local separatorGap = 7
local cursorHookID = "teleportMapsTooltipCursor"
local trackedHookID = "teleportMapsScrollTooltip"
local trackedCount = 0
local activeTracked

local function positionInViewport(target, viewport)
    local x, y = 0, 0
    local current = target

    while current ~= nil and current ~= viewport do
        local parent = current.parent
        x = x + current.x - (parent and parent.scrollX or 0)
        y = y + current.y - (parent and parent.scrollY or 0)
        current = parent
    end

    if current == viewport then
        return x, y
    end
end

local function isHovered(state)
    local tooltip, viewport = state.tooltip, state.viewport
    local target = tooltip.target

    if target == nil or target.enabled == false or not target.visibleGlobal or not target.isMouseOver
        or not viewport.visibleGlobal or tooltip.cursorX == nil or tooltip.cursorY == nil then
        return false
    end

    if tooltip.cursorX < 0 or tooltip.cursorY < 0
        or tooltip.cursorX >= target.width or tooltip.cursorY >= target.height then
        return false
    end

    -- Native absolute positions do not reliably include ancestor scroll origins.
    -- Clip in viewport space using the same scroll offset as the rendered content.
    local x, y = positionInViewport(target, viewport)
    if x == nil then
        return false
    end

    x, y = x + tooltip.cursorX, y + tooltip.cursorY
    return x >= 0 and y >= 0 and x < viewport.width and y < viewport.height
end

local function refreshTracked()
    local state = activeTracked
    if state == nil then
        return
    end

    if not isHovered(state) then
        state.tooltip:Hide()
        return
    end

    local position, origin = state.tooltip.target.xyGlobal, state.viewport.xyGlobal
    local x, y = positionInViewport(state.tooltip.target, state.viewport)

    if position.x ~= state.x or position.y ~= state.y
        or x ~= state.localX or y ~= state.localY
        or origin.x ~= state.viewportX or origin.y ~= state.viewportY
        or state.viewport.width ~= state.width or state.viewport.height ~= state.height then
        state.tooltip:Hide()
    end
end

-- Cover wheel, arrow and scrollbar dragging through the same scroll-position method.
function teleportTooltip.BindScroll(view)
    local setScrollPosition = view.SetScrollPosition

    function view:SetScrollPosition(position)
        local previous = self.scrollY
        local result = setScrollPosition(self, position)

        if self.scrollY ~= previous and activeTracked ~= nil
            and activeTracked.viewport == self.viewport then
            activeTracked.tooltip:Hide()
        end

        return result
    end
end

-- Scrolling or clipping does not reliably emit mouse-leave events. Track the active
-- tooltip independently, and only redisplay it after fresh native cursor coordinates.
function teleportTooltip.Track(tooltip, viewport)
    local state = { tooltip = tooltip, viewport = viewport }
    local show, hide, destroy = tooltip.Show, tooltip.Hide, tooltip.Destroy

    function tooltip:Show()
        if not isHovered(state) then
            self:Hide()
            return
        end

        if activeTracked ~= nil and activeTracked ~= state then
            activeTracked.tooltip:Hide()
        end

        local position, origin = self.target.xyGlobal, viewport.xyGlobal
        state.x, state.y = position.x, position.y
        state.localX, state.localY = positionInViewport(self.target, viewport)
        state.viewportX, state.viewportY = origin.x, origin.y
        state.width, state.height = viewport.width, viewport.height
        activeTracked = state

        return show(self)
    end

    function tooltip:Hide()
        if activeTracked == state then
            activeTracked = nil
        end

        return hide(self)
    end

    tooltip.target:Subscribe(ui.Hook.ONMOUSEREPEAT, trackedHookID, function(_, x, y)
        tooltip.cursorX, tooltip.cursorY = x, y
        tooltip:Show()
        return true
    end)

    trackedCount = trackedCount + 1
    if trackedCount == 1 then
        Event.Logic.Subscribe(trackedHookID, refreshTracked)
    end

    local destroyed = false
    function tooltip:Destroy()
        if destroyed then
            return
        end

        destroyed = true
        self:Hide()

        if self.target ~= nil then
            pcall(function() self.target:Unsubscribe(ui.Hook.ONMOUSEREPEAT, trackedHookID) end)
        end

        trackedCount = trackedCount - 1
        if trackedCount == 0 then
            Event.Logic.Unsubscribe(trackedHookID)
        end

        return destroy(self)
    end

    return tooltip
end

-- PrettyUI otherwise falls back to target-adjacent placement before ONMOUSEOVER.
local function attachAtCursor(target, parent, options)
    local tooltip = prettyui.Tooltip.attach(target, parent, options, { followCursor = true })
    local show = tooltip.Show

    function tooltip:Show()
        if self.cursorX == nil or self.cursorY == nil then
            return
        end

        return show(self)
    end

    -- PrettyUI ignores repeat events while hidden, but menu hover arbitration can
    -- hide a newly entered tooltip before it becomes the selected destination.
    -- Refresh coordinates regardless of visibility; the menu decides what to show.
    target:Subscribe(ui.Hook.ONMOUSEREPEAT, cursorHookID, function(_, x, y)
        tooltip.cursorX, tooltip.cursorY = x, y
        return true
    end)

    local destroy = tooltip.Destroy
    function tooltip:Destroy()
        if self.target ~= nil then
            pcall(function() self.target:Unsubscribe(ui.Hook.ONMOUSEREPEAT, cursorHookID) end)
        end

        return destroy(self)
    end

    return tooltip
end

local function lines(value)
    local normalized = value:gsub("<br%s*/?>", "\n"):gsub("\n$", "")
    return (normalized .. "\n"):gmatch("(.-)\n")
end

local function textWidth(font, value)
    local width = 0

    for line in lines(value) do
        local ok, measured = pcall(function()
            return font:GetStringWidth(line, false)
        end)

        width = math.max(width, ok and measured or #text.StripFormatting(line) * 7)
    end

    return width
end

local function textHeight(font, value, width)
    local ok, height = pcall(function()
        return font:GetStringHeightAndLineCount(value, width, font.baseline, false, false, false)
    end)

    if ok then
        return math.max(18, height)
    end

    local lineCount = 0

    for line in lines(value) do
        lineCount = lineCount + math.max(1, math.ceil(textWidth(font, line) / width))
    end

    return lineCount * (font.baseline or 18)
end

-- Attach a tooltip with title and optional description to the cursor
function teleportTooltip.Attach(target, parent, title, description)
    if text.IsBlank(description) then
        return attachAtCursor(target, parent, {
            text = title,
            maxWidth = maxWidth,
        })
    end

    local font = config.Font.MUSEO_SANS_15PT_REGULAR
    local width = math.max(
        40,
        math.max(textWidth(font, title), textWidth(font, description)) + paddingX * 4
    )

    -- Reserve separate regions so the title, divider, and wrapped description cannot overlap.
    local contentWidth = width - paddingX * 2
    local titleHeight = textHeight(font, title, contentWidth)
    local descriptionHeight = textHeight(font, description, contentWidth)
    local separatorY = paddingY + titleHeight + separatorGap
    local descriptionY = separatorY + 1 + separatorGap

    local tooltip = attachAtCursor(target, parent, {
        text = title,
        width = width,
        height = descriptionY + descriptionHeight + paddingY,
    })

    tooltip.label:SetPos(paddingX, paddingY)
    tooltip.label:SetSize(contentWidth, titleHeight)

    local separator = ui.Rectangle.new(tooltip.root)
    separator:SetPos(paddingX, separatorY)
    separator:SetSize(contentWidth, 1)
    separator.fill = true
    separator.rgba = 0xAFA27F80
    separator.clickthrough = true

    local body = ui.Text.new(tooltip.root)
    body:SetPos(paddingX, descriptionY)
    body:SetSize(contentWidth, descriptionHeight)
    body.font = id.Font.MUSEO_SANS_15PT_REGULAR
    body.content = description
    body.rgba = 0xD4CBB9FF
    body.maxLines = 0
    body.clickthrough = true

    return tooltip
end

-- Keep one tooltip for a collection of hover targets. The hidden
-- anchor owns PrettyUI's attachment hooks; individual slots forward hover events.
function teleportTooltip.Shared(parent, viewport)
    local anchor = ui.Layer.new(parent)
    anchor.hidden = true
    local shared = {
        anchor = anchor,
        tooltip = teleportTooltip.Track(teleportTooltip.Attach(anchor, parent, ""), viewport),
        title = "",
    }

    -- Context teardown can destroy the tooltip before its grid is destroyed.
    local destroy = shared.tooltip.Destroy
    function shared.tooltip:Destroy()
        if shared.destroyed then return end
        shared.destroyed = true
        self.target = anchor
        self.targetInterfaceID = anchor.interfaceID
        return destroy(self)
    end

    function shared:Show(target, title, x, y)
        if self.destroyed or target.enabled == false or not target.visibleGlobal then return end

        local tooltip = self.tooltip
        if tooltip.target ~= target then tooltip:Hide() end
        tooltip.target = target
        tooltip.targetInterfaceID = target.interfaceID
        tooltip.cursorX, tooltip.cursorY = x, y

        if self.title ~= title then
            tooltip:SetText(title)
            self.title = title
        end
        tooltip:Show()
    end

    function shared:Hide(target)
        if self.tooltip ~= nil and (target == nil or self.tooltip.target == target) then
            self.tooltip:Hide()
        end
    end

    function shared:Destroy()
        if self.tooltip ~= nil then
            self.tooltip:Destroy()
            self.anchor:Destroy()
            self.tooltip, self.anchor = nil, nil
        end
    end

    return shared
end

return teleportTooltip
