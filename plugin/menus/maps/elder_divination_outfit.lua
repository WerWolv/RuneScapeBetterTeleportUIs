local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local descriptions = require("definitions/descriptions")
local TeleportCounter = require("impl/ui/teleport_counter")
local cleanup = require("impl/cleanup")

local ElderDivinationOutfitPage1 = MapMenu.Create(ModalChoiceMenu, "elderDivinationOutfitPage1")
local ElderDivinationOutfitPage2 = MapMenu.Create(ModalChoiceMenu, "elderDivinationOutfitPage2")

local function beginVisuals(self)
    MapMenu.BeginVisuals(self)
    self.teleportsCounter = TeleportCounter.New(self.backgroundView.layer, false)
end

local function applyLayout(self, layout)
    MapMenu.ApplyLayout(self, layout)
    self.teleportsCounter:Layout(layout.width, layout.height)
end

local function updateVisuals(self, layout, hovered)
    -- Keep the counter above the map artwork while the shared presentation raises its vignette last.
    self.teleportsCounter:Update(var.VarPlayer.TRH75_DAILY_TELEPORTS.value)
    MapMenu.UpdateVisuals(self, layout, hovered)
end

local function releaseVisuals(self)
    cleanup.Release(self, "teleportsCounter")
    MapMenu.ReleaseVisuals(self)
end

for _, page in ipairs({ ElderDivinationOutfitPage1, ElderDivinationOutfitPage2 }) do
    page.BeginVisuals = beginVisuals
    page.ApplyLayout = applyLayout
    page.UpdateVisuals = updateVisuals
    page.ReleaseVisuals = releaseVisuals
end

local function wisp(npcID)
    return {
        npcID = npcID,
        animID = id.Seq.DIV_WISP_READY_WALK,
        camera = {
            target = { x = 0, y = 540, z = 0 },
            yaw = 0, pitch = 10, distance = 700, fov = 40,
            nearPlane = 1, farPlane = 2000,
        },
        size = 35,
        backdrop = { image = Plugin.resources.icons.backdrop },
    }
end

local function colony(name, level, location, npcID, x, y)
    return {
        nameOverride = name .. " wisps",
        description = descriptions.LevelRequirement(level, descriptions.SKILL.DIVINATION)
            .. descriptions.Location(location),
        point = { x = x, y = y },
        icons = wisp(npcID),
        hotkeyOffset = { x = 10, y = -20 }
    }
end

function ElderDivinationOutfitPage1:Define()
    return {
        title = "Divination Colonies",
        background = backgrounds.runescapeSurface,
        noBackgroundCrop = true,
        sizeMultiplier = 1.25,
        entries = {
            ["1. Optimum colony"] = {
                nameOverride = "Optimum colony",
                description = descriptions.Text("The highest-level colony you can access."),
                anchor = "topLeft",
                icons = { sprite = id.Sprite.BP3_MISSION_ICON_SKILL_DIVINATION, size = 36 },
                hotkeyOffset = { x = 15, y = -15 },
            },
            ["2. Incandescent wisps, south of the Poison Waste (lvl 95+)"] = colony(
                "Incandescent", 95, "South of the Poison Waste", id.NPC.DIV_WISP12, 80, 200
            ),
            ["3. Luminous wisps, south of Sophanem (lvl 90+)"] = colony(
                "Luminous", 90, "South of Sophanem", id.NPC.DIV_WISP11, 380, 290
            ),
            ["4. Radiant wisps, on Dragontooth Island (lvl 85+)"] = colony(
                "Radiant", 85, "Dragontooth Island", id.NPC.DIV_WISP10, 500, 75
            ),
            ["5. Brilliant wisps, east of the Mage Training Area (lvl 80+)"] = colony(
                "Brilliant", 80, "East of the Mage Training Area", id.NPC.DIV_WISP9, 400, 140
            ),
            ["6. Elder wisps, in Freneskae (lvl 75+)"] = {
                nameOverride = "Elder wisps",
                description = descriptions.LevelRequirement(75, descriptions.SKILL.DIVINATION)
                    .. descriptions.Location("Freneskae"),
                anchor = "bottomLeft",
                icons = wisp(id.NPC.EDIV_WISP85),
                hotkeyOffset = { x = 10, y = -20 }
            },
            ["7. Lustrous wisps, north of Canifis (lvl 70+)"] = colony(
                "Lustrous", 70, "North of Canifis", id.NPC.DIV_WISP8, 420, 71
            ),
            ["8. Vibrant wisps, north of South Feldip Hills (lvl 60+)"] = colony(
                "Vibrant", 60, "North of South Feldip Hills", id.NPC.DIV_WISP7, 128, 265
            ),
            ["9. Gleaming wisps, in the Karamja Jungle (50+)"] = colony(
                "Gleaming", 50, "Karamja jungle", id.NPC.DIV_WISP6, 235, 210
            ),
            ["0. [More options]"] = {
                nameOverride = "Next",
                anchor = "bottomRight",
                icons = teleportIcons.nextArrow,
            },
        },
    }
end

function ElderDivinationOutfitPage2:Define()
    return {
        title = "Divination Colonies",
        background = backgrounds.runescapeSurface,
        noBackgroundCrop = true,
        sizeMultiplier = 1.25,
        entries = {
            ["1. Sparkling wisps, south-east of Rellekka (lvl 40+)"] = colony(
                "Sparkling", 40, "South-east of Rellekka", id.NPC.DIV_WISP5, 210, 40
            ),
            ["2. Glowing wisps, south-east of Seers' Village (lvl 30+)"] = colony(
                "Glowing", 30, "South-east of Seers' Village", id.NPC.DIV_WISP4, 200, 120
            ),
            ["3. Bright wisps, east of Varrock (lvl 20+)"] = colony(
                "Bright", 20, "East of Varrock", id.NPC.DIV_WISP3, 371, 90
            ),
            ["4. Flickering wisps, north of Falador (lvl 10+)"] = colony(
                "Flickering", 10, "North of Falador", id.NPC.DIV_WISP2, 283, 104
            ),
            ["5. Pale wisps, west of Lumbridge forest (lvl 1+)"] = colony(
                "Pale", 1, "West of Lumbridge forest", id.NPC.DIV_WISP1, 328, 171
            ),
            ["6. Cancel"] = { hidden = true },
            ["7. [More options]"] = {
                nameOverride = "Back",
                anchor = "bottomLeft",
                icons = teleportIcons.prevArrow,
            },
        },
    }
end

return { ElderDivinationOutfitPage1, ElderDivinationOutfitPage2 }
