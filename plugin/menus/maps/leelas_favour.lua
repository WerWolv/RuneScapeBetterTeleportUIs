local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local Model3D = require("impl/ui/model_3d")
local text = require("impl/text")
local LeelasFavour = ModalChoiceMenu:Extend("leelasFavour")

function LeelasFavour:Define()
    return {
        title = "Menaphos",
        background = backgrounds.menaphos,
        noBackgroundCrop = true,
        entries = {
            ["1. Imperial District"] = {
                point = {x = 402, y = 409},
                icons = teleportIcons.menaphosFactions.imperial,
            },
            ["2. Merchant District"] = {
                point = {x = 573, y = 213},
                icons = teleportIcons.menaphosFactions.merchant,
            },
            ["3. Port District"] = {
                point = {x = 544, y = 778},
                icons = teleportIcons.menaphosFactions.port,
            },
            ["4. Worker District"] = {
                point = {x = 336, y = 168},
                icons = teleportIcons.menaphosFactions.worker,
            },
            ["5. Soul Obelisk"] = {
                point = {x = 92, y = 770},
                hidden = true,
            },
            ["6. Shifting Tombs"] = {
                point = {x = 597, y = 409},
                icons = teleportIcons.shiftingTombs,
            },
            ["7. Sophanem Slayer Dungeon"] = {
                point = {x = 825, y = 494},
                icons = teleportIcons.sophanemSlayerDungeon,
            },
        },
    }
end

function LeelasFavour:BeginVisuals()
    ModalChoiceMenu.BeginVisuals(self)

    for _, row in ipairs(self.session.rows) do
        if row.entryKey ==  "5. Soul Obelisk" then
            self.obeliskRow = row
            self.obeliskPortrait = Model3D.FromLoc(
                self.backgroundView.layer,
                config.Loc.MENAPHOS_SLAYER_BOSS_OBELISK_SURFACE,
                {
                    left = 20, bottom = -80,
                    width = 100, height = 300,
                    hotkey = text.Hotkey(row.name),
                    camera = {
                        target = { x = 0, y = 1000, z = 0 },
                        yaw = 75,
                        pitch = 0,
                        distance = 6000,
                        fov = 45,
                        nearPlane = 1, farPlane = 10000,
                    },
                }
            )
            self:AttachTooltip(row, row.click)
            break
        end
    end
end

function LeelasFavour:ApplyLayout(layout)
    ModalChoiceMenu.ApplyLayout(self, layout)

    if self.obeliskPortrait ~= nil then
        local portrait, row = self.obeliskPortrait, self.obeliskRow
        portrait.layer.hidden = row.disabled
        self:HideRowArtwork(self.obeliskRow)

        if not portrait.layer.hidden then
            self:LayoutRow(row, portrait:Layout(layout))
        end
    end
end

function LeelasFavour:GetHovered()
    local row = self.obeliskRow

    if row ~= nil and not self.obeliskPortrait.layer.hidden
        and not row.locked and row.click.visibleGlobal and row.click.isMouseOver then
        return row.name
    end

    return ModalChoiceMenu.GetHovered(self)
end

function LeelasFavour:UpdateVisuals(layout, hovered)
    ModalChoiceMenu.UpdateVisuals(self, layout, hovered)

    if self.obeliskPortrait ~= nil and not self.obeliskPortrait.layer.hidden then
        self.obeliskPortrait:Update(self.obeliskRow.disabled, hovered == self.obeliskRow.name)
    end
end

function LeelasFavour:ReleaseVisuals()
    ModalChoiceMenu.ReleaseVisuals(self)
    self.obeliskPortrait, self.obeliskRow = nil, nil
end

return LeelasFavour
