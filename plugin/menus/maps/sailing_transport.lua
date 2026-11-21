local SailingTransportMenu = require("impl/interfaces/native/sailing_transport_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")

local SailingTransport = MapMenu.Create(SailingTransportMenu, "sailingTransport")

function SailingTransport:Define()
    return {
        title = "Charter Ships",
        background = backgrounds.runescapeSurfaceFull,
        icons = teleportIcons.charterShip,
        entries = {
            TYRAS = {
                nameOverride = "Port Tyras",
                point = { x = 35, y = 197 },
            },
            PHANTASMYS = {
                nameOverride = "Port Phasmatys",
                point = { x = 493, y = 107 },
            },
            CATHERBY = {
                nameOverride = "Catherby",
                point = { x = 229, y = 109 },
            },
            SHIPYARD = {
                nameOverride = "Shipyard",
                point = { x = 272, y = 212 },
            },
            KARAMJA = {
                nameOverride = "Musa Point",
                point = { x = 266, y = 176 },
            },
            BRIMHAVEN = {
                nameOverride = "Brimhaven",
                point = { x = 216, y = 167 },
            },
            KHAZARD = {
                nameOverride = "Port Khazard",
                point = { x = 193, y = 177 },
            },
            SARIM = {
                nameOverride = "Port Sarim",
                point = { x = 300, y = 166 },
            },
            HARMLESS = {
                nameOverride = "Mos Le'Harmless",
                point = { x = 472, y = 234 },
            },
            CRANDOR = {
                nameOverride = "Crandor",
                point = { x = 236, y = 150 },
            },
            OGRESS = {
                nameOverride = "Oo'glog",
                point = { x = 169, y = 268 },
            },
            MENAPHOS = {
                nameOverride = "Menaphos",
                point = { x = 328, y = 309 },
            },
        },
    }
end

function SailingTransport:RefreshAvailability(snapshot)
    SailingTransportMenu.RefreshAvailability(self, snapshot)

    for _, row in ipairs(self.session.menu.rows) do
        row.destination.hidden = not row.click.visibleGlobal
    end
end

return SailingTransport
