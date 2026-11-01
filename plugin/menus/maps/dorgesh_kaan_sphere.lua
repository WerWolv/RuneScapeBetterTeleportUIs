local ChoiceV2Menu = require("impl/interfaces/choice_v2_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local DorgeshKaanSphere = ChoiceV2Menu:Extend("dorgeshKaanSphere")

function DorgeshKaanSphere:Define()
    return {
        title = "Dorgesh-kaan",
        background = backgrounds.parchment,
        noBackgroundCrop = true,
        vignette = false,
        icons = teleportIcons.dorgeshKaanSphere,
        entries = {
            ["1. Dorgesh-kaan North"] = {
                nameOverride = "North",
                point = {x = 150, y = 60},
            },
            ["2. Dorgesh-kaan South"] = {
                nameOverride = "South",
                point = {x = 150, y = 315},
            },
            ["3. Dorgesh-kaan East"] = {
                nameOverride = "East",
                point = {x = 270, y = 188},
            },
            ["4. Dorgesh-kaan West"] = {
                nameOverride = "West",
                point = {x = 30, y = 188},
            },
        },
    }
end

function DorgeshKaanSphere:BeginVisuals()
    ChoiceV2Menu.BeginVisuals(self)
    self.compass = ui.Sprite.new(self.backgroundView.layer)
    self.compass.spriteID = id.Sprite.ELR_MAP_COMPASS
    self.compass.clickthrough = true
end

function DorgeshKaanSphere:ApplyLayout(layout)
    ChoiceV2Menu.ApplyLayout(self, layout)
    local size = math.floor(math.min(layout.width, layout.height) * 0.6)
    self.compass:SetSize(size, size)
    self.compass:SetPos(math.floor((layout.width - size) / 2), math.floor((layout.height - size) / 2))
end

function DorgeshKaanSphere:ReleaseVisuals()
    ChoiceV2Menu.ReleaseVisuals(self)
    self.compass = nil
end

return DorgeshKaanSphere
