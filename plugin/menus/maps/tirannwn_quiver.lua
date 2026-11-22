local AtelfTeleportsMenu = require("impl/interfaces/native/atelf_teleports_menu")
local textUtils = require("impl/text")
local componentUtils = require("impl/ui/components")
local HotkeyBadge = require("impl/ui/hotkey_badge")
local NativeLayout = require("impl/interfaces/native/native_layout")
local cleanup = require("impl/cleanup")
local settings = require("impl/settings")
local TargetHighlight = require("impl/ui/target_highlight")
local TirannwnQuiver = AtelfTeleportsMenu:Extend("tirannwnQuiver")

function TirannwnQuiver:Define()
    return {
        entries = {
            ELFCITY_TELE_LLETYA = { id = "lletya", nameOverride = "Lletya" },
            ELFCITY_TELE_ELUNED = { id = "islwyn", nameOverride = "Islwyn" },
            ELFCITY_TELE_TYRAS = { id = "tyras", nameOverride = "Tyras Camp" },
            ELFCITY_TELE_POISON = { id = "poisonwaste", nameOverride = "Poison Waste" },
            ELFCITY_TELE_DEATH = { id = "deathaltar", nameOverride = "Death Altar" },
            ELFCITY_TELE_ELFCAMP = { id = "elfcamp", nameOverride = "Elf Camp" },
            ELFCITY_TELE_MUSHROOM = { id = "mushroompatch", nameOverride = "Mushroom Patch" },
            ELFCITY_TELE_RESOURCE = { id = "harmonypillars", nameOverride = "Harmony Pillars" },
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
    local parents = {}

    -- Native parent getters can return fresh handles for the same component.
    -- Reuse one handle per parent so all decorations share PrettyUI's allocator state.
    local function parentOf(control)
        local parent = control.parent
        local key = componentUtils.Key(parent)
        parents[key] = parents[key] or parent
        return parents[key]
    end

    session.hotkeys = {}

    for hotkey, name in ipairs(self.buttons) do
        local button = components:GetComponent(id.Component["ATELF_TELEPORTS__" .. name])
        if button ~= nil then
            session.hotkeys[#session.hotkeys + 1] = {
                button = button,
                badge = HotkeyBadge.New(parentOf(button), hotkey),
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

    session.deathLayout = NativeLayout.FromControls({ session.deathButton, session.chargesHolder })

    local parent = parentOf(session.deathButton)
    local icon = prettyui.NewComponent(ui.Sprite, parent, { categoryID = "auto" })
    session.deathDisabledIcon = icon
    icon.spriteID = id.Sprite.ELFCITY_ICON_TELEPORT_4_2
    icon.clickthrough = false
    icon.hidden = true

    local text = componentUtils.CenteredLabel(parent, id.Font.MUSEO_SANS_13PT_BOLD)
    text:SetSize(51, 18)
    text.rgba = 0xFFFFFFC0
    text.hidden = true

    session.chargesText = text
end

function TirannwnQuiver:UpdateVisuals()
    self:UpdateCharges()

    local session = self.session

    for _, hotkey in ipairs(session.hotkeys) do
        local button = hotkey.button
        local anchor = button
        local exhausted = button == session.deathButton and session.deathDisabledIcon ~= nil
            and not session.deathDisabledIcon.hidden

        if exhausted then
            anchor = session.deathDisabledIcon
        end

        -- Native icon enabled flags do not describe teleport availability.
        hotkey.badge:Update(anchor, { disabled = exhausted })
    end
end

function TirannwnQuiver:UpdateCharges()
    local session = self.session
    local text = session.chargesText
    if text == nil then
        return
    end

    session.deathLayout:Restore()

    local icon = session.deathDisabledIcon
    if not settings.Get("showTirannwnQuiverChargesOnGem") then
        text.hidden = true
        icon.hidden = true
        return
    end

    local button = session.deathButton
    local source = (session.chargesSource.content or ""):gsub("<br%s*/?>", " ")
    source = textUtils.StripFormatting(source):lower()
    local count = source:match("death%s+altar%s+(%d+)%s+more%s+times?%s+today")
    local exhausted = tonumber(count) == 0
    local visible = button.visibleGlobal and count ~= nil

    text.content = not exhausted and count or ""
    text.hidden = not visible or exhausted
    icon.hidden = not visible or not exhausted
    -- Replace recognized charge information with a count or the exhausted icon.
    session.deathLayout:Apply(function()
        if visible then
            session.chargesHolder.hidden = true
        end

        if exhausted then
            button.enabled = false
            -- Native actions can ignore enabled; remove the original hit target as well.
            button.hidden = true
        end
    end)

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

function TirannwnQuiver:BeginHighlight(key)
    local row, reason = self:FindHighlightTarget(key)
    if row == nil then
        return nil, reason
    end
    return { row = row, parent = row.click.parent }
end

function TirannwnQuiver:UpdateHighlight(state)
    local button = state.row.click
    if button == self.session.deathButton and self.session.deathDisabledIcon ~= nil
        and not self.session.deathDisabledIcon.hidden then
        button = self.session.deathDisabledIcon
    end
    TargetHighlight.Update(state, state.parent, button.width, button.height, true)
    local root = state.highlightVisual.root
    local position, parentPosition = button.xyGlobal, state.parent.xyGlobal
    root:SetPos(position.x - parentPosition.x, position.y - parentPosition.y)
    root.hidden = not button.visibleGlobal
end

function TirannwnQuiver:ReleaseVisuals()
    if self.session ~= nil then
        cleanup.Release(self.session, "deathLayout", "Restore")
        cleanup.Release(self.session, "deathDisabledIcon")

        for _, hotkey in ipairs(self.session.hotkeys or {}) do
            cleanup.Release(hotkey, "badge")
        end

        self.session.hotkeys = nil
    end

    if self.session ~= nil then
        cleanup.Release(self.session, "chargesText")
    end
end

return TirannwnQuiver
