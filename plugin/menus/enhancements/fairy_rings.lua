local TeleportMenu = require("impl/teleport_menu")
local NativeLayout = require("impl/native_layout")
local TextFieldAutofocus = require("impl/text_field_autofocus")
local text = require("impl/text")
local userSettings = require("impl/settings")
local fairyRingAliases = require("impl/fairy_ring_aliases")
local FairyRings = TeleportMenu:Extend("fairyRings")
FairyRings.interface = FairyRings
FairyRings.interfaceName = "FAIRYRINGS (" .. id.Interface.FAIRYRINGS .. ")"

-- Taken with permission from https://github.com/PrettyRS/fairyrings/blob/main/aliases.lua
-- Original code is licensed under BSD 3-Clause which may be found under licenses/PRETTYRS_FAIRYRINGS_LICENSE
local searchAliases = {
    AIQ = {
        "port sarim",
        "rimmington",
        "anvil",
        "ice dungeon",
        "frost dragons"
    },
    AIR = {
        "clue",
        "clue scroll",
        "treasure trail"
    },
    AIS = {
        "guthix"
    },
    ALR = {
        "abby demons",
        "abyssal demons"
    },
    AJR = {
        "fremennik",
        "mountain camp"
    },
    AKP = {
        "home",
        "poh"
    },
    AKQ = {
        "falconry",
        "phoenix lair",
        "fishing colony",
        "eternal magic trees",
        "airuts"
    },
    AKS = {
        "gnome glider",
        "oo'glog",
        "chompy birds"
    },
    ALP = {
        "jiggig"
    },
    ALQ = {
        "araxxor",
        "port phasmatys"
    },
    ALS = {
        "hemenster",
        "seers village",
        "fishing guild"
    },
    BIQ = {
        "kq",
        "bandit camp",
        "mining camp",
        "kalphite cave",
        "kalphite queen"
    },
    BJP = {
        "grove"
    },
    BJQ = {
        "kuradal",
        "slayer",
        "mithril dragons",
        "waterfiends"
    },
    BJR ={
        "brimhaven"
    },
    BIP = {
        "brilliant wisps",
        "mta",
        "mage training arena",
        "het's oasis",
        "slayer"
    },
    BJS = {
        "solak",
        "vinecrawlers",
        "bulbous crawler",
        "moss golem"
    },
    BIS = {
        "ardy",
        "ardougne"
    },
    BKP = {
        "jiggig",
        "incandescent wisps"
    },
    BKR = {
        "nature spirit",
        "nature grotto"
    },
    BKS = {
        "wendlewick",
        "eastfold farm",
        "crabs"
    },
    BLP = {
        "mor ul rek",
        "volcano",
        "karamja"
    },
    BLR = {
        "witchaven",
        "ardougne",
        "keep le faye",
        "pof",
        "player owned farm"
    },
    BLQ = {
        "bandos throne room"
    },
    CIQ = {
        "tree gnome village",
        "castle wars"
    },
    CJR = {
        "camelot",
        "seers village",
        "rellekka"
    },
    CIS = {
        "evil bob"
    },
    CJS = {
        "karamja"
    },
    CKQ = {
        "desert",
        "soul altar",
        "sophanem"
    },
    CKR = {
        "nature altar",
        "shilo village",
        "cairn isle",
        "karambwanji"
    },
    CKS = {
        "temple trekking",
        "paterdomus",
        "slayer tower",
        "mushroom patch"
    },
    CLR = {
        "agility course",
        "monkey"
    },
    CLS = {
        "hazelmere"
    },
    DJP ={
        "ardougne",
        "port khazard",
        "monastery"
    },
    DIP = {
        "trouble brewing",
        "cave horrors"    
    },
    DIS = {
        "draynor village",
        "runecrafting guild",
        "lumbridge swamp"
    },
    DJR = {
        "camelot",
        "seers village",
        "rellekka"
    },
    DJS = {
        "summoning obelisk",
        "amlodd",
        "ithell"
    },
    DKP = {
        "karambwans",
        "gnome glider",
        "shipyard"
    },
    DKQ = {
        "rotm",
        "ritual of the mahjarrat",
        "mahjarrat",
        "jas"
    },
    DKR = {
        "varrock",
        "grand exchange",
        "wilderness",
        "ge"
    },
    DKS = {
        "keldagrim",
        "rellekka",
        "fremennik",
        "fremmy",
        "polar hunter area"
    },
    DLP = {
        "bank"
    },
    DLQ ={
        "hunter area",
        "uzer"
    },
    DLS = {
        "canifis",
        "tunnel",
        "barrows",
        "morton",
        "mort'ton"
    }
}

local wheelControls = {
    "LEFT_CW",  "LEFT_ACW",
    "MID_CW",   "MID_ACW",
    "RIGHT_CW", "RIGHT_ACW",
}

local searchHeight, searchGap = 28, 6
local searchIconSize, searchIconInset = 24, 4
local selectedRowColor = 0x66512E
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

    local customAliases = fairyRingAliases.Parse(userSettings.Get("fairyRingAliases"))

    locations:IterateDynamicComponents(function(location)
        local locationText = plainText(location.content)
        local background = component("BG_BUILD", location.categoryID, location.dynamicID)

        if location.categoryID < 0 or location.hidden or not location.visible
            or not locationText:find("%S") or background == nil
            or background.hidden or not background.visible or background.height <= 0 then
            return false
        end

        local row = {
            index = location.dynamicID,
            top = background.y,
            height = background.height,
            background = background,
            location = locationText,
            text = { locationText },
            codes = {},
            controls = {},
        }

        for _, name in ipairs(logColumns) do
            local control = component(name, location.categoryID, location.dynamicID)

            if control ~= nil then
                row.controls[#row.controls + 1] = control

                if name == "FAVOURITE_BUILD" then
                    row.star = control
                end

                if name == "CODE_TEXT_BUILD" then
                    local codes = plainText(control.content):gsub("[%s%-]", "")

                    for code in codes:gmatch("%a%a%a") do
                        row.codes[#row.codes + 1] = code

                        for _, alias in ipairs(searchAliases[code:upper()] or {}) do
                            row.text[#row.text + 1] = plainText(alias)
                        end

                        for _, alias in ipairs(customAliases[code:upper()] or {}) do
                            row.text[#row.text + 1] = text.Trim(plainText(alias))
                        end
                    end
                end
            end
        end

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
        keyboardListener = component("KEYBOARD_LISTENER"),
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
    session.favouriteIcons = {}
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

    for name, color in pairs({
        LINE_DARK_TOP = 0x24180F,
        LINE_LIGHT_TOP = 0x3D2B1B,
        LINE_DARK_BOTTOM = 0x24180F,
        LINE_LIGHT_BOTTOM = 0x3D2B1B,
    }) do
        local line = component(name)

        if line ~= nil then
            line.rgb = color
            line.alpha = 1
        end
    end
end

function FairyRings:Matches(snapshot)
    local previous = self.session and self.session.menu.snapshot

    return TeleportMenu.Matches(self, snapshot)
        and previous.searchParent == snapshot.searchParent
        and previous.keyboardListener == snapshot.keyboardListener
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
        placeholder = "Type to search destinations or codes...",
        height = searchHeight,
        maxLength = 80,
        contentMargin = ui.Margin.new(searchIconInset * 2 + searchIconSize, 3, 8, 0),
    })

    self:UpdateSearchAutoFocus()

    self.searchIcon = ui.Sprite.new(snapshot.searchParent)
    self.searchIcon.spriteID = id.Sprite.AIF_SEARCH_ICON_0
    self.searchIcon:SetSize(searchIconSize, searchIconSize)
    self.searchIcon.clickthrough = true
end

function FairyRings:UpdateSearchAutoFocus()
    local snapshot = self.session.menu.snapshot
    local enabled = userSettings.Get("autoFocusFairyRingSearch")

    if not enabled then
        if self.searchInput ~= nil then
            self.searchInput:Destroy()
            self.searchInput = nil
        end

        return
    end

    if self.searchInput == nil and self.search ~= nil and snapshot.keyboardListener ~= nil then
        self.searchInput = TextFieldAutofocus:New(self.search, snapshot.keyboardListener, {
            hookID = "teleportMapsSearchInput",
            font = config.Font.MUSEO_SANS_15PT_REGULAR,
            -- Leave 1–9 to the native favourite shortcuts.
            forwardKey = function(_, character)
                return character ~= nil and character >= 49 and character <= 57
            end,
        })
        self.searchInput:Attach()
    end
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
        self.searchIcon:SetPos(searchGap + searchIconInset, searchY + (searchHeight - searchIconSize) / 2)
        self.searchIcon:MoveToFront()
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

    -- Capture the native alternating shades before applying filtered row positions.
    local stripes = {}

    for index = 1, math.min(2, #rows) do
        local background = rows[index].background

        stripes[index] = {
            rgb = background.rgb,
            alpha = background.alpha,
        }
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

    local codeQuery = query:gsub("[%s%-]", "")
    local exactCode = false
    local allowTypos = userSettings.Get("fuzzyFairyRingSearch")

    -- A complete native code selects only that code; names and aliases stay separate.
    for _, row in ipairs(rows) do
        for _, code in ipairs(row.codes) do
            if code == codeQuery then
                exactCode = true
            end
        end
    end

    for order, row in ipairs(rows) do
        row.order = order

        if not exactCode then
            row.score = text.FuzzyScore(row.text, query, allowTypos)
        end

        for _, code in ipairs(row.codes) do
            if code == codeQuery
                or not exactCode and codeQuery ~= "" and code:sub(1, #codeQuery) == codeQuery then
                row.score = math.huge
            end
        end
    end

    table.sort(rows, function(a, b)
        if a.score == b.score then
            return a.order < b.order
        end

        return (a.score or -math.huge) > (b.score or -math.huge)
    end)

    local nextY, bottom, visibleRows = 0, 0, 0
    local height

    session.filteredLayout:Apply(function()
        -- Do not leave labels floating over an unrelated result if no star could be identified.
        for _, control in ipairs(unassignedNumbers) do
            control.hidden = true
        end

        for _, row in ipairs(rows) do
            local matches = row.score ~= nil

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
                local stripe = stripes[visibleRows % #stripes + 1]
                row.background.rgb = stripe.rgb
                row.background.alpha = stripe.alpha
                visibleRows = visibleRows + 1

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

        scrollbar.hidden = false
    end)
end

-- The native destination label identifies the selection, including special destinations.
function FairyRings:HighlightDestination()
    local destination = component("COMBINATION_DESTINATION")

    if destination == nil or not destination.visibleGlobal then
        return
    end

    local selected = text.Trim(plainText(destination.content))

    if selected == "" then
        return
    end

    for _, row in ipairs(logRows()) do
        if text.Trim(row.location) == selected then
            self.session.highlightLayout = NativeLayout.FromControls({ row.background })
            self.session.highlightLayout:Apply(function()
                row.background.rgb = selectedRowColor
                row.background.alpha = 1
            end)

            return
        end
    end
end

-- The client retains the wheel layout and all native turn actions.
function FairyRings:CalculateLayout()
    return {}
end

function FairyRings:ApplyLayout()
    -- Restore selection styling before reading the native shades for filtered stripes.
    if self.session.highlightLayout ~= nil then
        self.session.highlightLayout:Restore()
        self.session.highlightLayout = nil
    end

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

    self:HighlightDestination()

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

-- Replace unselected star artwork on the native sprites so favourite actions stay live.
function FairyRings:UpdateVisuals()
    self:UpdateSearchAutoFocus()

    local favourites = component("FAVOURITE_BUILD")

    if favourites == nil then
        return
    end

    local image = Plugin.resources.icons.fairy_ring_favorite_unselected

    if not image.loaded then
        image:Load()
    end

    if not image.loaded then
        return
    end

    favourites:IterateDynamicComponents(function(control)
        if control.type == ui.ComponentType.SPRITE
            and control.spriteID == id.Sprite.FAIRY_RINGS_ICON_FAVOURITE_0 then
            control.sprite = image
            self.session.favouriteIcons[control] = control.runtimeSprite
        end

        return false
    end)
end

function FairyRings:ReleaseVisuals()
    if self.searchInput ~= nil then
        self.searchInput:Destroy()
        self.searchInput = nil
    end

    if self.searchIcon ~= nil then
        self.searchIcon:Destroy()
        self.searchIcon = nil
    end

    if self.search ~= nil then
        self.search:Destroy()
        self.search = nil
    end
end

-- Restore only our own cursor changes when the shared controller releases this menu.
function FairyRings:ReleaseInterface()
    if self.session.highlightLayout ~= nil then
        self.session.highlightLayout:Restore()
    end

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
