local AtelfTeleportsMenu = require("impl/interfaces/atelf_teleports_menu")
local textUtils = require("impl/text")
local componentUtils = require("impl/components")
local userSettings = require("impl/settings")
local TirannwnQuiver = AtelfTeleportsMenu:Extend("tirannwnQuiver")

-- Native shortcut order differs from the component order in the interface.
local hotkeyButtons = {
    id.Component.ATELF_TELEPORTS__ELFCITY_TELE_LLETYA,
    id.Component.ATELF_TELEPORTS__ELFCITY_TELE_ELUNED,
    id.Component.ATELF_TELEPORTS__ELFCITY_TELE_TYRAS,
    id.Component.ATELF_TELEPORTS__ELFCITY_TELE_POISON,
    id.Component.ATELF_TELEPORTS__ELFCITY_TELE_DEATH,
    id.Component.ATELF_TELEPORTS__ELFCITY_TELE_ELFCAMP,
    id.Component.ATELF_TELEPORTS__ELFCITY_TELE_MUSHROOM,
    id.Component.ATELF_TELEPORTS__ELFCITY_TELE_RESOURCE,
}

function TirannwnQuiver:Define()
    return {
        entries = {
            ELFCITY_TELE_ELUNED = {},
            INFO_HOLDER_CHARGES = { hidden = true }
        },
    }
end

function TirannwnQuiver:CalculateLayout()
    local progress = config.Quest.SEREN.masterQuestVars[1]
    if progress.varPlayer.value >= progress.endState then
        return {
            ELFCITY_TELE_ELUNED = { x = 230, y = 80 }
        }
    end

    return {}
end

function TirannwnQuiver:BeginVisuals()
    local components = ui.Interfaces
    local session = self.session

    session.hotkeys = {}

    for hotkey, componentID in ipairs(hotkeyButtons) do
        local button = components:GetComponent(componentID)
        if button ~= nil then
            local badge, label = componentUtils.HotkeyBadge(button.parent)
            label.content = tostring(hotkey)
            badge.hidden = true

            session.hotkeys[#session.hotkeys + 1] = {
                button = button,
                badge = badge,
                label = label,
            }
        end
    end

    session.chargesHolder = components:GetComponent(
        id.Component.ATELF_TELEPORTS__INFO_HOLDER_CHARGES
    )
    session.chargesSource = components:GetComponent(
        id.Component.ATELF_TELEPORTS__ELFCITY_TELE_CHARGES
    )
    session.deathButton = components:GetComponent(
        id.Component.ATELF_TELEPORTS__ELFCITY_TELE_DEATH
    )

    if session.chargesHolder == nil
        or session.chargesSource == nil
        or session.deathButton == nil then
        return
    end

    local text = componentUtils.CenteredLabel(session.deathButton.parent, id.Font.MUSEO_SANS_13PT_BOLD)
    text:SetSize(51, 18)
    text.rgba = 0xFFFFFFC0

    session.chargesText = text
end

function TirannwnQuiver:UpdateVisuals()
    local session = self.session
    local showHotkeys = userSettings.Get("showTeleportHotkeys")

    for _, hotkey in ipairs(session.hotkeys) do
        local button = hotkey.button
        local badge = hotkey.badge
        badge.hidden = not showHotkeys or not button.visibleGlobal

        if not badge.hidden then
            local position = button.xyGlobal
            local parentPosition = badge.parent.xyGlobal
            local disabled = button.enabled == false

            badge:SetPos(
                position.x - parentPosition.x + button.width - badge.width / 2,
                position.y - parentPosition.y - badge.height / 2
            )
            badge.alpha = disabled and 0.6 or 1
            hotkey.label.rgba = disabled and 0x9D978AFF or 0xFFE3A3FF
            badge:MoveToFront()
        end
    end

    local text = session.chargesText
    if text == nil then return end

    local button = session.deathButton
    local source = (session.chargesSource.content or ""):gsub("<br%s*/?>", " ")
    source = textUtils.StripFormatting(source):lower()
    local count = source:match("death%s+altar%s+(%d+)%s+more%s+times?%s+today")
    text.content = count or ""
    text.hidden = not button.visibleGlobal or count == nil
    -- Only replace the native text when a visible charge counter is available.
    session.chargesHolder.hidden = not text.hidden
    if text.hidden then return end

    local position = button.xyGlobal
    local parentPosition = text.parent.xyGlobal

    -- Centre the count along the bottom of the button.
    text:SetPos(
        position.x - parentPosition.x + (button.width - 52) / 2,
        position.y - parentPosition.y + (button.height - 32) / 2
    )

    text:MoveToFront()
end

function TirannwnQuiver:ReleaseVisuals()
    if self.session ~= nil then
        for _, hotkey in ipairs(self.session.hotkeys or {}) do
            pcall(function()
                hotkey.badge:Destroy()
            end)
        end

        self.session.hotkeys = nil
    end

    local text = self.session and self.session.chargesText
    if text ~= nil then
        pcall(function() text:Destroy() end)
        self.session.chargesText = nil
    end
end

return TirannwnQuiver
