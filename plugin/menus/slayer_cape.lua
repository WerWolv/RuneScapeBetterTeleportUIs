local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local SlayerCapePage1 = ModalChoiceMenu:Extend("slayerCapePage1")
local SlayerCapePage2 = ModalChoiceMenu:Extend("slayerCapePage2")

function SlayerCapePage1:Define()
    return {
        title = "Slayer Masters",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.slayerMaster,
        entries = {
            ["1. Mandrith"] = {
                point = {x = 297, y = 23},
            },
            ["2. Laniakea"] = {
                point = {x = 535, y = 25},
            },
            ["3. Morvran"] = {
                point = {x = 47, y = 117},
            },
            ["4. Kuradal"] = {
                point = {x = 141, y = 83},
            },
            ["5. Lapalok"] = {
                point = {x = 244, y = 230},
            },
            ["5. Duradel"] = {
                point = {x = 244, y = 230},
            },
            ["6. Sumona"] = {
                point = {x = 379, y = 235},
            },
            ["7. Chaeldar"] = {
                point = {x = 338, y = 181},
            },
            ["8. Mazchna"] = {
                point = {x = 425, y = 83},
            },
            ["9. The Raptor"] = {
                point = {x = 370, y = 74},
            },
            ["0. Next page"] = {
                nameOverride = "Next",
                icons = teleportIcons.nextArrow,
                point = {x = 560 - 24, y = 290},
            },
            ["X. Previous page"] = {
                nameOverride = "Previous",
                icons = teleportIcons.prevArrow,
                point = {x = 24, y = 290 },
                possiblyMissing = true,
            }
        },
    }
end

-- Define ring of duelling destinations and its hidden cancel option.
function SlayerCapePage2:Define()
    return {
        title = "Slayer Masters",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.slayerMaster,
        entries = {
            ["1. Vannaka"] = {
                point = {x = 302, y = 87},
            },
            ["2. Jacquelyn"] = {
                point = {x = 338, y = 172},
            },
            ["3. Spria"] = {
                point = {x = 252, y = 73},
            },
            ["3. Turael"] = {
                point = {x = 252, y = 73},
            },
            ["4. Previous page"] = {
                nameOverride = "Previous",
                icons = teleportIcons.prevArrow,
                point = {x = 24, y = 290 },
            },
            ["X. Next page"] = {
                nameOverride = "Next",
                icons = teleportIcons.nextArrow,
                point = {x = 560 - 24, y = 290},
                possiblyMissing = true,
            }
        },
    }
end

return { SlayerCapePage1, SlayerCapePage2 }
