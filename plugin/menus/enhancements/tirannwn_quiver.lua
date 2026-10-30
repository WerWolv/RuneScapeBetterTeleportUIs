local AtelfTeleportsMenu = require("impl/interfaces/atelf_teleports_menu")
local textUtils = require("impl/text")
local componentUtils = require("impl/components")
local HotkeyBadge = require("impl/hotkey_badge")
local NativeLayout = require("impl/native_layout")
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
            session.hotkeys[#session.hotkeys + 1] = {
                button = button,
                badge = HotkeyBadge.New(button.parent, hotkey),
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

    session.deathLayout = NativeLayout.FromControls({ session.deathButton })

    local icon = ui.Sprite.new(session.deathButton.parent)
    session.deathDisabledIcon = icon
    icon.spriteID = id.Sprite.ELFCITY_ICON_TELEPORT_4_2
    icon.clickthrough = false
    icon.hidden = true

    local text = componentUtils.CenteredLabel(session.deathButton.parent, id.Font.MUSEO_SANS_13PT_BOLD)
    text:SetSize(51, 18)
    text.rgba = 0xFFFFFFC0

    session.chargesText = text
end

function TirannwnQuiver:UpdateVisuals()
    self:UpdateCharges()

    local session = self.session

    for _, hotkey in ipairs(session.hotkeys) do
        local button = hotkey.button
        local anchor = button

        if button == session.deathButton and session.deathDisabledIcon ~= nil
            and not session.deathDisabledIcon.hidden then
            anchor = session.deathDisabledIcon
        end

        hotkey.badge:Update(anchor, { disabled = button.enabled == false })
    end
end

function TirannwnQuiver:UpdateCharges()
    local session = self.session
    local text = session.chargesText
    if text == nil then return end

    session.deathLayout:Restore()

    local button = session.deathButton
    local source = (session.chargesSource.content or ""):gsub("<br%s*/?>", " ")
    source = textUtils.StripFormatting(source):lower()
    local count = source:match("death%s+altar%s+(%d+)%s+more%s+times?%s+today")
    local exhausted = tonumber(count) == 0
    local visible = button.visibleGlobal and count ~= nil
    local icon = session.deathDisabledIcon

    text.content = not exhausted and count or ""
    text.hidden = not visible or exhausted
    icon.hidden = not visible or not exhausted
    -- Replace recognized charge information with a count or the exhausted icon.
    session.chargesHolder.hidden = visible

    if exhausted then
        session.deathLayout:Apply(function()
            button.enabled = false
            -- Native actions can ignore enabled; remove the original hit target as well.
            button.hidden = true
        end)
    end

    if not visible then
        return
    end

    local position = button.xyGlobal
    local parentPosition = text.parent.xyGlobal

    if exhausted then
        icon:SetPos(position.x - parentPosition.x, position.y - parentPosition.y)
        icon:SetSize(button.width, button.height)
        icon:MoveToFront()
        return
    end

    -- Centre the count along the bottom of the button.
    text:SetPos(
        position.x - parentPosition.x + (button.width - 52) / 2,
        position.y - parentPosition.y + (button.height - 32) / 2
    )

    text:MoveToFront()
end

function TirannwnQuiver:ReleaseVisuals()
    if self.session ~= nil then
        if self.session.deathLayout ~= nil then
            self.session.deathLayout:Restore()
        end

        if self.session.deathDisabledIcon ~= nil then
            pcall(function()
                self.session.deathDisabledIcon:Destroy()
            end)
            self.session.deathDisabledIcon = nil
        end

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
