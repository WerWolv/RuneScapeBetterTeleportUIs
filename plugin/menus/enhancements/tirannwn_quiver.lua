local AtelfTeleportsMenu = require("impl/interfaces/atelf_teleports_menu")
local textUtils = require("impl/text")
local componentUtils = require("impl/components")
local TirannwnQuiver = AtelfTeleportsMenu:Extend("tirannwnQuiver")

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
    local text = session.chargesText
    if text == nil then return end

    session.chargesHolder.hidden = true

    local button = session.deathButton
    local position = button.xyGlobal
    local parentPosition = text.parent.xyGlobal

    -- Centre the count along the bottom of the button.
    text:SetPos(
        position.x - parentPosition.x + (button.width - 52) / 2,
        position.y - parentPosition.y + (button.height - 32) / 2
    )

    local source = textUtils.StripFormatting(session.chargesSource.content)
    local count = source:match("Death Altar%s+(%d+)%s+more times today%.")
    text.content = count or ""
    text.hidden = not button.visibleGlobal or count == nil
    text:MoveToFront()
end

function TirannwnQuiver:ReleaseVisuals()
    local text = self.session and self.session.chargesText
    if text ~= nil then
        pcall(function() text:Destroy() end)
        self.session.chargesText = nil
    end
end

return TirannwnQuiver
