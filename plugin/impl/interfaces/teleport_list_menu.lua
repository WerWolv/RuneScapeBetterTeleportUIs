local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local components = require("impl/components")
local text = require("impl/text")

local TeleportListMenu = ModalChoiceMenu:Extend()
TeleportListMenu.interface = TeleportListMenu
TeleportListMenu.interfaceName = "TELEPORT_LIST (" .. id.Interface.TELEPORT_LIST .. ")"
TeleportListMenu.nativeInterface = {
    id = id.Interface.TELEPORT_LIST,
    prefix = "TELEPORT_LIST__",
    window = "MAINMODAL_WINDOW",
    content = "MAINMODAL_WINDOW_CONTENT",
    titleParent = "MAINMODAL_WINDOW_BORDER",
    close = "CLOSE_BUTTON",
    frame = { "MAINMODAL_WINDOW_BACKGROUND", "MAINMODAL_WINDOW_BORDER" },
    lastStaticID = 8,
}

local function component(name)
    return ui.Interfaces:GetComponent(id.Component["TELEPORT_LIST__" .. name])
end

local function isWithin(control, parent)
    if control == nil or parent == nil then return false end
    control = control.parent
    while control ~= nil and control ~= parent do control = control.parent end
    return control ~= nil
end

-- Dynamic IDs describe button identity, not destinations or keyboard bindings.
local function readButton(button)
    if button.type ~= ui.ComponentType.BUTTON then return nil end
    local label = text.Clean(button.label)
    local shortcut, name = label:match("^(.-)%s*:%s*(.*)$")
    if name == nil then name = label end
    name = text.Trim(name):gsub("%.$", "")
    shortcut = text.Trim(shortcut)
    if name == "" then return nil end

    return {
        row = button,
        click = button,
        labels = { [name] = true },
        shortcut = shortcut ~= "" and shortcut or nil,
    }
end

function TeleportListMenu:ReadInterface()
    local window = component("MAINMODAL_WINDOW")
    if window == nil or not window.visibleGlobal then
        self:ReportMatch(nil)
        return nil
    end

    local background = component("MAINMODAL_WINDOW_BACKGROUND")
    local content = component("MAINMODAL_WINDOW_CONTENT")
    local buttons = component("BUTTON_LAYER")
    for _, pair in ipairs({
        { name = "MAINMODAL_WINDOW_BACKGROUND", control = background, parent = window },
        { name = "MAINMODAL_WINDOW_CONTENT", control = content, parent = window },
        { name = "BUTTON_LAYER", control = buttons, parent = content },
    }) do
        if not isWithin(pair.control, pair.parent) then
            self:ReportMatch({"Not matched: missing or unexpectedly parented " .. pair.name .. "."})
            return nil
        end
    end

    local rows, seen, malformed = {}, {}, false
    buttons:IterateDynamicComponents(function(button)
        local key = components.Key(button)
        -- Do not use visibleGlobal: the native scrolling viewport may clip some buttons.
        if button.parent == buttons and not button.hidden and not seen[key] then
            seen[key] = true
            local entry = readButton(button)
            if entry == nil then malformed = true
            else rows[#rows + 1] = entry end
        end
        return false
    end)
    if malformed or #rows == 0 then
        self:ReportMatch({malformed and "Not matched: a dynamic child is not a named teleport button."
            or "Not matched: no visible direct dynamic buttons in BUTTON_LAYER."})
        return nil
    end

    table.sort(rows, function(a, b)
        if a.row.categoryID ~= b.row.categoryID then
            return a.row.categoryID < b.row.categoryID
        end
        return a.row.dynamicID < b.row.dynamicID
    end)
    for index, row in ipairs(rows) do row.index = index end

    local artwork = {}
    for _, name in ipairs({ "CATEGORY_TITLE_LAYER", "CATEGORY_OBJ_LAYER" }) do
        local control = component(name)
        if control ~= nil then artwork[#artwork + 1] = control end
    end

    local containers, control = {}, buttons
    while control ~= content do
        table.insert(containers, 1, control)
        control = control.parent
    end
    table.insert(containers, 1, content)

    return {
        window = window,
        content = content,
        nativeRows = rows,
        closeButton = component("CLOSE_BUTTON"),
        scrolling = buttons,
        scrollbar = component("SCROLLBAR_LAYER"),
        scrollContainers = containers,
        categoryArtwork = artwork,
    }
end

function TeleportListMenu:Matches(snapshot)
    if not ModalChoiceMenu.Matches(self, snapshot) then return false end
    for index, row in ipairs(snapshot.nativeRows) do
        if row.shortcut ~= self.session.menu.snapshot.nativeRows[index].shortcut then
            return false
        end
    end
    return true
end

function TeleportListMenu:IsDisabled(row)
    return row.click.enabled == false or ModalChoiceMenu.IsDisabled(self, row)
end

function TeleportListMenu:GetLayoutHost(window)
    local frame = assert(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__FULLMODAL_WINDOW))
    local content = assert(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__FULLMODAL_WINDOW_CONTENT))
    assert(window.parent == content and content.parent == frame, "Unexpected TELEPORT_LIST host hierarchy")
    return content, { frame, content }, {
        width = frame.width - content.width,
        height = frame.height - content.height,
        contentWidth = content.width,
        contentHeight = content.height,
        left = content.xyGlobal.x - frame.xyGlobal.x,
        top = content.xyGlobal.y - frame.xyGlobal.y,
    }
end

return TeleportListMenu
