local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local ArchaeologyOutfit = MapMenu.Create(ModalChoiceMenu, "archaeologyOutfit")
local ArchaeologyCollectorsPage1 = MapMenu.Create(ModalChoiceMenu, "archaeologyCollectorsPage1")
local ArchaeologyCollectorsPage2 = MapMenu.Create(ModalChoiceMenu, "archaeologyCollectorsPage2")
local collectorNextArrow = require("impl/utils").DeepCopy(teleportIcons.nextArrow)
collectorNextArrow.hoveredSize = collectorNextArrow.size

-- Collection names: https://runescape.wiki/w/Template:Archaeology_collection_summary
local function collections(...)
    return "- " .. table.concat({...}, "<br>- ") .. "<br>"
end

function ArchaeologyOutfit:Define()
    return {
        title = "Archaeological Dig Sites",
        background = backgrounds.runescapeSurfaceFull,
        noBackgroundCrop = true,
        showTeleportNames = false,
        sizeMultiplier = 1.2,
        entries = {
            ["1. Archaeology Campus"] = {
                id = "campus",
                icons = teleportIcons.digsite.guild,
                point = {x = 379, y = 128},
            },
            ["2. Kharid-et"] = {
                id = "kharidet",
                icons = teleportIcons.digsite.kharidEt,
                point = {x = 385, y = 165},
            },
            ["3. Infernal Source"] = {
                id = "infernal",
                icons = teleportIcons.digsite.infernalSource,
                point = {x = 355, y = 78},
            },
            ["4. Everlight"] = {
                id = "everlight",
                icons = teleportIcons.digsite.everlight,
                point = {x = 490, y = 165},
            },
            ["5. Moonrise"] = {
                id = "moonrise",
                icons = teleportIcons.digsite.moonrise,
                point = {x = 605, y = 85},
            },
            ["6. Senntisten"] = {
                id = "senntisten",
                icons = teleportIcons.digsite.senntisten,
                point = {x = 390, y = 90},
            },
            ["7. Stormguard Citadel"] = {
                id = "stormguard",
                icons = teleportIcons.digsite.stormguard,
                point = {x = 190, y = 110},
            },
            ["8. Daemonheim"] = {
                id = "daemonheim",
                icons = teleportIcons.digsite.daemonheim,
                point = {x = 410, y = 30},
            },
            ["9. Warforge"] = {
                id = "warforge",
                icons = teleportIcons.digsite.warforge,
                point = {x = 112, y = 276},
            },
            ["0. Orthen"] = {
                id = "orthen",
                icons = teleportIcons.digsite.orthen,
                point = {x = 510, y = 24},
            }
        },
    }
end

function ArchaeologyCollectorsPage1:Define()
    return {
        title = "Archaeology Collectors",
        background = backgrounds.runescapeSurfaceFull,
        sizeMultiplier = 1.25,
        entries = {
            ["1. Art Critic Jacques"] = {
                id = "jacques",
                icons = teleportIcons.digsite.guild,
                description = collections(
                    "Anarchic Abstraction",
                    "Radiant Renaissance",
                    "Imperial Impressionism"
                ),
                point = {x = 361, y = 92},
            },
            ["2. Artiefax"] = {
                id = "artiefax",
                icons = teleportIcons.digsite.moonrise,
                description = collections("Guthixian I", "Guthixian II"),
                point = {x = 252, y = 77},
            },
            ["3. Chief Tess"] = {
                id = "tess",
                icons = teleportIcons.digsite.guild,
                description = collections("Blingy Fings", "Smoky Fings", "Hitty Fings", "Showy Fings"),
                point = {x = 166, y = 273},
            },
            ["4. Generals Bentnoze & Wartface"] = {
                id = "generals",
                icons = teleportIcons.digsite.warforge,
                description = "General Bentnoze<br>" .. collections(
                    "Red Rum Relics I", "Red Rum Relics II", "Red Rum Relics III"
                ) .. "<br>General Wartface<br>" .. collections(
                    "Green Gobbo Goodies I", "Green Gobbo Goodies II", "Green Gobbo Goodies III"
                ),
                point = {x = 280, y = 70},
            },
            ["5. Isaura"] = {
                id = "isaura",
                icons = teleportIcons.digsite.infernalSource,
                description = collections("Zamorakian I", "Zamorakian II", "Zamorakian III", "Zamorakian IV"),
                point = {x = 242, y = 123},
            },
            ["6. Lowse"] = {
                id = "lowse",
                icons = teleportIcons.digsite.stormguard,
                description = collections("Armadylean I", "Armadylean II", "Armadylean III"),
                point = {x = 265, y = 165},
            },
            ["7. Sharrigan"] = {
                id = "sharrigan",
                icons = teleportIcons.digsite.orthen,
                description = collections(
                    "Dragonkin I", "Dragonkin II", "Dragonkin III", "Dragonkin IV",
                    "Dragonkin V", "Dragonkin VI", "Dragonkin VII"
                ),
                point = {x = 510, y = 24},
            },
            ["8. Sir Atcha"] = {
                id = "atcha",
                icons = teleportIcons.digsite.everlight,
                description = collections("Saradominist I", "Saradominist II", "Saradominist III", "Saradominist IV"),
                point = {x = 278, y = 132},
            },
            ["9. Soran (Emissary of Zaros)"] = {
                id = "soran",
                icons = teleportIcons.digsite.kharidEt,
                description = collections("Zarosian I", "Zarosian II", "Zarosian III", "Zarosian IV"),
                point = {x = 335, y = 105},
            },
            ["0. More options"] = {
                id = "next",
                nameOverride = "Next",
                anchor = "bottomRight",
                icons = collectorNextArrow,
            },
        },
    }
end

function ArchaeologyCollectorsPage2:Define()
    return {
        title = "Archaeology Collectors",
        background = backgrounds.runescapeSurfaceFull,
        sizeMultiplier = 1.5,
        entries = {
            ["1. Velucia"] = {
                id = "velucia",
                icons = teleportIcons.digsite.guild,
                description = collections(
                    "Museum - Training Weapons",
                    "Museum - Armadylean I",
                    "Museum - Armadylean II",
                    "Museum - Armadylean III",
                    "Museum - Bandosian I",
                    "Museum - Bandosian II",
                    "Museum - Bandosian III",
                    "Museum - Dragonkin I",
                    "Museum - Dragonkin II",
                    "Museum - Dragonkin III",
                    "Museum - Dragonkin IV",
                    "Museum - Dragonkin V",
                    "Museum - Dragonkin VI",
                    "Museum - Dragonkin VII",
                    "Museum - Guthixian I",
                    "Museum - Guthixian II",
                    "Museum - Saradominist I",
                    "Museum - Saradominist II",
                    "Museum - Saradominist III",
                    "Museum - Saradominist IV",
                    "Museum - Zamorakian I",
                    "Museum - Zamorakian II",
                    "Museum - Zamorakian III",
                    "Museum - Zamorakian IV",
                    "Museum - Zarosian I",
                    "Museum - Zarosian II",
                    "Museum - Zarosian III",
                    "Museum - Zarosian IV",
                    "Museum - Zarosian V",
                    "Museum - Zarosian VI",
                    "Museum - Zarosian VII"
                ),
                point = {x = 379, y = 128},
            },
            ["2. Wise Old Man"] = {
                id = "wiseoldman",
                icons = teleportIcons.digsite.guild,
                description = collections(
                    "Wise Am the Music Man",
                    "Hat Problem",
                    "Hat Hoarder",
                    "Magic Man",
                    "Knowledge is Power"
                ),
                point = {x = 308, y = 151},
            },
            ["3. Eblis"] = {
                id = "eblis",
                icons = teleportIcons.digsite.kharidEt,
                description = collections(
                    "Finery of the Inquisition",
                    "Entertaining the Masses",
                    "Religious Iconography",
                    "Urns of the Empire",
                    "Imperial Sorcery"
                ),
                point = {x = 350, y = 224},
            },
        },
    }
end

return { ArchaeologyOutfit, ArchaeologyCollectorsPage1, ArchaeologyCollectorsPage2 }
