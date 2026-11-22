local GliderMenu = require("impl/interfaces/native/glider_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local descriptions = require("definitions/descriptions")

local GnomeGliders = MapMenu.Create(GliderMenu, "gnomeGliders")

local function glider(yaw, pitch)
    return {
        modelID = id.Model.GNOME_AREA_IMP_GLIDER,
        camera = {
            target = { x = 0, y = 120, z = 30 },
            yaw = yaw, pitch = pitch, distance = 3400, fov = 40,
            nearPlane = 1, farPlane = 10000,
        },
        size = 60,
    }
end

function GnomeGliders:Define()
    return {
        title = "Gnome Gliders",
        background = backgrounds.runescapeSurfaceFull,
        entries = {
            ["Grand Tree"] = {
                id = "grandtree",
                nameOverride = "Ta Quir Priw",
                description = descriptions.Location("Grand Tree, Tree Gnome Stronghold"),
                point = { x = 105, y = 67 },
                icons = glider(20, 55),
            },
            ["White Wolf Mountain"] = {
                id = "whitewolfmountain",
                nameOverride = "Sindarpos",
                description = descriptions.Location("White Wolf Mountain"),
                point = { x = 242, y = 93 },
                icons = glider(65, 50),
            },
            ["Digsite"] = {
                id = "digside",
                nameOverride = "Lemanto Andra",
                description = descriptions.Location("Digsite"),
                point = { x = 387, y = 120 },
                icons = glider(110, 60),
            },
            ["Al Kharid"] = {
                id = "alkharid",
                nameOverride = "Kar-Hewo",
                description = descriptions.Location("North of Al Kharid"),
                point = { x = 374, y = 163 },
                icons = glider(155, 55),
            },
            ["Karamja"] = {
                id = "karamja",
                nameOverride = "Gandius",
                description = descriptions.Location("Eastern Karamja"),
                point = { x = 285, y = 232 },
                icons = glider(200, 50),
            },
            ["Feldip Hills"] = {
                id = "feldiphills",
                nameOverride = "Lemantolly Undri",
                description = descriptions.Location("Feldip Hills"),
                point = { x = 155, y = 240 },
                icons = glider(245, 60),
            },
            ["Tree Gnome Village"] = {
                id = "treegnomevillage",
                nameOverride = "Priw Gnomo Andralo",
                description = descriptions.Location("Outside of Tree Gnome Village"),
                point = { x = 129, y = 174 },
                icons = glider(290, 55),
            },
            ["Prifddinas"] = {
                id = "prifddinas",
                nameOverride = "Dylandra",
                description = descriptions.Location("Meilyr Clan, Prifddinas"),
                point = { x = 72, y = 117 },
                icons = glider(335, 50),
            },
            ["Tuai Leit"] = {
                id = "tualeit",
                nameOverride = "Kai-Undri",
                description = descriptions.Location("Tuai Leit, The Arc"),
                anchor = "bottomRight",
                icons = {
                    modelID = id.Model.ME3_IORWORTH_CAMP_GNOMECOPTER,
                    camera = {
                        target = { x = 50, y = 320, z = -300 },
                        yaw = 45, pitch = 30, distance = 3000, fov = 40,
                        nearPlane = 1, farPlane = 15000,
                    },
                    size = 60,
                },
            },
        },
    }
end

function GnomeGliders:BeginVisuals()
    for _, row in ipairs(self.session.menu.rows) do
        row.destination.hotkey = row.native.shortcut
        row.destination.hotkeyOffset = { x = 18, y = -19 }
    end

    MapMenu.BeginVisuals(self)
end

return GnomeGliders
