local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local ModelSlotMenu = require("impl/interfaces/presentations/model_slot_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")

local teleportIcons = require("definitions/teleport_icons")
local backgrounds = require("definitions/backgrounds")
local TeleportCounter = require("impl/ui/teleport_counter")
local cleanup = require("impl/cleanup")

local EliteWoodcuttingOutfitMainPage1 = ModelSlotMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitMainPage1")
local EliteWoodcuttingOutfitMainPage2 = ModelSlotMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitMainPage2")

local EliteWoodcuttingOutfitEternalMagicTrees = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitEternalMagicTrees")
local EliteWoodcuttingOutfitElderPage1 = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitElderPage1")
local EliteWoodcuttingOutfitElderPage2 = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitElderPage2")
local EliteWoodcuttingOutfitIdols = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitIdols")
local EliteWoodcuttingOutfitMagic = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitMagic")
local EliteWoodcuttingOutfitYew = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitYew")
local EliteWoodcuttingOutfitChokingIvy = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitChokingIvy")
local EliteWoodcuttingOutfitCreepingIvy = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitCreepingIvy")
local EliteWoodcuttingOutfitMahogany = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitMahogany")
local EliteWoodcuttingOutfitAcadia = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitAcadia")
local EliteWoodcuttingOutfitMaple = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitMaple")
local EliteWoodcuttingOutfitTeak = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitTeak")
local EliteWoodcuttingOutfitWillow = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitWillow")
local EliteWoodcuttingOutfitOakNormal = MapMenu.Create(ModalChoiceMenu, "eliteWoodcuttingOutfitOakNormal")

-- For testing: TRH113_ELITE_WOODCUTTING_DAILY_TELEPORTS VarPlayer contains the remaining teleport count

local function tree(locIDs, name, submenu, distance, x, y)
    local models, animation = {}, nil
    for index, locID in ipairs(type(locIDs) == "table" and locIDs or { locIDs }) do
        local loc = config.Loc.FromID(locID)
        local parts = loc:GetModelIDs(LocShapeType.CENTREPIECE_STRAIGHT)
        if #parts == 0 then
            -- Choking ivy is wall decoration rather than a centrepiece.
            for _, shape in ipairs(loc.locShapeTypes) do
                parts = loc:GetModelIDs(shape)
                if #parts > 0 then break end
            end
        end
        assert(#parts > 0, "No tree models for " .. loc.configName)
        for _, modelID in ipairs(parts) do
            models[#models + 1] = modelID
        end
        if index == 1 and loc.defaultAnimation ~= nil then
            animation = loc.defaultAnimation.id
        end
    end
    return {
        nameOverride = name .. (submenu and "  <sprite=36157>" or ""),
        modelIDs = models,
        animID = animation,
        viewDistance = distance,
        modelOffset = { x = x, y = y },
    }
end

-- Separate model widgets paint in order; inner geometry must precede its outer shell.
local function innerModelFirst(entry, modelID)
    for index, part in ipairs(entry.modelIDs) do
        if part == modelID then
            table.insert(entry.modelIDs, 1, table.remove(entry.modelIDs, index))
            break
        end
    end
    return entry
end

function EliteWoodcuttingOutfitMainPage1:Define()
    return {
        title = "Tree Types",
        showTitle = false,
        overlayLabels = true,
        rightInset = 6,
        labelStyle = {
            font = id.Font.NOTOSANS_SEMIBOLD_11,
            backgroundRGBA = 0x140F0AA0,
            inset = 6, paddingX = 4, paddingY = 2,
        },
        sizeMultiplier = 1.75,
        entries = {
            ["1. Eternal Magic Trees"] = innerModelFirst(
                tree(id.Loc.ETERNAL_TREE_TRUNK, "Eternal", true, 6000, 0, 80),
                id.Model.VEGETATION_TREE_ETERNAL_MAGIC_CORE
            ),
            ["2. Elder Trees"] = tree(id.Loc.ELDER_TREE, "Elder", true, 2000, 0, 70),
            ["3. Overgrown Idols"] = tree(id.Loc.IDOLS_STONE_IDOL, "Idols", true, 1000, 0, 50),
            ["4. Magic Trees"] = tree({
                id.Loc.FFH_MAGIC_TREE_TRUNK, id.Loc.FFH_MAGIC_TREE_CANOPY,
            }, "Magic", true, 3300, -10, 60),
            ["5. Yew Trees"] = tree({
                id.Loc.FFH_YEW_TREE_TRUNK_VAR0, id.Loc.FFH_YEW_TREE_CANOPY_VAR0,
            }, "Yew", true, 3000, 0, 70),
            ["6. Choking Ivy"] = tree(id.Loc.TUT5_2013_IVY_3X1_BUILDING_1A, "Choking Ivy", true, 2000, -10, 50),
            ["7. Creeping Ivy"] = tree(
                id.Loc.MYQ6_CASTLE_DRAKAN_COURTYARD_EXTERIOR_WALLS_IVY1, "Creeping Ivy", true, 1900, 10, 60
            ),
            ["8. Active Crystal Tree"] = tree({
                id.Loc.CRYSTAL_TREE_BASE, id.Loc.CRYSTAL_TREE_BRANCHES,
            }, "Crystal Tree", false, 2500, 0, 60),
            ["9. Active Evil Tree"] = tree(id.Loc.EVILTREE_NORMAL, "Evil Tree", false, 2000, 0, 70),
            ["0. [More options]"] = {
                anchor = "bottomRight",
                nameOverride = "Next",
                icons = teleportIcons.nextArrow,
            },
        },
    }
end

function EliteWoodcuttingOutfitMainPage2:Define()
    return {
        title = "Tree Types",
        showTitle = false,
        overlayLabels = true,
        rightInset = 6,
        labelStyle = {
            font = id.Font.NOTOSANS_SEMIBOLD_11,
            backgroundRGBA = 0x140F0AA0,
            inset = 6, paddingX = 4, paddingY = 2,
        },
        sizeMultiplier = 1.75,
        entries = {
            ["1. Arctic Pine Trees"] = tree({
                id.Loc.FFH_ARCTIC_PINE_TREE_TRUNK, id.Loc.FFH_ARCTIC_PINE_TREE_CANOPY,
            }, "Arctic Pines", false, 2800, 0, 70),
            ["2. Mahogany Trees"] = tree({
                id.Loc.FFH_MAHOGANY_TREE_TRUNK, id.Loc.FFH_MAHOGANY_TREE_CANOPY,
            }, "Mahogany", true, 3000, 0, 70),
            ["3. Acadia Trees"] = tree(id.Loc.MENAPHOS_ACACIA_TREE, "Acadia", true, 2500, 10, 60),
            ["4. Maple Trees"] = tree({
                id.Loc.FFH_MAPLE_TREE_TRUNK, id.Loc.FFH_MAPLE_TREE_CANOPY,
            }, "Maple", true, 3100, 0, 70),
            ["5. Teak Trees"] = tree(id.Loc.TEAKTREE, "Teak", true, 2400, 0, 90),
            ["6. Willow Trees"] = tree(id.Loc.VEGETATION_TREE_WILLOW_V2, "Willow", true, 3400, -10, 80),
            ["7. Oak Trees"] = tree({
                id.Loc.FFH_OAK_TREE_TRUNK, id.Loc.FFH_OAK_TREE_CANOPY,
            }, "Oak", true, 1800, 0, 70),
            ["8. Normal Trees"] = tree(id.Loc.VEGETATION_TREE_BASIC_V4, "Normal", true, 2800, -8, 70),
            ["9. [Previous options]"] = {
                anchor = "bottomRight",
                nameOverride = "Previous",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitEternalMagicTrees:Define()
    return {
        title = "Eternal Magic Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. Piscatoris"] = {
                point = {x = 87, y = 60},
            },
            ["2. Dalia's Tree Nursery"] = {
                point = {x = 537, y = 170},
                hotkeyOffset = { x = 10, y = -20 }
            },
            ["3. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitElderPage1:Define()
    return {
        title = "Elder Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. East Sorcerer's Tower"] = {
                nameOverride = "Sorcerer's Tower",
                point = {x = 201, y = 117},
            },
            ["2. South Yanille"] = {
                nameOverride = "Yanille",
                point = {x = 157, y = 206},
            },
            ["3. Tree Gnome Stronghold"] = {
                point = {x = 122, y = 96},
            },
            ["4. South Draynor"] = {
                nameOverride = "Draynor",
                point = {x = 313, y = 163},
            },
            ["5. Falador Farm"] = {
                point = {x = 291, y = 140},
            },
            ["6. South Varrock"] = {
                nameOverride = "Varrock",
                point = {x = 350, y = 122},
            },
            ["7. West Lletya"] = {
                nameOverride = "Lletya",
                point = {x = 90, y = 190},
            },
            ["8. Piscatoris"] = {
                point = {x = 87, y = 60},
            },
            ["9. [More options]"] = {
                anchor = "bottomRight",
                nameOverride = "Next Page",
                icons = teleportIcons.nextArrow,
            },
            ["0. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitElderPage2:Define()
    return {
        title = "Elder Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. South Edgeville"] = {
                nameOverride = "Edgeville",
                point = {x = 304, y = 100},
            },
            ["2. North Rimmington"] = {
                nameOverride = "Rimmington",
                point = {x = 265, y = 162},
            },
            ["3. Fort Forinthry Grove"] = {
                point = {x = 382, y = 72},
            },
            ["4. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Previous Page",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitIdols:Define()
    return {
        title = "Overgrown Idols",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. West of the Karamja Shipyard"] = {
                nameOverride = "Karamja Shipyard",
                point = {x = 263, y = 215},
            },
            ["2. North of the Jadinko Vine Cave"] = {
                nameOverride = "Jadinko Vine Cave",
                point = {x = 266, y = 236},
            },
            ["3. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitMagic:Define()
    return {
        title = "Magic Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. East Ranging Guild"] = {
                nameOverride = "Ranging Guild",
                point = {x = 195, y = 97},
            },
            ["2. Sorcerer's Tower"] = {
                point = {x = 195, y = 125},
            },
            ["3. Mage Training Arena"] = {
                point = {x = 390, y = 143},
            },
            ["4. South Tirannwn"] = {
                nameOverride = "Tirannwn",
                point = {x = 89, y = 194},
            },
            ["5. Crwys Sector"] = {
                nameOverride = "Crwys District",
                point = {x = 67, y = 119},
            },
            ["6. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitYew:Define()
    return {
        title = "Yew Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. Seers' Graveyard"] = {
                point = {x = 195, y = 93},
            },
            ["2. West Catherby"] = {
                nameOverride = "Catherby",
                point = {x = 208, y = 106},
            },
            ["3. Edgeville"] = {
                point = {x = 304, y = 94},
            },
            ["4. Varrock Palace"] = {
                point = {x = 337, y = 89},
            },
            ["5. Crwys Sector"] = {
                nameOverride = "Crwys District",
                point = {x = 67, y = 119},
            },
            ["6. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitChokingIvy:Define()
    return {
        title = "Choking Ivy",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. North Varrock Palace"] = {
                point = {x = 343, y = 85},
            },
            ["2. East Varrock Palace"] = {
                point = {x = 358, y = 97},
            },
            ["3. North Falador"] = {
                nameOverride = "Falador North Wall",
                point = {x = 276, y = 119},
            },
            ["4. South Falador"] = {
                nameOverride = "Falador South Wall",
                point = {x = 279, y = 144},
            },
            ["5. South-east Taverley"] = {
                nameOverride = "Taverley Lake",
                point = {x = 263, y = 103},
            },
            ["6. East Ardougne Church"] = {
                point = {x = 174, y = 140},
            },
            ["7. North Yanille"] = {
                nameOverride = "Yanille North Wall",
                point = {x = 159, y = 194},
            },
            ["8. South Castle Wars"] = {
                nameOverride = "Castle Wars South Wall",
                point = {x = 120, y = 209},
            },
            ["9. Crwys Sector"] = {
                nameOverride = "Crwys District",
                point = {x = 67, y = 119},
            },
            ["0. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitCreepingIvy:Define()
    return {
        title = "Creeping Ivy",
        background = backgrounds.runescapeSurfaceFull,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. Wendlewick"] = {
                point = {x = 545, y = 129},
            },
            ["2. Geva's Cabin"] = {
                point = {x = 542, y = 89},
            },
            ["3. Raz's Hut"] = {
                point = {x = 583, y = 101},
            },
            ["4. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitMahogany:Define()
    return {
        title = "Mahogany Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. Tai Bwo Wannai"] = {
                point = {x = 232, y = 204},
            },
            ["2. Ape Atoll"] = {
                point = {x = 210, y = 300},
            },
            ["3. Kharazi Jungle"] = {
                point = {x = 263, y = 252},
            },
            ["4. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitAcadia:Define()
    return {
        title = "Acadia Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. Het's Oasis"] = {
                point = {x = 371, y = 158},
            },
            ["2. Menaphos"] = {
                point = {x = 335, y = 298},
            },
            ["3. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitMaple:Define()
    return {
        title = "Maple Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. South Varrock"] = {
                point = {x = 353, y = 121},
            },
            ["2. Seers' Village"] = {
                point = {x = 204, y = 89},
            },
            ["3. Daemonheim Peninsula Resource Dungeon"] = {
                point = {x = 424, y = 50},
            },
            ["4. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitTeak:Define()
    return {
        title = "Teak Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. Musa Point"] = {
                point = {x = 250, y = 184},
            },
            ["2. Tai Bwo Wannai"] = {
                point = {x = 232, y = 204},
            },
            ["3. Ape Atoll"] = {
                point = {x = 210, y = 300},
            },
            ["4. South-west Castle Wars"] = {
                point = {x = 93, y = 213},
            },
            ["5. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitWillow:Define()
    return {
        title = "Willow Trees",
        background = backgrounds.runescapeSurfaceFull,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. Draynor"] = {
                point = {x = 308, y = 158},
            },
            ["2. Catherby"] = {
                point = {x = 220, y = 102},
            },
            ["3. Barbarian Outpost"] = {
                point = {x = 148, y = 68},
            },
            ["4. Marigold Farm"] = {
                point = {x = 568, y = 148},
            },
            ["5. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

function EliteWoodcuttingOutfitOakNormal:Define()
    return {
        title = "Trees",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.skills.woodcutting,
        entries = {
            ["1. West Varrock"] = {
                point = {x = 329, y = 107},
            },
            ["2. East Varrock"] = {
                point = {x = 362, y = 93},
            },
            ["3. [Previous options]"] = {
                anchor = "bottomLeft",
                nameOverride = "Back",
                icons = teleportIcons.prevArrow,
            }
        },
    }
end

local pages = {
    EliteWoodcuttingOutfitMainPage1, EliteWoodcuttingOutfitMainPage2,
    EliteWoodcuttingOutfitEternalMagicTrees,
    EliteWoodcuttingOutfitElderPage1, EliteWoodcuttingOutfitElderPage2,
    EliteWoodcuttingOutfitIdols,
    EliteWoodcuttingOutfitMagic,
    EliteWoodcuttingOutfitYew,
    EliteWoodcuttingOutfitChokingIvy,
    EliteWoodcuttingOutfitCreepingIvy,

    EliteWoodcuttingOutfitMahogany,
    EliteWoodcuttingOutfitAcadia,
    EliteWoodcuttingOutfitMaple,
    EliteWoodcuttingOutfitTeak,
    EliteWoodcuttingOutfitWillow,
    EliteWoodcuttingOutfitOakNormal
}

for _, page in ipairs({ EliteWoodcuttingOutfitMainPage1, EliteWoodcuttingOutfitMainPage2 }) do
    function page:BeginVisuals()
        ModelSlotMenu.BeginVisuals(self)
        self.teleportsCounter = TeleportCounter.New(self.slotLayer, true, true)
        self.teleportsCounter.height = 44
        self.teleportsCounter.label.maxLines = 2
    end

    function page:ApplyLayout(layout)
        ModelSlotMenu.ApplyLayout(self, layout)
        local counter = self.teleportsCounter
        local arrow = self.slots[#self.slots].layer
        counter:Layout(self.slots[1].layer.width, layout.height)
        counter.root:SetPos(arrow.x + arrow.width - counter.root.width, arrow.y - counter.height - 6)
    end

    function page:UpdateVisuals(layout, hovered)
        self.teleportsCounter:Update(20 - var.VarPlayer.TRH113_ELITE_WOODCUTTING_DAILY_TELEPORTS.value)
        ModelSlotMenu.UpdateVisuals(self, layout, hovered)
    end

    function page:ReleaseVisuals()
        cleanup.Release(self, "teleportsCounter")
        ModelSlotMenu.ReleaseVisuals(self)
    end
end

return pages
