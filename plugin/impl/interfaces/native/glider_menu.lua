local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local NativeLayout = require("impl/interfaces/native/native_layout")
local text = require("impl/text")

local GliderMenu = ModalChoiceMenu:Extend()
GliderMenu.interface = GliderMenu
GliderMenu.cacheNativeSnapshot = true
GliderMenu.interfaceName = "GLIDERMAP (" .. id.Interface.GLIDERMAP .. ")"
GliderMenu.nativeInterface = {
    trackedLayout = true,
    id = id.Interface.GLIDERMAP,
    prefix = "GLIDERMAP__",
    window = "WINDOW",
    content = "WINDOW_CONTENT",
    titleParent = "WINDOW_BORDER",
    close = "WINDOW_CLOSE_BUTTON",
    frame = { "WINDOW_BACKGROUND", "WINDOW_BORDER" },
    lastStaticID = 107,
    tooltipOwner = "row",
}

local destinations = {
    { "GRANDTREE", "Grand Tree" },
    { "MOUNTAIN", "White Wolf Mountain" },
    { "DIGSITE", "Digsite" },
    { "DESERT", "Al Kharid" },
    { "JUNGLE", "Karamja" },
    { "OGRE", "Feldip Hills" },
    { "TGV", "Tree Gnome Village" },
    { "ELFCITY", "Prifddinas" },
    { "ELR1", "Tuai Leit" },
}

local function component(name)
    return ui.Interfaces:GetComponent(id.Component["GLIDERMAP__" .. name])
end

function GliderMenu:ReadInterface()
    local window = component("WINDOW")

    if window == nil or window.parent == nil or not window.visibleGlobal then
        return nil
    end

    local content = component("WINDOW_CONTENT")
    local hubs, map = component("HUBS_LAYER"), component("WORLD_MAP")

    if content == nil or content.parent ~= window or hubs == nil or hubs.parent ~= content
        or map == nil or map.parent ~= content then
        self:ReportMatch({ "Not matched: missing Gnome Glider content, map or destination layer." })

        return nil
    end

    local rows = {}

    for index, destination in ipairs(destinations) do
        local prefix = destination[1] .. "_BUTTON"
        local row = component(prefix .. "_LAYER")
        local click = component(prefix .. "_ACTIVE_LAYER")
        local labelLayer = component(prefix .. "_TEXT_LAYER")
        local label = component(prefix .. "_TEXT")
        local disabled = component(prefix .. "_DISABLED_LAYER")

        if row == nil or row.parent ~= hubs or click == nil or click.parent ~= row
            or labelLayer == nil or labelLayer.parent ~= row or label == nil or label.parent ~= labelLayer
            or label.type ~= ui.ComponentType.LABEL or disabled == nil or disabled.parent ~= row then
            self:ReportMatch({ "Not matched: missing Gnome Glider button controls for " .. destination[1] .. "." })

            return nil
        end

        -- Keep hidden, quest-locked rows in the map without enabling their actions.
        local labelContent = text.Clean(label.content)
        rows[index] = {
            row = row,
            click = click,
            label = label,
            labelLayer = labelLayer,
            disabledLayer = disabled,
            labelContent = labelContent,
            labels = { [destination[2]] = true },
            shortcut = text.Hotkey(labelContent),
            index = index,
        }
    end

    local routes = {}

    hubs:IterateStaticComponents(function(control)
        if control.parent == hubs and control.type == ui.ComponentType.MODEL then
            routes[#routes + 1] = control
        end

        return false
    end)

    return {
        window = window,
        content = content,
        hubs = hubs,
        map = map,
        routes = routes,
        nativeRows = rows,
        closeButton = component("WINDOW_CLOSE_BUTTON"),
    }
end

function GliderMenu:GetSnapshot()
    local snapshot = ModalChoiceMenu.GetSnapshot(self)

    if snapshot == nil then
        return nil
    end

    local current = snapshot.content.parent == snapshot.window
        and component("HUBS_LAYER") == snapshot.hubs and snapshot.hubs.parent == snapshot.content
        and component("WORLD_MAP") == snapshot.map and snapshot.map.parent == snapshot.content

    for index, destination in ipairs(destinations) do
        local prefix = destination[1] .. "_BUTTON"
        local row = snapshot.nativeRows[index]

        current = current and component(prefix .. "_LAYER") == row.row and row.row.parent == snapshot.hubs
            and component(prefix .. "_ACTIVE_LAYER") == row.click and row.click.parent == row.row
            and component(prefix .. "_TEXT_LAYER") == row.labelLayer and row.labelLayer.parent == row.row
            and component(prefix .. "_TEXT") == row.label and row.label.parent == row.labelLayer
            and component(prefix .. "_DISABLED_LAYER") == row.disabledLayer and row.disabledLayer.parent == row.row
            and text.Clean(row.label.content) == row.labelContent
    end

    if not current then
        self:InvalidateSnapshot()

        return ModalChoiceMenu.GetSnapshot(self)
    end

    return snapshot
end

function GliderMenu:Matches(snapshot)
    return self.session ~= nil and self.session.menu.snapshot == snapshot
end

function GliderMenu:IsDisabled(row)
    return row.native.disabledLayer.visibleGlobal or ModalChoiceMenu.IsDisabled(self, row)
end

function GliderMenu:LayoutRowContainers(x, y, width, height)
    ModalChoiceMenu.LayoutRowContainers(self, x, y, width, height)

    local snapshot = self.session.menu.snapshot
    NativeLayout.Set(snapshot.map, "hidden", true)

    -- Native flight scripts can reveal these models again during travel.
    for _, route in ipairs(snapshot.routes) do
        NativeLayout.Set(route, "alpha", 0)
        NativeLayout.Set(route, "clickthrough", true)
    end
end

return GliderMenu
