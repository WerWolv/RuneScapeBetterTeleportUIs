local MaxGuildPortalMenu = require("impl/interfaces/native/max_guild_portal_menu")
local ModelSlotMenu = require("impl/interfaces/presentations/model_slot_menu")
local modelSlotStyles = require("definitions/model_slot_styles")
local HotkeyBadge = require("impl/ui/hotkey_badge")

local MaxGuildPortal = ModelSlotMenu.Create(MaxGuildPortalMenu, "maxGuildPortal")
local portalLabels = { "L", "R", "B" }

function MaxGuildPortal:GetDescription(row)
    if row.disabled and row.assignedPortal == nil then
        return row.destination.lockedDescription
    end
    return MaxGuildPortalMenu.GetDescription(self, row)
end

function MaxGuildPortal:GetSlotStyle(row, hovered)
    if row.assignedPortal ~= nil then
        return self.definition.slotStyles.assigned
    end
    return ModelSlotMenu.GetSlotStyle(self, row, hovered)
end

function MaxGuildPortal:UpdateVisuals(layout, hovered)
    ModelSlotMenu.UpdateVisuals(self, layout, hovered)

    for _, slot in ipairs(self.slots) do
        local assignment = slot.row.assignedPortal
        if assignment ~= nil then
            if slot.portalBadge == nil then
                slot.portalBadge = HotkeyBadge.New(slot.layer, portalLabels[assignment])
                slot.portalBadgeOptions = { forceVisible = true, disabled = false, preserveOrder = true }
            end
            if slot.portalAssignment ~= assignment then
                slot.portalBadge.label.content = portalLabels[assignment]
                slot.portalAssignment = assignment
            end
            local options = slot.portalBadgeOptions
            options.scale, options.inset = layout.scale, math.ceil(6 * layout.scale)
            slot.portalBadge:Update(slot.layer, options)
            slot.hotkey:Hide()
        elseif slot.portalBadge ~= nil then
            slot.portalBadge:Hide()
        end
    end
end

local function model(modelID, distance, offset)
    return {
        modelID = modelID,
        viewDistance = distance,
        modelOffset = { x = 0, y = offset },
    }
end

local function npc(npcID, animID, distance, offset)
    return {
        npcID = npcID,
        animID = animID,
        viewDistance = distance,
        modelOffset = { x = 0, y = offset },
    }
end

function MaxGuildPortal:Define()
    local entries = {
        ["Active crystal tree"] = model(id.Model.CRYSTAL_TREE, 2500, 60),
        ["Jadinko Lair"] = npc(id.NPC.JARO_MUTATED_JADINKO_MALE, id.Seq.JARO_JARDINKO_ADULT_READY, 800, 90),
        ["Lava Flow Mine"] = npc(id.NPC.LFM_GOLD_NYMPH, id.Seq.LFM_NYMPH_READY, 600, 150),
        ["Living Rock Caverns"] = npc(id.NPC.LRC_ROCK_CREATURE_MELEE, id.Seq.LRC_ROCK_CREATURE_MELEE_READY, 1500, 50),
        ["Brilliant wisp colony"] = npc(id.NPC.DIV_WISP9, id.Seq.DIV_WISP_READY_WALK, 500, 120),
        ["Radiant wisp colony"] = npc(id.NPC.DIV_WISP10, id.Seq.DIV_WISP_READY_WALK, 500, 120),
        ["Luminous wisp colony"] = npc(id.NPC.DIV_WISP11, id.Seq.DIV_WISP_READY_WALK, 500, 120),
        ["Incandescent wisp colony"] = npc(id.NPC.DIV_WISP12, id.Seq.DIV_WISP_READY_WALK, 500, 120),
        ["Runespan"] = npc(id.NPC.TRH203_RUNESPAN_CREATURE_NEBULA, nil, 600, 80),
        ["Tree Gnome Stronghold"] = npc(id.NPC.JMOD_SPIRIT_TREE_TRANSMOG, nil, 2300, 50),
        ["Zanaris Fairy Ring"] = model(id.Model.NATURAL_MUSHROOMS_FAIRY_RING, 350, 40),
        ["Puro-Puro"] = npc(id.NPC.II_IMPLING_TYPE_10, id.Seq.II_IMPLING_READY, 300, 350),
        ["Prifddinas Waterfall"] = npc(id.NPC.ECWF_LEAPING_FISH, id.Seq.ECWF_URCHIN_BIG_IDLE, 1000, 0),
        ["Invention Guild"] = model(id.Model.INVENT_WORKBENCH, 1300, 60),
        ["Menaphos VIP area"] = model(id.Model.MENAPHOS_ACACIA_TREE_VIP_01, 3400, 30),
        ["Deep sea fishing hub"] = npc(id.NPC.DSF_JELLYFISH_HIGH_BAD, id.Seq.DSF_JELLYFISH_SWIM_IDLE_RAISED, 800, -30),
        ["Overgrown idols"] = model(id.Model.JUNGLE_VINES_MONKEY_IDOL, 1000, 50),
        ["Anachronia Dinosaur Farm"] = npc(id.NPC.POF_ANIMAL_PAVOSAURUS_REX_BASIC, id.Seq.BIG_GAME_TYRANNOSAUR_IDLE, 2600, 150),
    }

    local descriptions = {
        ["Active crystal tree"] = { unlocked = "", locked = "" },
        ["Jadinko Lair"] = { unlocked = "", locked = "" },
        ["Lava Flow Mine"] = { unlocked = "", locked = "" },
        ["Living Rock Caverns"] = { unlocked = "", locked = "" },
        ["Brilliant wisp colony"] = { unlocked = "", locked = "" },
        ["Radiant wisp colony"] = { unlocked = "", locked = "" },
        ["Luminous wisp colony"] = { unlocked = "", locked = "" },
        ["Incandescent wisp colony"] = { unlocked = "", locked = "" },
        ["Runespan"] = { unlocked = "", locked = "" },
        ["Tree Gnome Stronghold"] = { unlocked = "", locked = "" },
        ["Zanaris Fairy Ring"] = { unlocked = "", locked = "" },
        ["Puro-Puro"] = { unlocked = "", locked = "" },
        ["Prifddinas Waterfall"] = { unlocked = "", locked = "" },
        ["Invention Guild"] = { unlocked = "", locked = "" },
        ["Menaphos VIP area"] = { unlocked = "", locked = "" },
        ["Deep sea fishing hub"] = { unlocked = "", locked = "" },
        ["Overgrown idols"] = { unlocked = "", locked = "" },
        ["Anachronia Dinosaur Farm"] = { unlocked = "", locked = "" },
    }

    for name, entry in pairs(entries) do
        entry.nameOverride = name
        entry.description = descriptions[name].unlocked
        entry.lockedDescription = descriptions[name].locked
    end
    self:ConfigureDestinations(entries)

    return {
        title = "Max Guild Portal Destination",
        columns = 6,
        rows = 3,
        showLabels = true,
        overlayLabels = true,
        labelStyle = {
            font = id.Font.NOTOSANS_SEMIBOLD_11,
            backgroundRGBA = 0x140F0AA0,
            inset = 6, paddingX = 4, paddingY = 2,
        },
        slotStyles = {
            normal = modelSlotStyles.normal,
            hovered = modelSlotStyles.hovered,
            disabled = modelSlotStyles.disabled,
            assigned = {
                modelAlpha = 1, modelBrightness = 1,
                backgroundAlpha = 1, backgroundRGB = 0xFFE9A3,
                labelAlpha = 1, labelRGBA = modelSlotStyles.normal.labelRGBA,
            },
        },
        sizeMultiplier = 1.75,
        entries = entries,
    }
end

return MaxGuildPortal
