local SplitLayerMenu = require("impl/interfaces/native/split_layer_menu")

local MaxGuildPortalMenu = SplitLayerMenu:Extend()
MaxGuildPortalMenu.interface = MaxGuildPortalMenu
MaxGuildPortalMenu.cacheNativeSnapshot = true
MaxGuildPortalMenu.blockDisabledClicks = true
MaxGuildPortalMenu.interfaceName = "ELF_PVM_PORTAL_CHOOSE_TASK (" .. id.Interface.ELF_PVM_PORTAL_CHOOSE_TASK .. ")"
MaxGuildPortalMenu.nativeInterface = {
    trackedLayout = true,
    id = id.Interface.ELF_PVM_PORTAL_CHOOSE_TASK,
    prefix = "ELF_PVM_PORTAL_CHOOSE_TASK__",
    window = "MAINMODAL_WINDOW",
    content = "MAINMODAL_WINDOW_CONTENT",
    titleParent = "MAINMODAL_WINDOW_BORDER",
    close = "MAINMODAL_WINDOW_CLOSE_BUTTON",
    frame = { "MAINMODAL_WINDOW_BACKGROUND", "MAINMODAL_WINDOW_BORDER" },
    lastStaticID = 8,
    controls = "CLICK_LAYER",
    build = "BUILD_LAYER",
    artworkStride = 11,
    labelOffset = 9,
    hide = { "SCROLLBAR_LAYER" },
}

-- The skill-portal variables store the keys of this enum, not visible row indices.
function MaxGuildPortalMenu:ConfigureDestinations(entries)
    for _, pair in ipairs(config.Enum.ELF_MAX_SKILL_PORTAL_NAMES.values) do
        local entry = entries[pair[2]]
        if entry ~= nil then
            entry.portalDestinationID = pair[1]
        end
    end
end

function MaxGuildPortalMenu:RefreshAvailability(snapshot)
    SplitLayerMenu.RefreshAvailability(self, snapshot)
    local first = var.VarPlayer.ELFCITY_MAX_GUILD_SKILL_PORTAL_A.value
    local second = var.VarPlayer.ELFCITY_MAX_GUILD_SKILL_PORTAL_B.value

    for _, row in ipairs(self.session.menu.rows) do
        local destinationID = row.destination.portalDestinationID
        local assignment = 0
        if destinationID ~= nil and not row.locked then
            if destinationID == first then assignment = assignment | 1 end
            if destinationID == second then assignment = assignment | 2 end
        end
        row.assignedPortal = assignment ~= 0 and assignment or nil
    end
end

-- The shared native button template expresses availability through its label.
function MaxGuildPortalMenu:IsDisabled(row)
    return row.native.label.rgba == 0x8E8E8EFF
end

return MaxGuildPortalMenu
