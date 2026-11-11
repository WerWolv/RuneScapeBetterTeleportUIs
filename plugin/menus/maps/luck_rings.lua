local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local LuckRings = MapMenu.Create(ModalChoiceMenu, "luckRings")

function LuckRings:Match(snapshot)
    local match, reason = ModalChoiceMenu.Match(self, snapshot)

    if match == nil then
        return nil, reason
    end

    for _, row in ipairs(match.rows) do
        if not row.locked then
            if row.entryKey == "4. Hazelmere's Statue" then
                match.title = "Hazelmere's Signet Ring"
                return match
            elseif row.entryKey == "3. Keldagrim" then
                match.title = "Luck of the Dwarves"
            else
                -- Technically, it could also be a Ring of Luck but these two share the same teleports
                match.title = "Ring of Fortune"
            end
        end
    end

    return match
end

function LuckRings:Define()
    return {
        -- Wealth and Fortune offer the same pair of destinations.
        title = "Luck Ring",
        background = backgrounds.runescapeSurface,
        entries = {
            ["1. Miscellania"] = {
                icons = teleportIcons.jewellery.darkGoldOnyx,
                point = {x = 113, y = 17},
            },
            ["2. Grand Exchange"] = {
                icons = teleportIcons.jewellery.darkGoldOnyx,
                point = {x = 329, y = 93},
            },
            ["3. Keldagrim"] = {
                icons = teleportIcons.jewellery.goldOnyx,
                point = {x = 204, y = 29},
                possiblyMissing = true
            },
            ["4. Hazelmere's Statue"] = {
                icons = teleportIcons.jewellery.goldDiamond,
                point = {x = 120, y = 115},
                possiblyMissing = true
            },
            ["^%d%. Dwarven Outpost$"] = {
                icons = teleportIcons.jewellery.goldOnyx,
                point = {x = 154, y = 96},
                possiblyMissing = true
            },
            ["^%d%. Nowhere$"] = {hidden = true},
        },
    }
end

return LuckRings
