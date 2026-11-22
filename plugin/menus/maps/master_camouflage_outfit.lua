local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local resize = require("impl/utils").Resize

local MasterCamouflageOutfitPage1 = MapMenu.Create(ModalChoiceMenu, "masterCamouflageOutfitPage1")
local MasterCamouflageOutfitPage2 = MapMenu.Create(ModalChoiceMenu, "masterCamouflageOutfitPage2")

local function clan(buttonID, name, level, icons, x, y, hotkeyX)
    return {
        id = buttonID,
        nameOverride = name,
        description = descriptions.LevelRequirement(level, descriptions.SKILL.THIEVING),
        point = { x = x, y = y },
        icons = resize(icons, 64),
        hotkeyOffset = { x = hotkeyX or 24, y = -24 },
    }
end

function MasterCamouflageOutfitPage1:Define()
    return {
        title = "Prifddinas Thieving",
        background = backgrounds.prifddinas,
        noBackgroundCrop = true,
        entries = {
            ["1. Iorwerth (level 91)"] = clan("iorwerth", "Iorwerth", 91, teleportIcons.elfClans.iorwerth, 254, 123),
            ["2. Ithell (level 92)"] = clan("ithell", "Ithell", 92, teleportIcons.elfClans.ithell, 230, 99),
            ["3. Cadarn (level 93)"] = clan("cadarn", "Cadarn", 93, teleportIcons.elfClans.cadarn, 314, 99),
            ["4. Amlodd (level 94)"] = clan("amlodd", "Amlodd", 94, teleportIcons.elfClans.amlodd, 230, 63, 20),
            ["5. Trahaearn (level 95)"] = clan("trahaearn", "Trahaearn", 95, teleportIcons.elfClans.trahaearn, 290, 123, 16),
            ["6. Hefin (level 96)"] = clan("hefin", "Hefin", 96, teleportIcons.elfClans.hefin, 254, 39),
            ["7. Crwys (level 97)"] = clan("crwys", "Crwys", 97, teleportIcons.elfClans.crwys, 314, 63),
            ["8. Meilyr (level 98)"] = clan("meilyr", "Meilyr", 98, teleportIcons.elfClans.meilyr, 290, 39),

            -- Why is this in here and not Lletya??
            ["9. Pyramid Plunder"] = {
                id = "pyramidpain",
                description = descriptions.Location("Jalsavrah, Sophanem"),
                point = { x = 272, y = 80 },
                icons = { objectID = id.Obj.NTK_JEWELLED_SCEPTRE_6, size = 40 },
            },
            ["0. [More options]"] = {
                id = "next",
                nameOverride = "Next",
                anchor = "bottomRight",
                icons = teleportIcons.nextArrow,
            },
        },
    }
end

function MasterCamouflageOutfitPage2:Define()
    return {
        title = "Thieving Teleports",
        background = backgrounds.runescapeSurface,
        noBackgroundCrop = true,
        sizeMultiplier = 1.25,
        icons = teleportIcons.skills.thieving,
        entries = {
            ["1. The Consortium"] = {
                id = "consortium",
                description = descriptions.Location("Keldagrim"),
                point = { x = 204, y = 29 },
            },
            ["2. Lletya"] = {
                id = "lletya",
                description = descriptions.Location("Tirannwn"),
                point = { x = 90, y = 187 },
            },
            ["3. Thieving Guild"] = {
                id = "thievingguild",
                description = descriptions.Location("North of Lumbridge"),
                point = { x = 346, y = 167 },
            },
            ["4. Pollnivneach"] = {
                id = "pollnivneach",
                description = descriptions.Location("Kharidian Desert"),
                point = { x = 374, y = 234 },
            },
            ["5. Cancel"] = { hidden = true },
            ["6. [More options]"] = {
                id = "back",
                nameOverride = "Back",
                anchor = "bottomLeft",
                icons = teleportIcons.prevArrow,
            },
        },
    }
end

return { MasterCamouflageOutfitPage1, MasterCamouflageOutfitPage2 }
