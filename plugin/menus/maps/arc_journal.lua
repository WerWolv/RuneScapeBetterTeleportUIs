local ModalChoiceMenu = require("impl/interfaces/native/modal_choice_menu")
local MapMenu = require("impl/interfaces/presentations/map_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local geometry = require("impl/map_geometry")
local cleanup = require("impl/cleanup")
local descriptions = require("definitions/descriptions")
local ArcJournal = MapMenu.Create(ModalChoiceMenu, "arcJournal")

function ArcJournal:BeginVisuals()
    MapMenu.BeginVisuals(self)

    self.decorationLayer = ui.Layer.new(self.backgroundView.layer)
    self.decorationLayer.clickthrough = true
    self.decorationSprites = {}

    for index, decoration in ipairs(self.definition.decorations) do
        local sprite = ui.Sprite.new(self.decorationLayer)
        sprite.spriteID = decoration.sprite
        sprite.clickthrough = true
        self.decorationSprites[index] = sprite
    end
end

function ArcJournal:ApplyLayout(layout)
    MapMenu.ApplyLayout(self, layout)

    if self.decorationWidth == layout.width and self.decorationHeight == layout.height then
        return
    end

    self.decorationLayer:SetSize(layout.width, layout.height)

    for index, decoration in ipairs(self.definition.decorations) do
        local x, y, width, height = geometry.Rectangle(
            self.session.menu.background,
            decoration.x, decoration.y, decoration.width, decoration.height,
            layout.width, layout.height
        )
        local sprite = self.decorationSprites[index]
        sprite:SetPos(x, y)
        sprite:SetSize(width, height)
    end

    self.decorationWidth, self.decorationHeight = layout.width, layout.height
end

function ArcJournal:ReleaseVisuals()
    cleanup.Release(self, "decorationLayer")
    self.decorationSprites = nil
    self.decorationWidth, self.decorationHeight = nil, nil

    MapMenu.ReleaseVisuals(self)
end

local function teleportsRemaining(count)
    local noun = tonumber(count) == 1 and "teleport" or "teleports"
    return descriptions.Text(string.format("%s <sprite=27621> %s left", count, noun))
end

function ArcJournal:Define()
    return {
        title = "The Arc",
        background = backgrounds.arcParchment,
        noBackgroundCrop = true,
        sizeMultiplier = 1.5,
        decorations = {
            { sprite = id.Sprite.ELR_MAP_COMPASS,         x = 590, y = 18,  width = 110, height = 110 },
            { sprite = id.Sprite.ELR_ARC_LOGO_0,          x = 40,  y = 280, width = 128, height = 128 },
            { sprite = id.Sprite.ELR_ARC_ISLAND_NAME_1_0, x = 70,  y = 60,  width = 96,  height = 96  }, -- Tuai Leit
            { sprite = id.Sprite.ELR_ARC_ISLAND_NAME_2_0, x = 210, y = 75,  width = 128, height = 32  }, -- Whale's Maw
            { sprite = id.Sprite.ELR_ARC_ISLAND_NAME_3_0, x = 120, y = 216, width = 64,  height = 32  }, -- Waiko
            { sprite = id.Sprite.ELR_ARC_ISLAND_NAME_4_0, x = 454, y = 115, width = 128, height = 64  }, -- Ghoshima
            { sprite = id.Sprite.ELR_ARC_ISLAND_NAME_5_0, x = 263, y = 160, width = 192, height = 64  }, -- The Islands That Once Were Turtles
            { sprite = id.Sprite.ELR_ARC_ISLAND_NAME_6_0, x = 300, y = 328, width = 96,  height = 64  }, -- Aminishi
            { sprite = id.Sprite.ELR_ARC_ISLAND_NAME_7_0, x = 450, y = 362, width = 80,  height = 32  }, -- Cyclosis
        },
        entries = {
            ["1. Port Sarim."] = {
                nameOverride = "Port Sarim",
                point = {x = 580, y = 270},
                icons = teleportIcons.arcIslands.ship,
                hotkeyOffset = { x = 70, y = -50 },
            },
            ["^2%. Waiko%. %((%d+)%)$"] = {
                nameOverride = "Waiko",
                description = teleportsRemaining,
                point = {x = 210, y = 210},
                icons = teleportIcons.arcIslands.waiko,
                hotkeyOffset = { x = 28, y = -24 },
            },
            ["^3%. Whale's Maw%. %((%d+)%)$"] = {
                nameOverride = "Whale's Maw",
                description = teleportsRemaining,
                point = {x = 270, y = 120},
                icons = teleportIcons.arcIslands.whalesMaw,
                hotkeyOffset = { x = 24, y = -8 },
            },
            ["^4%. Aminishi%. %((%d+)%)$"] = {
                nameOverride = "Aminishi",
                description = teleportsRemaining,
                point = {x = 330, y = 330},
                icons = teleportIcons.arcIslands.aminishi,
                hotkeyOffset = { x = 40, y = -40 },
            },
            ["^5%. Cyclosis%. %((%d+)%)$"] = {
                nameOverride = "Cyclosis",
                description = teleportsRemaining,
                point = {x =  420, y = 360},
                icons = teleportIcons.arcIslands.cyclosis,
                hotkeyOffset = { x = 24, y = -18 },
            },
            ["^6%. Tuai Leit%. %((%d+)%)$"] = {
                nameOverride = "Tuai Leit",
                description = teleportsRemaining,
                point = {x = 150, y = 70},
                icons = teleportIcons.arcIslands.tuaiLeit,
                hotkeyOffset = { x = 30, y = -30 },
            },
            ["^7%. The Islands That Once Were Turtles%. %((%d+)%)$"] = {
                nameOverride = "The Islands That Once Were Turtles",
                description = teleportsRemaining,
                point = {x = 370, y = 240},
                icons = teleportIcons.arcIslands.turtleIslands,
                hotkeyOffset = { x = 75, y = -30 },
            },
            ["^8%. Goshima%. %((%d+)%)$"] = {
                nameOverride = "Goshima",
                description = teleportsRemaining,
                point = {x = 530, y = 180},
                icons = teleportIcons.arcIslands.goshima,
                hotkeyOffset = { x = 38, y = -24 },
            },
        },
    }
end

return ArcJournal
