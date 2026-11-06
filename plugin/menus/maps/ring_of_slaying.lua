local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local Model3D = require("impl/ui/model_3d")
local cleanup = require("impl/cleanup")
local RingOfSlaying = ModalChoiceMenu:Extend("ringOfSlaying")

local slayerMasters = {
    [1] = {
        name = "Spria",
        npcID = id.NPC.SLAYER_MASTER_1_SPRIA,
    },
    [2] = {
        name = "Mazchna",
        npcID = id.NPC.SLAYER_MASTER_2_MAZCHNA,
    },
    [3] = {
        name = "Vannaka",
        npcID = id.NPC.SLAYER_MASTER_3,
    },
    [4] = {
        name = "Chaeldar",
        npcID = id.NPC.SLAYER_MASTER_4,
        animID = id.Seq.FAIRYKIT_FAIRY_QUEEN_READY,
        targetY = 650,
    },
    [5] = {
        name = "Lapalok",
        npcID = id.NPC.SLAYER_MASTER_5_LAPALOK,
    },
    [6] = {
        name = "Kuradal",
        npcID = id.NPC.SLAYER_MASTER_6_KURADAL,
    },
    [7] = {
        name = "Morvran",
        npcID = id.NPC.SLAYER_MASTER_7_IORWERTH,
        animID = id.Seq.ELF_2014_SLAYER_MASTER_IDLE,
        distance = 700,
        targetY = 470,
    },
    [8] = {
        name = "Laniakea",
        npcID = id.NPC.SLAYER_MASTER_8_DINO_ISLAND,
        animID = id.Seq.DINO_SLAYER_MASTER_IDLE,
    },
    [9] = {
        name = "The Raptor",
        npcID = id.NPC.SLAYER_MASTER_2A_FORT_SLAYER,
        animID = id.Seq.SIGHERO_RAPTOR_CASUAL_READY,
    },
    [45] = {
        name = "Sumona",
        npcID = id.NPC.SMKI_SUMONA,
    },
    [46] = {
        name = "Mandrith",
        npcID = id.NPC.BOUNTY_MANDRITH,
        distance = 850,
        targetY = 600,
    },
    [47] = {
        name = "Jacquelyn",
        npcID = id.NPC.SLAYER_MASTER_1A_JACQUELYN,
    },
}

local function currentSlayerMaster()
    local variable = var.VarPlayer.SLAYER_MASTER
    return variable and slayerMasters[variable.value] or nil
end

local function slayerOptionsName()
    local master = currentSlayerMaster()
    return master and ("Talk to <col=ffff00>" .. master.name .. "</col>") or "Slayer options"
end

function RingOfSlaying:Define()
    return {
        title = "Ring of Slaying",
        background = backgrounds.runescapeSurface,
        icons = teleportIcons.jewellery.goldEnchantedGem,
        entries = {
            ["1. Sumona in Pollnivneach."] = {
                nameOverride = "Pollnivneach",
                point = {x = 374, y = 234},
            },
            ["2. Morytania Slayer Tower."] = {
                nameOverride = "Morytania Slayer Tower",
                point = {x = 404, y = 76},
            },
            ["3. Fremennik Slayer Dungeon."] = {
                nameOverride = "Fremennik Slayer Dungeon",
                point = {x = 199, y = 28},
            },
            ["4. Tarn's Lair."] = {
                nameOverride = "Tarn's Lair",
                point = {x = 416, y = 157},
            },
            ["5. Nowhere. Give me Slayer options."] = {
                nameOverride = slayerOptionsName,
                point = {x = 0, y = 0}
            },
        },
    }
end

-- Re-resolve the label and portrait together when the player's master changes.
function RingOfSlaying:Matches(snapshot)
    return ModalChoiceMenu.Matches(self, snapshot)
        and self.session.slayerMaster == currentSlayerMaster()
end

-- The shared portrait owns drawing; the original Slayer options row owns input.
function RingOfSlaying:BeginVisuals()
    ModalChoiceMenu.BeginVisuals(self)
    self.session.slayerMaster = currentSlayerMaster()

    local master = self.session.slayerMaster

    if master == nil then
        return
    end

    for _, row in ipairs(self.session.rows) do
        if row.entryKey == "5. Nowhere. Give me Slayer options." then
            -- Keep its native tooltip, but let the portrait supply the artwork and hitbox.
            row.destination.hidden = true
            self.masterPortrait = Model3D.FromNPC(
                self.backgroundView.layer,
                master.npcID, master.animID or id.Seq.HUMAN_READY,
                {
                    left = 0, bottom = 0,
                    width = 160, height = 200,
                    camera = {
                        target = { x = 0, y = master.targetY or 580, z = 0 },
                        yaw = 180, pitch = 0,
                        distance = master.distance or 600,
                        fov = 45,
                        nearPlane = 1, farPlane = 10000,
                    },
                }
            )
            self.masterPortrait.optionsRow = row
            break
        end
    end
end

function RingOfSlaying:ApplyLayout(layout)
    ModalChoiceMenu.ApplyLayout(self, layout)

    local portrait = self.masterPortrait

    if portrait == nil then
        return
    end

    local row = portrait.optionsRow
    self:HideRowArtwork(row)
    self:LayoutRow(row, portrait:Layout(layout))

    local cursor = row.click.cursorConfig
    if cursor.mouseOverCursor ~= id.Cursor.CURSOR_TALKTO then
        portrait.originalCursor = cursor.mouseOverCursor
        cursor.mouseOverCursor = id.Cursor.CURSOR_TALKTO
    end
end

-- Select the portrait before showing tooltips so cursor following stays active throughout a hover.
function RingOfSlaying:GetHovered()
    local portrait = self.masterPortrait
    local row = portrait and portrait.optionsRow

    if row ~= nil and not portrait.layer.hidden and row.click.visibleGlobal and row.click.isMouseOver then
        return row.name
    end

    return ModalChoiceMenu.GetHovered(self)
end

function RingOfSlaying:UpdateVisuals(layout, hovered)
    ModalChoiceMenu.UpdateVisuals(self, layout, hovered)

    local portrait = self.masterPortrait

    if portrait ~= nil then
        portrait:Update(portrait.optionsRow.disabled, hovered == portrait.optionsRow.name)
    end
end

function RingOfSlaying:ReleaseVisuals()
    local portrait = self.masterPortrait
    if portrait ~= nil and portrait.originalCursor ~= nil then
        cleanup.Try("restore Slayer master cursor", function()
            local cursor = portrait.optionsRow.click.cursorConfig
            if cursor.mouseOverCursor == id.Cursor.CURSOR_TALKTO then
                cursor.mouseOverCursor = portrait.originalCursor
            end
        end)
    end

    ModalChoiceMenu.ReleaseVisuals(self)
    self.masterPortrait = nil
end

return RingOfSlaying
