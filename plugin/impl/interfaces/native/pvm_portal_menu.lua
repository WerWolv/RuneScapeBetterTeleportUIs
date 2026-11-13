local SplitLayerMenu = require("impl/interfaces/native/split_layer_menu")

local PvmPortalMenu = SplitLayerMenu:Extend()
local portalDestinations
PvmPortalMenu.interface = PvmPortalMenu
PvmPortalMenu.cacheNativeSnapshot = true
PvmPortalMenu.blockDisabledClicks = true
PvmPortalMenu.interfaceName = "PVM_PORTAL_MANAGEMENT (" .. id.Interface.PVM_PORTAL_MANAGEMENT .. ")"
PvmPortalMenu.nativeInterface = {
    trackedLayout = true,
    id = id.Interface.PVM_PORTAL_MANAGEMENT,
    prefix = "PVM_PORTAL_MANAGEMENT__",
    window = "MAINMODAL_WINDOW",
    content = "MAINMODAL_WINDOW_CONTENT",
    titleParent = "MAINMODAL_WINDOW_BORDER",
    close = "MAINMODAL_WINDOW_CLOSE_BUTTON",
    frame = { "MAINMODAL_WINDOW_BACKGROUND", "MAINMODAL_WINDOW_BORDER" },
    lastStaticID = 17,
    controls = "CONTROL_LAYER",
    build = "BUILD_LAYER",
    artworkStride = 11,
    labelOffset = 9,
    hide = { "HEADER_LAYER", "SORT_LAYER", "CONTENTS_BACKGROUND_LAYER", "SCROLLBAR_LAYER" },
}

-- The assignment bytes store destination IDs, not DBRow IDs or sorted UI indices.
-- PVM_PORTAL_DESTINATION column 1 is that ID; column 3 is its native label.
-- Column 7 lists picker membership: 1 = Max Guild, 2 = War's Retreat.
function PvmPortalMenu:ConfigureDestinations(entries)
    if portalDestinations == nil then
        portalDestinations = {}
        for name, rowID in pairs(id.DBRow) do
            if type(name) == "number" and type(rowID) == "string" then
                name, rowID = rowID, name
            end
            if type(name) == "string" and type(rowID) == "number"
                and (name:match("^PVM_HUB_PORTAL_") or name:match("^PVM_PORTAL_")) then
                local row = config.DBRow[name]
                if row ~= nil and row.ownerDBTable.id == id.DBTable.PVM_PORTAL_DESTINATION then
                    local destinationID = row:GetColumnValues(1)[1]
                    local label = row:GetColumnValues(3)[1]
                    if type(destinationID) == "number" and destinationID > 0 and type(label) == "string" then
                        local maxGuild, warsRetreat = false, false
                        for _, picker in ipairs(row:GetColumnValues(7)) do
                            maxGuild = maxGuild or picker == 1
                            warsRetreat = warsRetreat or picker == 2
                        end
                        portalDestinations[label] = {
                            id = destinationID,
                            maxGuildOnly = maxGuild and not warsRetreat,
                        }
                    end
                end
            end
        end
    end

    for name, destination in pairs(portalDestinations) do
        if entries[name] ~= nil then
            -- Aliases share the same definition, so encounter/location names agree.
            entries[name].portalDestinationID = destination.id
            entries[name].maxGuildOnly = destination.maxGuildOnly
        end
    end
end

function PvmPortalMenu:RefreshAvailability(snapshot)
    SplitLayerMenu.RefreshAvailability(self, snapshot)
    snapshot = snapshot or self.session.menu.snapshot
    -- The native picker includes its full roster even when destinations are locked.
    -- Max Guild's exclusive rows identify the context without relying on location
    -- or translated headings. Re-evaluate whenever native discovery changes.
    if snapshot.maxGuildPortal == nil then
        snapshot.maxGuildPortal = false
        for _, row in ipairs(self.session.menu.rows) do
            if row.destination.maxGuildOnly then
                snapshot.maxGuildPortal = true
                break
            end
        end
    end

    local first, second, maxGuild
    if snapshot.maxGuildPortal then
        maxGuild = var.VarPlayer.ELFCITY_MAX_GUILD_PVM_PORTAL.value
    else
        local state = var.VarPlayer.PVM_HUB_1.value
        first, second = state & 0xFF, (state >> 8) & 0xFF
    end

    for _, row in ipairs(self.session.menu.rows) do
        row.assignedPortal = nil
        if row.disabled and not row.locked then
            local destinationID = row.destination.portalDestinationID
            if destinationID ~= nil and destinationID == maxGuild then
                row.assignedPortal = 3
            elseif destinationID ~= nil and destinationID == first then
                row.assignedPortal = 1
            elseif destinationID ~= nil and destinationID == second then
                row.assignedPortal = 2
            end
        end
    end
end

-- Portal availability is encoded by the sibling label's disabled colour.
-- Native input enabled flags do not describe which destinations are available.
function PvmPortalMenu:IsDisabled(row)
    -- The presentation hides native input artwork and collapses clipped hitboxes.
    -- Its visibleGlobal state is therefore not a native availability signal.
    return row.native.label.rgba == 0x8E8E8EFF
end

return PvmPortalMenu
