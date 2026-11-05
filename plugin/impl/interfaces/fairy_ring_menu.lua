local TeleportMenu = require("impl/teleport_menu")
local text = require("impl/text")
local settings = require("impl/settings")
local aliases = require("menus/enhancements/fairy_rings/fairy_ring_aliases")

local FairyRingMenu = TeleportMenu:Extend()
FairyRingMenu.interface = FairyRingMenu
FairyRingMenu.interfaceName = "FAIRYRINGS (" .. id.Interface.FAIRYRINGS .. ")"
FairyRingMenu.logColumns = {
    "FAVOURITE_BUILD", "FAVOURITE_CLICK", "BG_BUILD",
    "CODE_TEXT_BUILD", "LOCATION_TEXT_BUILD", "TEXT_CLICK",
}

local wheelControls = {
    "LEFT_CW", "LEFT_ACW",
    "MID_CW", "MID_ACW",
    "RIGHT_CW", "RIGHT_ACW",
}

function FairyRingMenu.Component(name, category, index)
    local componentID = id.Component["FAIRYRINGS__" .. name]

    if index ~= nil then
        return ui.Interfaces:GetComponent(componentID, category, index)
    end

    return ui.Interfaces:GetComponent(componentID)
end

function FairyRingMenu.PlainText(value)
    return text.StripFormatting(value):lower():gsub("%s+", " ")
end

local component = FairyRingMenu.Component
local plainText = FairyRingMenu.PlainText

-- Discover only native log entries. Coordinates never imply that a ring is unlocked.
function FairyRingMenu.ReadLogRows()
    local rows = {}
    local locations = component("LOCATION_TEXT_BUILD")

    if locations == nil then
        return rows
    end

    local customAliases = aliases.Parse(settings.Get("fairyRingAliases"))

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
            name = text.StripFormatting(location.content),
            text = { locationText },
            codes = {},
            controls = {},
        }

        for _, name in ipairs(FairyRingMenu.logColumns) do
            local control = component(name, location.categoryID, location.dynamicID)

            if control ~= nil then
                row.controls[#row.controls + 1] = control

                if name == "FAVOURITE_BUILD" then
                    row.star = control
                elseif name == "FAVOURITE_CLICK" then
                    row.favouriteClick = control
                elseif name == "TEXT_CLICK" then
                    row.click = control
                elseif name == "CODE_TEXT_BUILD" then
                    local codes = plainText(control.content):gsub("[%s%-]", "")

                    for code in codes:gmatch("%a%a%a") do
                        row.codes[#row.codes + 1] = code

                        for _, alias in ipairs(aliases.searchAliases[code:upper()] or {}) do
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

    -- Retain the client's chosen sort order rather than sorting by dynamic ID.
    table.sort(rows, function(a, b)
        if a.top == b.top then
            return a.index < b.index
        end

        return a.top < b.top
    end)

    return rows
end

function FairyRingMenu:Define()
    local entries = {}

    for _, name in ipairs(wheelControls) do
        entries[name] = {
            cursor = name:sub(-3) == "ACW" and id.Cursor.CURSOR_ROTATE_ANTICLOCKWISE
                or id.Cursor.CURSOR_ROTATE_CLOCKWISE,
        }
    end

    return { title = "Fairy Ring Teleport Network", entries = entries }
end

-- Wheel identities remain stable while the native log is rebuilt or sorted.
function FairyRingMenu:ReadInterface()
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

function FairyRingMenu:Matches(snapshot)
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

return FairyRingMenu
