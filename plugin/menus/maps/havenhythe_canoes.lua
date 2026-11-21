local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local utils = require("impl/utils")
local HavenhytheCanoes = MapMenu.Create(ModalChoiceMenu, "havenhytheCanoes")

local function canoe(yaw)
    local icons = utils.DeepCopy(teleportIcons.canoe)
    icons.camera.yaw = yaw
    return icons
end

function HavenhytheCanoes:Define()
    return {
        title = "Havenhythe Canoe Stations",
        background = backgrounds.havenhythe,
        sizeMultiplier = 1.25,
        icons = teleportIcons.canoe,
        entries = {
            ["1. Wendlewick (Burnt Lobster Tavern)"] = {
                nameOverride = "Wendlewick",
                icons = canoe(90),
                point = {x = 165, y = 447},
            },
            ["2. Wendlewick (Farm)"] = {
                nameOverride = "Blighted Cave",
                icons = canoe(150),
                point = {x = 371, y = 378},
            },
            ["3. Wendlewick (Grotto)"] = {
                nameOverride = "Grotto",
                icons = canoe(45),
                point = {x = 309, y = 632},
            },
            ["4. Amberfell"] = {
                icons = canoe(270),
                point = {x = 510, y = 353},
            },
            ["5. Heathervein"] = {
                icons = canoe(180),
                point = {x = 677, y = 280},
            },
            ["6. Linbog"] = {
                icons = canoe(315),
                point = {x = 661, y = 462},
            },
        },
    }
end

function HavenhytheCanoes:RefreshAvailability(snapshot)
    ModalChoiceMenu.RefreshAvailability(self, snapshot)
    for _, row in ipairs(self.session.menu.rows) do
        row.destination.hidden = row.disabled
    end
end

return HavenhytheCanoes
