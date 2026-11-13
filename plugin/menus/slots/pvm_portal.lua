local PvmPortalMenu = require("impl/interfaces/native/pvm_portal_menu")
local ModelSlotMenu = require("impl/interfaces/presentations/model_slot_menu")
local matcher = require("impl/destination_matcher")
local modelSlotStyles = require("definitions/model_slot_styles")
local HotkeyBadge = require("impl/ui/hotkey_badge")

local PvmPortal = ModelSlotMenu.Create(PvmPortalMenu, "pvmPortal")
local portalLabels = { "L", "R", "M" }

function PvmPortal:RefreshAvailability(snapshot)
    PvmPortalMenu.RefreshAvailability(self, snapshot)
    for _, row in ipairs(self.session.menu.rows) do
        local obscured = row.disabled and row.assignedPortal == nil
        if row.obscured ~= obscured then
            row.obscured = obscured
            self:InvalidateVisualLayout()
        end
    end
end

function PvmPortal:GetDisplayName(row)
    if row.obscured then
        return "???"
    end
    return PvmPortalMenu.GetDisplayName(self, row)
end

function PvmPortal:GetDescription(row)
    if row.obscured then
        return row.destination.lockedDescription
    end
    return PvmPortalMenu.GetDescription(self, row)
end

function PvmPortal:GetSlotStyle(row, hovered)
    if row.assignedPortal ~= nil then
        return self.definition.slotStyles.assigned
    end
    return ModelSlotMenu.GetSlotStyle(self, row, hovered)
end

function PvmPortal:UpdateVisuals(layout, hovered)
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

function PvmPortal:Match(snapshot)
    local entries = self.definition.entries
    local added = false
    for _, row in ipairs(snapshot.nativeRows) do
        for name in pairs(row.labels) do
            if entries[name] == nil then
                entries[name] = {
                    placeholderText = "?",
                    placeholderFont = id.Font.NOTOSANS_BOLD_50,
                    nameOverride = name,
                    description = "",
                    lockedDescription = "",
                }
                added = true
            end
        end
    end
    if added then
        self:ConfigureDestinations(entries)
    end

    local match, reason = PvmPortalMenu.Match(self, snapshot)

    if match == nil then
        local lines = { "Destination matching failed: " .. tostring(reason), "Native destinations:" }

        for _, row in ipairs(snapshot.nativeRows) do
            lines[#lines + 1] = "  " .. matcher.LabelSummary(row.labels)
        end

        self:ReportMatch(lines)
    end

    return match, reason
end

local function npc(npcID, animID, distance, offset)
    return {
        npcID = npcID,
        animID = animID,
        viewDistance = distance or 1800,
        modelOffset = {
            x = 0,
            y = offset or 100,
        },
    }
end

function PvmPortal:Define()
    local entries = {
        ["Airut peninsula"]            = npc(id.NPC.HOTM_SLAYER_CREATURE_MELEE, id.Seq.HOTM_TUSKA_HARBINGER_KNUCKLES_IDLE, 800, 70),
        ["Amascut"]                     = npc(id.NPC.AMASCUT_BOSS, id.Seq.AMASCUT_BOSS_IDLE, 1000, 250),
        ["Arch-Glacor"]                 = npc(id.NPC.EGWD_WEN_BOSS, id.Seq.EGWD_WEN_BOSS_GLACOR_IDLE, 7000, 100),
        ["Araxxi"]                      = npc(id.NPC.SB_BOSS2, id.Seq.SB_SPIDER_BOSS_02_READY, 2400, 70),
        ["Barrows Brothers"]            = npc(id.NPC.BARROWS_DHAROK, id.Seq.BARROW_DHAROK_READY, 650, 120),
        ["Bork"]                        = npc(id.NPC.DSD_BORK, id.Seq.QUEST_DSD_ORK_BOSS_READY, 1300, 120),
        ["Commander Zilyana"]           = npc(id.NPC.GODWARS_SARADOMIN_AVATAR, id.Seq.GODWARS_SARADOMIN_READY, 700, 150),
        ["Corporeal Beast"]             = npc(id.NPC.SUM2_SPIRIT_BEAST_CORPOREAL, id.Seq.SUM1_SPIRIT_BEAST_READY, 2500, 80),
        ["Croesus"]                     = npc(id.NPC.EGWD_BIK_BOSS, id.Seq.EGWD_BIK_BOSS_CROESUS_IDLE, 6000, 80),
        ["Dagannoth Kings"]             = npc(id.NPC.DAGCAVE_MELEE_BOSS, id.Seq.DAGANNOTH_KINGS_2016_UPDATE_MELEE_IDLE, 1800, 90),
        ["Dragonkin Laboratory"]        = npc(id.NPC.DUNGEON_DRAGONFORT_BOSS3, id.Seq.DUNGEON_WILDERNESS_ASTELLARN_IDLE, 2500, 40),
        ["Flesh-hatcher Mhekarnahz"]    = npc(id.NPC.STALKER_BOSS, id.Seq.STALKER_2022_IDLE, 3000, 80),
        ["Fort Forinthry (Zemouregal & Vorkath)"] = npc(id.NPC.FORT_BOSS_VORKATH, id.Seq.DRAGON_BOSS_VORKATH_IDLE, 2000, 60),
        ["General Graardor"]            = npc(id.NPC.GODWARS_BANDOS_AVATAR, id.Seq.GODWARS_GENERAL_GRAARDOR_2012_READY, 1500),
        ["Ghrazi Blood Knights"]        = npc(id.NPC.BLOOD_KNIGHT_BOSS_LORD_GHRAZI, id.Seq.GHRAZI_LORD_IDLE, 1100, 170),
        ["Giant Mole"]                  = npc(id.NPC.MOLE2_GIANT, id.Seq.MOLE2_GIANT_MOLE_IDLE, 1200, 50),
        ["Glacor cavern"]               = npc(id.NPC.MAH5_GLACOR, id.Seq.MAH5_GLACOR_READY, 1200, 80),
        ["Gregorovic"]                  = npc(id.NPC.GWD2_SLISKE_BOSS, id.Seq.GWD2_SLISKE_GENERAL_IDLE, 600, 170),
        ["Har-Aken"]                    = npc(id.NPC.BPETS_HARAKEN, id.Seq.BOSSPETS_HARAKEN_IDLE, 400, 70),
        ["Helwyr"]                      = npc(id.NPC.GWD2_SEREN_BOSS, id.Seq.GWD2_SEREN_GENERAL_IDLE, 1600, 80),
        ["Ivar"]                        = npc(id.NPC.WENDLE_GIANT_BOSS, id.Seq.GIANT_STANDARD_IDLE, 800, 170),
        ["Kalphite King"]               = npc(id.NPC.KK_KING_MELEE, id.Seq.KK_KALPHITE_KING_READY, 2000, 60),
        ["Kalphite Queen"]              = npc(id.NPC.KALPHITE_QUEEN, id.Seq.KALPHITE_QUEEN_2014_READY, 1200, 60),
        ["Kerapac"]                     = npc(id.NPC.EGWD_JAS_BOSS, id.Seq.EGWD_JAS_BOSS_KERAPAC_IDLE_STAFF, 1200, 110),
        ["King Black Dragon"]           = npc(id.NPC.KING_DRAGON, id.Seq.DRAGON_UPDATE_2012_KBD_READY, 2400, 90),
        ["Kree'arra"]                   = npc(id.NPC.GODWARS_ARMADYL_AVATAR, id.Seq.GODWARS_KREE_ARRA_2012_READY, 1600, 100),
        ["K'ril Tsutsaroth"]            = npc(id.NPC.GODWARS_ZAMORAK_AVATAR, id.Seq.RAND_BOSS_DEMON_GHAN_KO_READY, 1800, 140),
        ["Legiones"]                    = npc(id.NPC.ASC_LEGIO_1, id.Seq.ASC_LEGIO_IDLE, 600, 200),
        ["Mazcab"]                      = npc(id.NPC.RAID1_BEASTMASTER, id.Seq.TUSKA_RAIDS_BEASTMASTER_IDLE, 2000, 80),
        ["Nex"]                         = npc(id.NPC.GODWARS2_ZAROS_AVATAR, id.Seq.GODWARS_NEX_2012_READY, 800, 150),
        ["Queen Black Dragon"]          = npc(id.NPC.QBD2_BOSS, id.Seq.QBD2_QBD_READY, 6000, 40),
        ["Raksha"]                      = npc(id.NPC.DINO_BOSS, id.Seq.DINO_BOSS_IDLE, 3200, 130),
        ["Rasial's Citadel"]            = npc(id.NPC.RASIAL_FORT_CHAMBER_RASIAL, id.Seq.COMBAT_2012_CASUAL_UNARMED_IDLE, 600, 190),
        ["Rex Matriarchs"]              = npc(id.NPC.REXKINGS_MELEE_BOSS, id.Seq.BIG_GAME_TYRANNOSAUR_IDLE, 2600, 170),
        ["Sanctum of Rebirth"]          = npc(id.NPC.RAID_REBIRTH1_SLAYER_MASTER_BOSS, id.Seq.RAID_REBIRTH1_SLAYER_MASTER_BOSS_IDLE, 1200, 140),
        ["Shadow Reef"]                 = npc(id.NPC.DUNGEON_ULTHVEN_BOSS3, id.Seq.DUNGEON_ULTHVEN_AMBASSADOR_IDLE, 1300, 190),
        ["Silverquill"]                 = npc(id.NPC.WENDLE_HEDGEHOG_BOSS, id.Seq.WENDLE_HEDGEHOG_BOSS_IDLE, 800, 40),
        ["Solak"]                       = npc(id.NPC.NATURE_BOSS_MAIN, id.Seq.NATURE_BOSS_SOLAK_IDLE, 2000, 160),
        ["Telos"]                       = npc(id.NPC.GWD2_SOLO_BOSS, id.Seq.GWD2_SOLO_BOSS_IDLE, 2000, 180),
        ["Temple of Aminishi"]          = npc(id.NPC.DUNGEON_AMINISHI_BOSS3_NORMAL, id.Seq.DUNGEON_AMINISHI_EVIL_SEIRYU_HEAD_IDLE, 6000, 60),
        ["Gate of Elidinis"]            = npc(id.NPC.ELIDINIS_BOSS, id.Seq.ELIDINIS_BOSS_IDLE, 3200, 150),
        ["The Magister"]                = npc(id.NPC.MENAPHOS_SLAYER_BOSS, id.Seq.MENAPHOS_OREB_IDLE, 500, 180),
        ["Zamorak"]                     = npc(id.NPC.EGWD_ZAMORAK_BOSS, id.Seq.ZAMORAK_IDLE, 2000, 210),
        ["Twin Furies"]                 = npc(id.NPC.GWD2_ZAM_BOSS_MELEE, id.Seq.GWD2_ZAMORAK_GENERAL_BLACK_IDLE, 1000, 140),
        ["TzKal-Zuk"]                   = npc(id.NPC.EGWD_FUL_BOSS_SHOWDOWN, id.Seq.EGWD_FUL_BOSS_IDLE, 2000, 200),
        ["TzTok-Jad"]                   = npc(id.NPC.TZHAAR_FIGHTCAVE_SWARM_BOSS, id.Seq.TZHAAR_UPDATE_TZTOK_JAD_BAK_READY, 2400),
        ["Tormented demons"]            = npc(id.NPC.LUC2_UNDEAD_DEMON_01_MELEE_PRAY_MELEE, id.Seq.LUC2_UNDEAD_DEMON_READY, 1500, 100),
        ["Vindicta & Gorvek"]           = npc(id.NPC.GWD2_ZAROS_BOSS_MOUNTED, id.Seq.GWD2_ZAROS_GENERAL_DRAGON_IDLE, 1200, 160),
        ["Vorago"]                      = npc(id.NPC.LRC2_BOSS, id.Seq.BOSS2_BOSS_IDLE, 3000, 150),
    }

    -- Edit both tooltip descriptions here; <br> adds a line break.
    -- Empty strings leave title-only tooltips. Assigned portals use "unlocked".
    local descriptions = {
        ["Airut peninsula"] = { unlocked = "", locked = "" },
        ["Amascut"] = { unlocked = "", locked = "" },
        ["Arch-Glacor"] = { unlocked = "", locked = "" },
        ["Araxxi"] = { unlocked = "", locked = "" },
        ["Barrows Brothers"] = { unlocked = "", locked = "" },
        ["Bork"] = { unlocked = "", locked = "" },
        ["Commander Zilyana"] = { unlocked = "", locked = "" },
        ["Corporeal Beast"] = { unlocked = "", locked = "" },
        ["Croesus"] = { unlocked = "", locked = "" },
        ["Dagannoth Kings"] = { unlocked = "", locked = "" },
        ["Dragonkin Laboratory"] = { unlocked = "", locked = "" },
        ["Flesh-hatcher Mhekarnahz"] = { unlocked = "", locked = "" },
        ["Fort Forinthry (Zemouregal & Vorkath)"] = { unlocked = "", locked = "" },
        ["General Graardor"] = { unlocked = "", locked = "" },
        ["Ghrazi Blood Knights"] = { unlocked = "", locked = "" },
        ["Giant Mole"] = { unlocked = "", locked = "" },
        ["Glacor cavern"] = { unlocked = "", locked = "" },
        ["Gregorovic"] = { unlocked = "", locked = "" },
        ["Har-Aken"] = { unlocked = "", locked = "" },
        ["Helwyr"] = { unlocked = "", locked = "" },
        ["Ivar"] = { unlocked = "", locked = "" },
        ["Kalphite King"] = { unlocked = "", locked = "" },
        ["Kalphite Queen"] = { unlocked = "", locked = "" },
        ["Kerapac"] = { unlocked = "", locked = "" },
        ["King Black Dragon"] = { unlocked = "", locked = "" },
        ["Kree'arra"] = { unlocked = "", locked = "" },
        ["K'ril Tsutsaroth"] = { unlocked = "", locked = "" },
        ["Legiones"] = { unlocked = "", locked = "" },
        ["Mazcab"] = { unlocked = "", locked = "" },
        ["Nex"] = { unlocked = "", locked = "" },
        ["Queen Black Dragon"] = { unlocked = "", locked = "" },
        ["Raksha"] = { unlocked = "", locked = "" },
        ["Rasial's Citadel"] = { unlocked = "", locked = "" },
        ["Rex Matriarchs"] = { unlocked = "", locked = "" },
        ["Sanctum of Rebirth"] = { unlocked = "", locked = "" },
        ["Shadow Reef"] = { unlocked = "", locked = "" },
        ["Silverquill"] = { unlocked = "", locked = "" },
        ["Solak"] = { unlocked = "", locked = "" },
        ["Telos"] = { unlocked = "", locked = "" },
        ["Temple of Aminishi"] = { unlocked = "", locked = "" },
        ["Gate of Elidinis"] = { unlocked = "", locked = "" },
        ["The Magister"] = { unlocked = "", locked = "" },
        ["Zamorak"] = { unlocked = "", locked = "" },
        ["Twin Furies"] = { unlocked = "", locked = "" },
        ["TzKal-Zuk"] = { unlocked = "", locked = "" },
        ["TzTok-Jad"] = { unlocked = "", locked = "" },
        ["Tormented demons"] = { unlocked = "", locked = "" },
        ["Vindicta & Gorvek"] = { unlocked = "", locked = "" },
        ["Vorago"] = { unlocked = "", locked = "" },
    }

    entries["Fort Forinthry (Zemouregal & Vorkath)"].nameOverride = "Zemouregal & Vorkath"

    -- Keep the configured boss name on cards and tooltips when a native alias matches.
    for name, entry in pairs(entries) do
        entry.nameOverride = entry.nameOverride or name
        local description = descriptions[name]
        if description ~= nil then
            entry.description = description.unlocked
            entry.lockedDescription = description.locked
        end
    end

    -- Some versions of the picker use the encounter name instead of its arrival
    -- location. Matching stays name-based when native rows are sorted or missing.
    for alias, name in pairs({
        ["Araxxor"] = "Araxxi",
        ["Araxyte hive"] = "Araxxi",
        ["Barrows"] = "Barrows Brothers",
        ["Corporeal beast"] = "Corporeal Beast",
        ["Giant mole"] = "Giant Mole",
        ["Fort Forinthry"] = "Fort Forinthry (Zemouregal & Vorkath)",
        ["Zemouregal & Vorkath"] = "Fort Forinthry (Zemouregal & Vorkath)",
        ["Ivar, King of Bones"] = "Ivar",
        ["Silverquill, the Dreadhog"] = "Silverquill",
        ["Solak, Guardian of the Grove"] = "Solak",
        ["The Ghrazi Blood Knights"] = "Ghrazi Blood Knights",
        ["Liberation of Mazcab"] = "Mazcab",
        ["Rasial"] = "Rasial's Citadel",
        ["The Shadow Reef"] = "Shadow Reef",
        ["The Gate of Elidinis"] = "Gate of Elidinis",
        ["The Zamorakian Undercity"] = "Zamorak",
        ["The Twin Furies"] = "Twin Furies",
        ["TokHaar Fight Kiln"] = "Har-Aken",
        ["TzHaar Fight Caves"] = "TzTok-Jad",
    }) do
        entries[alias] = entries[name]
    end

    self:ConfigureDestinations(entries)

    return {
        title = "Boss Portal Destination",
        columns = 5,
        rows = 3,
        scrollable = true,
        showLabels = true,
        overlayLabels = true,
        rightInset = 6,
        labelStyle = {
            font = id.Font.NOTOSANS_SEMIBOLD_11,
            backgroundRGBA = 0x140F0AA0,
            inset = 6, paddingX = 4, paddingY = 2,
        },
        slotStyles = {
            normal = modelSlotStyles.normal,
            hovered = modelSlotStyles.hovered,
            disabled = {
                modelAlpha = 0.4, modelBrightness = -10000.00,
                backgroundAlpha = 0.4, backgroundRGB = 0xC0C0C0,
                labelAlpha = 0.6, labelRGBA = 0x9D978AFF,
            },
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

return PvmPortal
