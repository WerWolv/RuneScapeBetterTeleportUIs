local TeleportMenu = require("impl/teleport_menu")
local NativeLayout = require("impl/native_layout")
local text = require("impl/text")
local FairyRings = TeleportMenu:Extend("fairyRings")
FairyRings.interface = FairyRings
FairyRings.interfaceName = "FAIRYRINGS (" .. id.Interface.FAIRYRINGS .. ")"

local wheelControls = {
    "LEFT_CW", "LEFT_ACW",
    "MID_CW", "MID_ACW",
    "RIGHT_CW", "RIGHT_ACW",
}

local searchHeight, searchGap = 28, 6
local headerControls = {
    "LOG_TITLE", "SORT_DROPDOWN_HOLDER", "LOG_FOUND_LABEL", "LOG_FOUND_TOTAL",
}
local logColumns = {
    "FAVOURITE_BUILD", "FAVOURITE_CLICK", "BG_BUILD",
    "CODE_TEXT_BUILD", "LOCATION_TEXT_BUILD", "TEXT_CLICK",
}
local function component(name, category, index)
    if index ~= nil then
        return ui.Interfaces:GetComponent(id.Component["FAIRYRINGS__" .. name], category, index)
    end

    return ui.Interfaces:GetComponent(id.Component["FAIRYRINGS__" .. name])
end

local function plainText(value)
    return text.StripFormatting(value):lower():gsub("%s+", " ")
end

-- The named columns share a category and dynamic ID for each destination.
-- Discover from location labels so special destinations need not have a three-letter code.
local function logRows()
    local rows = {}
    local locations = component("LOCATION_TEXT_BUILD")

    if locations == nil then
        return rows
    end

    locations:IterateDynamicComponents(function(location)
        local text = plainText(location.content)
        local background = component("BG_BUILD", location.categoryID, location.dynamicID)

        if location.categoryID < 0 or location.hidden or not location.visible
            or not text:find("%S") or background == nil
            or background.hidden or not background.visible or background.height <= 0 then
            return false
        end

        local row = {
            index = location.dynamicID,
            top = background.y,
            height = background.height,
            text = {},
            controls = {},
        }

        for _, name in ipairs(logColumns) do
            local control = component(name, location.categoryID, location.dynamicID)

            if control ~= nil then
                row.controls[#row.controls + 1] = control

                if name == "FAVOURITE_BUILD" then
                    row.star = control
                end

                if name == "CODE_TEXT_BUILD" or name == "LOCATION_TEXT_BUILD" then
                    local text = plainText(control.content)
                    row.text[#row.text + 1] = text

                    if name == "CODE_TEXT_BUILD" then
                        row.text[#row.text + 1] = text:gsub("[%s%-]", "")
                    end
                end
            end
        end

        row.text = table.concat(row.text, " ")
        rows[#rows + 1] = row
        return false
    end)

    -- Preserve the client's selected sort order, independently of the dynamic IDs.
    table.sort(rows, function(a, b)
        if a.top == b.top then
            return a.index < b.index
        end

        return a.top < b.top
    end)

    return rows
end

function FairyRings:Define()
    return {
        title = "Fairy Rings",
        entries = {
            LEFT_CW = {
                cursor = id.Cursor.CURSOR_ROTATE_CLOCKWISE,
            },
            LEFT_ACW = {
                cursor = id.Cursor.CURSOR_ROTATE_ANTICLOCKWISE,
            },
            MID_CW = {
                cursor = id.Cursor.CURSOR_ROTATE_CLOCKWISE,
            },
            MID_ACW = {
                cursor = id.Cursor.CURSOR_ROTATE_ANTICLOCKWISE,
            },
            RIGHT_CW = {
                cursor = id.Cursor.CURSOR_ROTATE_CLOCKWISE,
            },
            RIGHT_ACW = {
                cursor = id.Cursor.CURSOR_ROTATE_ANTICLOCKWISE,
            },
        },
    }
end

-- Match native wheel controls by identity, independently of the selected ring code.
function FairyRings:ReadInterface()
    local window = component("MAINMODAL_WINDOW")
    local content = component("MAINMODAL_WINDOW_CONTENT")

    if window == nil or not window.visibleGlobal or content == nil then
        return nil
    end

    local rows = {}

    for index, name in ipairs(wheelControls) do
        local control = component(name)

        if control == nil then
            return nil
        end

        rows[#rows + 1] = {
            index = index,
            labels = { [name] = true },
            row = control,
            click = control,
            disabled = not control.visibleGlobal,
        }
    end

    return {
        window = window,
        content = content,
        nativeRows = rows,
        searchParent = component("LOG_CONTAINER_TOP"),
        logHolder = component("LOG_CONTENT_HOLDER"),
        logContent = component("LOG_CONTENT"),
        scrollbar = component("SCROLLBAR"),
        darkSeparator = component("LINE_DARK_TOP"),
        lightSeparator = component("LINE_LIGHT_TOP"),
    }
end

function FairyRings:BeginInterface()
    local session = self.session
    local snapshot = session.menu.snapshot
    local controls = {}

    session.cursorOverrides = {}
    session.headerControls = {}

    for _, name in ipairs(headerControls) do
        local control = component(name)

        if control ~= nil then
            session.headerControls[#session.headerControls + 1] = control
            controls[#controls + 1] = control
        end
    end

    for _, name in ipairs({ "searchParent", "logHolder", "darkSeparator", "lightSeparator" }) do
        if snapshot[name] ~= nil then
            controls[#controls + 1] = snapshot[name]
        end
    end

    session.nativeLayout = NativeLayout.FromControls(controls)
end

function FairyRings:Matches(snapshot)
    local previous = self.session and self.session.menu.snapshot

    return TeleportMenu.Matches(self, snapshot)
        and previous.searchParent == snapshot.searchParent
        and previous.logHolder == snapshot.logHolder
        and previous.logContent == snapshot.logContent
        and previous.scrollbar == snapshot.scrollbar
        and previous.darkSeparator == snapshot.darkSeparator
        and previous.lightSeparator == snapshot.lightSeparator
end

function FairyRings:BeginVisuals()
    local snapshot = self.session.menu.snapshot

    if snapshot.searchParent == nil or snapshot.logHolder == nil or snapshot.logContent == nil then
        return
    end

    self.search = prettyui.TextField.new(snapshot.searchParent, {
        placeholder = "Search destinations or codes...",
        height = searchHeight,
        maxLength = 80,
    })
end

-- Reserve a dedicated search row below the client's existing log controls.
function FairyRings:LayoutSearch()
    local session = self.session
    local snapshot = session.menu.snapshot
    local top, holder = snapshot.searchParent, snapshot.logHolder
    local extra = searchHeight + searchGap

    session.nativeLayout:Restore()
    session.nativeLayout:Apply(function()
        local searchY = top.height + 5

        -- Pin the existing header row before expanding its vertically centred parent.
        for _, control in ipairs(session.headerControls) do
            control:SetY(control.y)
            control:SetHeight(control.height)
        end

        top:SetHeight(top.height + extra)
        holder:SetY(holder.y + extra)
        holder:SetHeight(math.max(1, holder.height - extra))

        -- Both lines belong to LOG, outside the resized header and content holder.
        for _, name in ipairs({ "darkSeparator", "lightSeparator" }) do
            local control = snapshot[name]

            if control ~= nil then
                control:SetY(control.y + extra)
            end
        end

        self.search.root:SetPos(searchGap, searchY)
        self.search.root:SetSize(math.max(1, top.width - searchGap * 2), searchHeight)
    end)
end

local function restoreScroll(session)
    local state = session.searchScroll

    if state ~= nil then
        pcall(function()
            if state.control.scrollHeight == state.appliedHeight then
                state.control:SetScrollSize(state.width, state.height)
            end

            if state.control.scrollX == state.appliedX and state.control.scrollY == state.appliedY then
                state.control:SetScrollPos(state.x, state.y)
            end
        end)

        session.searchScroll = nil
    end
end

-- Re-read native rows after restoring our previous pass, so sorting and rebuilt lists stay live.
function FairyRings:FilterLog()
    local session = self.session

    local query = text.Trim(plainText(self.search:GetText()))
    local snapshot = session.menu.snapshot
    local content = snapshot.logContent

    if query == "" then
        restoreScroll(session)
        session.query = query
        return
    end

    local rows = logRows()

    -- Leave unfamiliar or temporarily empty client builds alone rather than hiding the entire log.
    if #rows == 0 then
        restoreScroll(session)
        return
    end

    local controls, columns, favouriteNumbers = {}, {}, {}

    for _, name in ipairs(logColumns) do
        local column = component(name)

        if column ~= nil then
            columns[#columns + 1] = column
            controls[#controls + 1] = column

            if name == "FAVOURITE_BUILD" then
                column:IterateDynamicComponents(function(control)
                    if control.type == ui.ComponentType.LABEL then
                        favouriteNumbers[#favouriteNumbers + 1] = control
                    end

                    return false
                end)
            end
        end
    end

    -- Number labels are appended after the star sprites rather than sharing row IDs.
    -- Resolve their original star before moving anything, retaining the native shortcut.
    local unassignedNumbers = {}

    for _, number in ipairs(favouriteNumbers) do
        local centre = number.y + number.height / 2
        local owner
        local ambiguous = false

        if not number.hidden and number.visible then
            for _, row in ipairs(rows) do
                local star = row.star

                if star ~= nil and centre >= star.y and centre < star.y + star.height then
                    if owner ~= nil then
                        ambiguous = true
                        break
                    end

                    owner = row
                end
            end
        end

        if owner ~= nil and not ambiguous then
            owner.controls[#owner.controls + 1] = number
        else
            unassignedNumbers[#unassignedNumbers + 1] = number
            controls[#controls + 1] = number
        end
    end

    for _, row in ipairs(rows) do
        for _, control in ipairs(row.controls) do
            controls[#controls + 1] = control
        end
    end

    session.filteredLayout = NativeLayout.FromControls(controls)
    local gap

    for index = 2, #rows do
        local previous = rows[index - 1]
        local space = rows[index].top - previous.top - previous.height

        if space >= 0 then
            gap = math.min(gap or space, space)
        end
    end

    gap = gap or 0
    local nextY, bottom = 0, 0
    local height

    session.filteredLayout:Apply(function()
        -- Do not leave labels floating over an unrelated result if no star could be identified.
        for _, control in ipairs(unassignedNumbers) do
            control.hidden = true
        end

        for _, row in ipairs(rows) do
            local matches = true

            for word in query:gmatch("%S+") do
                if not row.text:find(word, 1, true) then
                    matches = false
                    break
                end
            end

            for _, control in ipairs(row.controls) do
                if matches then
                    local position = control.position
                    control.position = ui.Pos.new(
                        position.x, position.y + nextY - row.top,
                        position.xParentPc, position.yParentPc,
                        position.xSelfPc, position.ySelfPc
                    )
                else
                    control.hidden = true
                end
            end

            if matches then
                bottom = nextY + row.height
                nextY = bottom + gap
            end
        end

        height = math.max(content.height, math.ceil(bottom))

        for _, column in ipairs(columns) do
            column:SetHeight(height)
        end
    end)

    if session.searchScroll == nil or content.scrollHeight ~= session.searchScroll.appliedHeight then
        session.searchScroll = {
            control = content,
            width = content.scrollWidth,
            height = content.scrollHeight,
            x = content.scrollX,
            y = content.scrollY,
        }
    end

    content:SetScrollSize(session.searchScroll.width, height)
    session.searchScroll.appliedHeight = height

    if session.query ~= query then
        content:SetScrollPos(content.scrollX, 0)
    else
        content:SetScrollPos(content.scrollX, math.min(content.scrollY, math.max(0, height - content.height)))
    end

    session.searchScroll.appliedX = content.scrollX
    session.searchScroll.appliedY = content.scrollY
    session.query = query
end

-- The native scrollbar is a scripted layer, not a slider that updates its thumb
-- automatically when LOG_CONTENT's scroll extent changes.
function FairyRings:UpdateScrollbar()
    local session = self.session
    local snapshot = session.menu.snapshot
    local scrollbar, content = snapshot.scrollbar, snapshot.logContent

    if scrollbar == nil then
        return
    end

    local parts = {}
    local controls = { scrollbar }

    for index = 0, 6 do
        local control = component("SCROLLBAR", 0, index)

        if control == nil then
            return
        end

        parts[index] = control
        controls[#controls + 1] = control
    end

    session.scrollbarLayout = NativeLayout.FromControls(controls)
    session.scrollbarLayout:Apply(function()
        local extent = math.max(content.height, content.scrollHeight)
        local trackTop = parts[4].height
        local trackHeight = math.max(0, scrollbar.height - trackTop - parts[5].height)
        local topCap, bottomCap = parts[2].height, parts[3].height
        local thumbHeight = math.min(trackHeight,
            math.max(topCap + bottomCap, math.floor(trackHeight * content.height / math.max(1, extent))))
        local range = math.max(0, extent - content.height)
        local fraction = range > 0 and math.max(0, math.min(1, content.scrollY / range)) or 0
        local thumbY = trackTop + math.floor((trackHeight - thumbHeight) * fraction)

        -- Track artwork, track input region, then the three-piece native thumb.
        parts[0]:SetY(trackTop + topCap)
        parts[0]:SetHeight(math.max(0, trackHeight - topCap - bottomCap))
        parts[6]:SetY(trackTop)
        parts[6]:SetHeight(trackHeight)
        parts[2]:SetY(thumbY)
        parts[1]:SetY(thumbY + topCap)
        parts[1]:SetHeight(math.max(0, thumbHeight - topCap - bottomCap))
        parts[3]:SetY(thumbY + thumbHeight - bottomCap)

        if range == 0 then
            scrollbar.hidden = true
        end
    end)
end

-- The client retains the wheel layout and all native turn actions.
function FairyRings:CalculateLayout()
    return {}
end

function FairyRings:ApplyLayout()
    if self.search ~= nil then
        if self.session.scrollbarLayout ~= nil then
            self.session.scrollbarLayout:Restore()
            self.session.scrollbarLayout = nil
        end

        -- Undo row changes before adjusting the surrounding native containers.
        if self.session.filteredLayout ~= nil then
            self.session.filteredLayout:Restore()
            self.session.filteredLayout = nil
        end

        self:LayoutSearch()
        self:FilterLog()
        self:UpdateScrollbar()
    end

    for _, row in ipairs(self.session.menu.rows) do
        local control = row.click
        local desired = row.destination.cursor

        if desired ~= nil and control.visibleGlobal then
            local cursor = control.cursorConfig
            local override = self.session.cursorOverrides[row.entryKey]

            if cursor.mouseOverCursor ~= desired then
                if override == nil or cursor.mouseOverCursor ~= override.applied then
                    override = {
                        control = control,
                        original = cursor.mouseOverCursor,
                    }
                    self.session.cursorOverrides[row.entryKey] = override
                end

                cursor.mouseOverCursor = desired
                override.applied = desired
            end
        end
    end
end

function FairyRings:ReleaseVisuals()
    if self.search ~= nil then
        self.search:Destroy()
        self.search = nil
    end
end

-- Restore only our own cursor changes when the shared controller releases this menu.
function FairyRings:ReleaseInterface()
    if self.session.scrollbarLayout ~= nil then
        self.session.scrollbarLayout:Restore()
    end

    if self.session.filteredLayout ~= nil then
        self.session.filteredLayout:Restore()
    end

    restoreScroll(self.session)

    if self.session.nativeLayout ~= nil then
        self.session.nativeLayout:Restore()
    end

    for _, override in pairs(self.session.cursorOverrides or {}) do
        pcall(function()
            local cursor = override.control.cursorConfig

            if cursor.mouseOverCursor == override.applied then
                cursor.mouseOverCursor = override.original
            end
        end)
    end
end

return FairyRings
