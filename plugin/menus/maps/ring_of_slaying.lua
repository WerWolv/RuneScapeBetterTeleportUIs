local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local backgrounds = require("definitions/backgrounds")
local teleportIcons = require("definitions/teleport_icons")
local cropped = require("definitions/artwork_variants").Cropped
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
        offsetY = 300,
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
        offsetY = 240,
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
        viewDistance = 500,
        offsetY = 250,
    },
    [47] = {
        name = "Jacquelyn",
        npcID = id.NPC.SLAYER_MASTER_1A_JACQUELYN,
    },
}

local function currentSlayerMaster()
    return slayerMasters[var.VarPlayer.SLAYER_MASTER.value]
end

function RingOfSlaying:Define()
    return {
        title = "Ring of Slaying",
        background = cropped(
            backgrounds.runescapeSurface, 
            {x = 143, y = 0, width = 316, height = 260}
        ),
        icons = teleportIcons.ringOfSlaying,
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
                nameOverride = "Talk to <col=ffff00>" .. currentSlayerMaster().name .. "</col>",
                point = {x = 0, y = 0}
            },
        },
    }
end

-- Clip the passive model at the map's bottom edge so it rises out of the map.
function RingOfSlaying:BeginVisuals()
    ModalChoiceMenu.BeginVisuals(self)

    local layer = ui.Layer.new(self.backgroundView.layer)
    layer.clickthrough = true
    layer.hidden = true
    self.masterPortrait = { layer = layer }

    for _, row in ipairs(self.session.rows) do
        if row.entryKey == "5. Nowhere. Give me Slayer options." then
            -- Keep its native tooltip, but let the portrait supply the artwork and hitbox.
            row.destination.hidden = true
            self.masterPortrait.optionsRow = row
            break
        end
    end

    local model = ui.Model.new(layer)
    model.clickthrough = true
    self.masterPortrait.model = model
end

function RingOfSlaying:ApplyLayout(layout)
    ModalChoiceMenu.ApplyLayout(self, layout)

    local master = currentSlayerMaster()
    local portrait = self.masterPortrait
    portrait.layer.hidden = master == nil

    if master == nil then
        return
    end

    -- Changing masters refreshes the model without restarting its animation every frame.
    if portrait.master ~= master then
        portrait.model:SetModel(ui.ModelType.NPC_MODEL, master.npcID)
        portrait.model.animID = master.animID or id.Seq.HUMAN_READY
        portrait.model.viewDistance = master.viewDistance or 400
        portrait.master = master
    end

    local scale = math.min(1, layout.width / 500, layout.height / 400)
    local function scaled(value)
        return math.max(1, math.floor(value * scale))
    end

    local size = scaled(112)
    -- Use the whole map as the clipping region, keeping the original portrait scale.
    portrait.layer:SetPos(0, 0)
    portrait.layer:SetSize(layout.width, layout.height)
    portrait.model:SetSize(layout.width, layout.height)
    portrait.model.modelWidth = math.max(1, math.floor(layout.width / scale))
    portrait.model.modelHeight = math.max(1, math.floor(layout.height / scale))

    local offset = portrait.model.screenOffset
    -- Leave room for shoulders and animated arms to the left of the model's centre.
    offset.x = math.floor(size - layout.width / 2 - 75)
    offset.y = math.floor((layout.height - size) / 2) + scaled(master.offsetY or 280)
    offset.z = 0
    portrait.model.screenOffset = offset
    portrait.layer:MoveToFront()

    -- Use the native Slayer options action only over the visible portrait, not its full-map viewport.
    if portrait.optionsRow ~= nil then
        local origin = portrait.layer.xyGlobal
        local centerX = layout.width / 2 + offset.x
        local left = math.max(0, centerX - size)
        local right = math.min(layout.width, math.max(left, centerX + size))
        local height = math.min(layout.height, scaled(160))

        self:HideRowArtwork(portrait.optionsRow)
        self:LayoutRow(portrait.optionsRow,
            origin.x + left, origin.y + layout.height - height,
            right - left, height
        )

        local button = portrait.optionsRow.click
        local cursor = button.cursorConfig
        if cursor.mouseOverCursor ~= id.Cursor.CURSOR_TALKTO then
            portrait.originalCursor = cursor.mouseOverCursor
            cursor.mouseOverCursor = id.Cursor.CURSOR_TALKTO
        end
    end
end

-- Select the portrait before showing tooltips so cursor following stays active throughout a hover.
function RingOfSlaying:GetHovered()
    local portrait = self.masterPortrait
    local row = portrait.optionsRow

    if not portrait.layer.hidden and row ~= nil and row.click.visibleGlobal and row.click.isMouseOver then
        return row.name
    end

    return ModalChoiceMenu.GetHovered(self)
end

function RingOfSlaying:ReleaseVisuals()
    local portrait = self.masterPortrait
    if portrait ~= nil and portrait.originalCursor ~= nil then
        pcall(function()
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
