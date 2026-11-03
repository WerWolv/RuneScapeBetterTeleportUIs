local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local native = require("impl/interfaces/native_helpers")
local components = require("impl/components")
local text = require("impl/text")

local PortalNexusMenu = ModalChoiceMenu:Extend()
PortalNexusMenu.interface = PortalNexusMenu
PortalNexusMenu.interfaceName = "PORTAL_NEXUS (" .. id.Interface.CONSTRUCTION_HOUSE_FURNITURE_PORTAL_NEXUS .. ")"
PortalNexusMenu.nativeInterface = {
    id = id.Interface.CONSTRUCTION_HOUSE_FURNITURE_PORTAL_NEXUS,
    prefix = "CONSTRUCTION_HOUSE_FURNITURE_PORTAL_NEXUS__",
    window = "MAINMODAL_WINDOW",
    content = "MAINMODAL_WINDOW_CONTENT",
    titleParent = "MAINMODAL_WINDOW_BORDER",
    close = "MAINMODAL_WINDOW_CLOSE_BUTTON",
    frame = {
        "MAINMODAL_WINDOW_BACKGROUND",
        "MAINMODAL_WINDOW_BORDER",
    },
    lastStaticID = 8,
}

local function component(name)
    return ui.Interfaces:GetComponent(id.Component["CONSTRUCTION_HOUSE_FURNITURE_PORTAL_NEXUS__" .. name])
end

local function hasTeleportAction(control)
    local ops = control.opConfig

    if ops ~= nil then
        for index = 1, ops.numOpNames do
            if text.Clean(ops:GetOpName(index)):lower():find("teleport", 1, true) then
                return true
            end
        end
    end

    return false
end

-- Rows have a background, shortcut label, spell sprite and destination label.
-- Inspect their roles rather than assuming that dynamic IDs encode a destination.
local function readRow(row)
    local labels, sprites = {}, {}
    local click = hasTeleportAction(row) and row or nil

    components.Walk(row, function(control)
        if control == row then
            return
        end

        if control.parent ~= row then
            return false
        end

        if click == nil and hasTeleportAction(control) then
            click = control
        end

        if control.type == ui.ComponentType.LABEL then
            labels[#labels + 1] = control
        elseif control.type == ui.ComponentType.SPRITE then
            sprites[#sprites + 1] = control
        end

        return false
    end)

    if #labels ~= 2 or #sprites ~= 1 then
        return nil
    end

    table.sort(labels, function(a, b)
        return a.dynamicID < b.dynamicID
    end)

    local shortcut = text.Clean(labels[1].content):gsub("%.$", "")
    local name = text.Clean(labels[2].content)

    if name == "" or sprites[1].spriteID < 0 then
        return nil
    end

    return {
        row = row,
        click = click or row,
        labels = { [name] = true },
        shortcut = shortcut,
        spriteID = sprites[1].spriteID,
    }
end

function PortalNexusMenu:ReadInterface()
    local window = component("MAINMODAL_WINDOW")

    if window == nil or not window.visibleGlobal then
        return nil
    end

    local content = component("MAINMODAL_WINDOW_CONTENT")
    local active = component("ACTIVE_LAYER")
    local contents = component("ACTIVE_CONTENTS")
    local scrolling = component("ACTIVE_SCROLLING")

    if content == nil or content.parent ~= window
        or active == nil or active.parent ~= content
        or contents == nil or contents.parent ~= active
        or scrolling == nil or scrolling.parent ~= contents then
        return nil
    end

    local rows = native.ReadDynamicRows(scrolling, readRow)

    if rows == nil then
        return nil
    end

    return {
        window = window,
        content = content,
        nativeRows = rows,
        closeButton = component("MAINMODAL_WINDOW_CLOSE_BUTTON"),
        scrolling = scrolling,
        scrollbar = component("ACTIVE_SCROLLBAR"),
        scrollContainers = { content, active, contents, scrolling },
    }
end

-- A recycled row can keep its name while its native shortcut or artwork changes.
function PortalNexusMenu:Matches(snapshot)
    if not ModalChoiceMenu.Matches(self, snapshot) then
        return false
    end

    for index, row in ipairs(snapshot.nativeRows) do
        local previous = self.session.menu.snapshot.nativeRows[index]

        if row.shortcut ~= previous.shortcut or row.spriteID ~= previous.spriteID then
            return false
        end
    end

    return true
end

return PortalNexusMenu
