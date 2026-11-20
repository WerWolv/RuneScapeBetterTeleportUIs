local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local NativeLayout = require("impl/interfaces/native/native_layout")
local cleanup = require("impl/cleanup")
local text = require("impl/text")

local SpiritTreeMenu = ModalChoiceMenu:Extend()
SpiritTreeMenu.interface = SpiritTreeMenu
SpiritTreeMenu.cacheNativeSnapshot = true
SpiritTreeMenu.interfaceName = "SPIRITTREE2 (" .. id.Interface.SPIRITTREE2 .. ")"
SpiritTreeMenu.nativeInterface = {
    trackedLayout = true,
    id = id.Interface.SPIRITTREE2,
    prefix = "SPIRITTREE2__",
    window = "SPIRITTREE_WINDOW",
    content = "SPIRITTREE_WINDOW_CONTENT",
    titleParent = "SPIRITTREE_WINDOW_BORDER",
    close = "SPIRITTREE_WINDOW_CLOSE_BUTTON",
    frame = { "SPIRITTREE_WINDOW_BACKGROUND", "SPIRITTREE_WINDOW_BORDER" },
    lastStaticID = 37,
}

local tooltipHookID = "teleportMapsSpiritTreeTooltip"
local tooltipHooks = { ui.Hook.ONMOUSEOVER, ui.Hook.ONMOUSEREPEAT }

-- These static controls identify destinations; their sibling text supplies the
-- current shortcut. The native HUBS_LAYER retains all keyboard/action scripts.
local destinations = {
    { "VILLAGE", "COM_12", "Tree Gnome Village" },
    { "STRONGHOLD", "COM_14", "Tree Gnome Stronghold" },
    { "OURANIA", "COM_16", "Battlefield" },
    { "GRANDEXCHANGE", "COM_18", "Grand Exchange" },
    { "MOBILISINGARMIES", "COM_20", "South Feldip Hills" },
    { "PORTSARIM", "COM_22", "Port Sarim" },
    { "ETCETERIA", "COM_24", "Etceteria" },
    { "BRIMHAVEN", "COM_26", "Brimhaven" },
    { "POISONWASTE", "COM_28", "Poison Waste" },
    { "ELFCITY", "ELFCITY_TEXT", "Prifddinas" },
    { "MANOR_FARM", "MANOR_FARM_TEXT", "Manor Farm" },
    { "POH", "POH_TEXT", "Player-owned house" },
}

local function component(name)
    return ui.Interfaces:GetComponent(id.Component["SPIRITTREE2__" .. name])
end

function SpiritTreeMenu:ReadInterface()
    local window = component("SPIRITTREE_WINDOW")

    if window == nil or window.parent == nil or not window.visibleGlobal then
        return nil
    end

    local content = component("SPIRITTREE_WINDOW_CONTENT")
    local hubs, map = component("HUBS_LAYER"), component("WORLD_MAP")

    if content == nil or content.parent ~= window or hubs == nil or hubs.parent ~= content
        or map == nil or map.parent ~= content then
        self:ReportMatch({ "Not matched: missing Spirit Tree content, map or destination layer." })

        return nil
    end

    local rows = {}

    for index, destination in ipairs(destinations) do
        local click, label = component(destination[1]), component(destination[2])

        if click == nil or click.parent ~= hubs or click.type ~= ui.ComponentType.SPRITE
            or label == nil or label.parent ~= hubs or label.type ~= ui.ComponentType.LABEL then
            self:ReportMatch({ "Not matched: missing Spirit Tree control pair for " .. destination[1] .. "." })

            return nil
        end

        -- Include hidden destinations too, allowing availability to change live.
        rows[index] = {
            row = click,
            click = click,
            label = label,
            labels = { [destination[3]] = true },
            shortcut = text.Clean(label.content),
            index = index,
        }
    end

    return {
        window = window,
        content = content,
        hubs = hubs,
        map = map,
        nativeRows = rows,
        closeButton = component("SPIRITTREE_WINDOW_CLOSE_BUTTON"),
    }
end

-- Static children can be replaced while their modal host survives.
function SpiritTreeMenu:GetSnapshot()
    local snapshot = ModalChoiceMenu.GetSnapshot(self)

    if snapshot == nil then
        return nil
    end

    local current = snapshot.content.parent == snapshot.window
        and component("HUBS_LAYER") == snapshot.hubs and snapshot.hubs.parent == snapshot.content
        and component("WORLD_MAP") == snapshot.map and snapshot.map.parent == snapshot.content

    for index, destination in ipairs(destinations) do
        local row = snapshot.nativeRows[index]

        current = current and component(destination[1]) == row.click and row.click.parent == snapshot.hubs
            and component(destination[2]) == row.label and row.label.parent == snapshot.hubs
            and text.Clean(row.label.content) == row.shortcut
    end

    if not current then
        self:InvalidateSnapshot()

        return ModalChoiceMenu.GetSnapshot(self)
    end

    return snapshot
end

function SpiritTreeMenu:Matches(snapshot)
    -- A refreshed snapshot also carries new shortcut labels or artwork owners.
    return self.session ~= nil and self.session.menu.snapshot == snapshot
end

function SpiritTreeMenu:IsDisabled(row)
    return row.click.spriteID == id.Sprite.AIF_SPIRITTREE_MAP_2
        or ModalChoiceMenu.IsDisabled(self, row)
end

function SpiritTreeMenu:RefreshAvailability(snapshot)
    ModalChoiceMenu.RefreshAvailability(self, snapshot)

    -- Native script 9765 compares packed coordinates. The Lua var API can
    -- expose the source as a CoordGrid, so normalize both sides before comparing.
    local source = var.VarPlayer.SPIRITTREE_COORD.value

    if type(source) ~= "number" then
        source = source:ToPacked()
    end

    for _, row in ipairs(self.session.menu.rows) do
        local coordinate = config.Enum.SPIRITTREE_COORD:GetOutputValue(row.native.index - 1)

        if coordinate ~= nil and type(coordinate) ~= "number" then
            coordinate = coordinate:ToPacked()
        end

        row.currentLocation = source > 0 and source == coordinate
        row.disabled = row.disabled or row.currentLocation
    end
end

function SpiritTreeMenu:AttachTooltip(entry, target)
    ModalChoiceMenu.AttachTooltip(self, entry, target)

    -- Suppress native hover scripts on the action owner, even when the plugin
    -- tooltip is attached to a disabled destination's passive probe.
    local controls = self.session.nativeTooltipControls or {}
    self.session.nativeTooltipControls = controls

    local nativeTarget = entry.click
    local tracked = false

    for _, control in ipairs(controls) do
        if control == nativeTarget then
            tracked = true
            break
        end
    end

    if not tracked then
        controls[#controls + 1] = nativeTarget
    end

    for _, hook in ipairs(tooltipHooks) do
        -- Keep suppression after any freshly reattached plugin hover listeners.
        if tracked then
            nativeTarget:Unsubscribe(hook, tooltipHookID)
        end

        nativeTarget:Subscribe(hook, tooltipHookID, function()
            return false
        end)
    end
end

function SpiritTreeMenu:LayoutRowContainers(x, y, width, height)
    ModalChoiceMenu.LayoutRowContainers(self, x, y, width, height)

    local snapshot = self.session.menu.snapshot
    NativeLayout.Set(snapshot.map, "hidden", true)

    for _, row in ipairs(snapshot.nativeRows) do
        NativeLayout.Set(row.label, "alpha", 0)
        NativeLayout.Set(row.label, "clickthrough", true)
    end
end

function SpiritTreeMenu:ReleaseInterface()
    for _, control in ipairs(self.session.nativeTooltipControls or {}) do
        for _, hook in ipairs(tooltipHooks) do
            cleanup.Try("restore Spirit Tree hover tooltip", function()
                control:Unsubscribe(hook, tooltipHookID)
            end)
        end
    end

    self.session.nativeTooltipControls = nil
    ModalChoiceMenu.ReleaseInterface(self)
end

return SpiritTreeMenu
