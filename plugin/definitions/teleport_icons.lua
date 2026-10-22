local teleportIcons = {
    menaphosFactions = {
        imperial = {
            normal = {sprite = id.Sprite.MENAPHOS_ICON_FACTION_IMPERIAL_0},
            hovered = {sprite = id.Sprite.MENAPHOS_ICON_FACTION_IMPERIAL_1},
            size = 32,
            shadowColor = 0x00000099,
            shadowColorHovered = 0x00000099
        },
        merchant = {
            normal = {sprite = id.Sprite.MENAPHOS_ICON_FACTION_MERCHANT_0},
            hovered = {sprite = id.Sprite.MENAPHOS_ICON_FACTION_MERCHANT_1},
            size = 32,
            shadowColor = 0x00000099,
            shadowColorHovered = 0x00000099
        },
        port = {
            normal = {sprite = id.Sprite.MENAPHOS_ICON_FACTION_PORT_0},
            hovered = {sprite = id.Sprite.MENAPHOS_ICON_FACTION_PORT_1},
            size = 32,
            shadowColor = 0x00000099,
            shadowColorHovered = 0x00000099
        },
        worker = {
            normal = {sprite = id.Sprite.MENAPHOS_ICON_FACTION_WORKER_0},
            hovered = {sprite = id.Sprite.MENAPHOS_ICON_FACTION_WORKER_1},
            size = 32,
            shadowColor = 0x400000FF,
            shadowColorHovered = 0x400000FF,
        },
    },
    elfClans = {
        amlodd = {
            image = "elfClans/amlodd", imageWidth = 47, imageHeight = 75,
            size = 40, shadowColorHovered = 0x00000099,
        },
        cadarn = {
            image = "elfClans/cadarn", imageWidth = 62, imageHeight = 75,
            size = 40, shadowColorHovered = 0x00000099,
        },
        crwys = {
            image = "elfClans/crwys", imageWidth = 56, imageHeight = 80,
            size = 40, shadowColorHovered = 0x00000099,
        },
        hefin = {
            image = "elfClans/hefin", imageWidth = 51, imageHeight = 75,
            size = 40, shadowColorHovered = 0x00000099,
        },
        iorwerth = {
            image = "elfClans/iorwerth", imageWidth = 75, imageHeight = 70,
            size = 40, shadowColorHovered = 0x00000099,
        },
        ithell = {
            image = "elfClans/ithell", imageWidth = 69, imageHeight = 68,
            size = 40, shadowColorHovered = 0x00000099,
        },
        meilyr = {
            image = "elfClans/meilyr", imageWidth = 45, imageHeight = 78,
            size = 40, shadowColorHovered = 0x00000099,
        },
        trahaearn = {
            image = "elfClans/trahaearn", imageWidth = 48, imageHeight = 75,
            size = 40, shadowColorHovered = 0x00000099,
        },
    },
    elfcityTeleport = {
        [0] = { -- Light Blue
            normal = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_0_0},
            hovered = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_0_1},
            size = 34,
        },
        [1] = { -- Turquoise 
            normal = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_1_0},
            hovered = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_1_1},
            size = 34,
        },
        [2] = { -- Blue-Green
            normal = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_2_0},
            hovered = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_2_1},
            size = 34,
        },
        [3] = { -- Light Purple
            normal = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_3_0},
            hovered = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_3_1},
            size = 34,
        },
        [4] = { -- Yellow
            normal = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_4_0},
            hovered = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_4_1},
            size = 34,
        },
        [5] = { -- Green
            normal = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_5_0},
            hovered = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_5_1},
            size = 34,
        },
        [6] = { -- Magenta
            normal = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_6_0},
            hovered = {sprite = id.Sprite.ELFCITY_ICON_TELEPORT_6_1},
            size = 34,
        },
    },
    obelisk = {
        objectID = id.Obj.WILDY_EVENTS_REWARDS_PORTABLE_OBELISK,
        size = 40,
        shadowColor = 0x00000066,
        shadowColorHovered = 0xFF33FFCC
    },
    drakansMedallion = {
        objectID = id.Obj.MYQ5_DRAKAN_PENDANT,
        size = 40,
        shadowColorHovered = 0x9A4521CC
    },
    underworldTeleport = {
        sprite = id.Sprite.SPELL_ICON_NECROMANCY_TELEPORT_UNDERWORLD_HUB,
        size = 40,
        shadowColor = 0x9A4521FF,
        shadowColorHovered = 0x9A4521CC
    },
    ungaelTeleport = {
        sprite = id.Sprite.SPELL_ICON_NECROMANCY_TELEPORT_UNGAEL,
        size = 40,
        shadowColor = 0x9A4521FF,
        shadowColorHovered = 0x9A4521CC
    },
    relicOfHet = {
        objectID = id.Obj.MENAPHOS_REPUTATION_CONSUMABLE_HET,
        size = 32,
        shadowColorHovered = 0xFAF45FCC
    },
    castleWarsCape = {
        objectID = id.Obj.CASTLEWARS_CAPE_FLAG,
        size = 40,
        shadowColorHovered = 0x9B8F8DCC
    },
    warForgeShield = {
        objectID = id.Obj.ARCH_TOWER_COWER_SHIELD,
        size = 40,
        shadowColorHovered = 0xC07529CC
    },
    fistOfGuthixOrb = {
        objectID = id.Obj.HVH_TELEPORT_TABLET,
        size = 40,
        shadowColorHovered = 0x7799B9CC
    },
    corporealBeast = {
        objectID = id.Obj.SUM2_SPIRIT_SHIELD_ELYSIAN,
        size = 32,
        shadowColorHovered = 0x376C83CC
    },
    tearsOfGuthix = {
        objectID = id.Obj.WILDY_EVENTS_GENERAL_SKILL_HUNTER_BUTTERFLY,
        size = 32,
        shadowColorHovered = 0x4B5075CC
    },
    trollInvasion = {
        objectID = id.Obj.SLAYERGUIDE_TROLL,
        size = 40,
        shadowColorHovered = 0x3C3737CC
    },
    dice = {
        objectID = id.Obj.PENG_POW_DICE,
        size = 32,
        shadowColorHovered = 0xAAAAAACC
    },
    horn = {
        objectID = id.Obj.BARBASSAULT_HORN_COLLECTOR,
        size = 40,
        shadowColorHovered = 0xAAAAAACC
    },
    sickle = {
        objectID = id.Obj.MYQ4_ENCHANT_BLESS_SILVER_SICKLE_EMERALD,
        size = 32,
        shadowColorHovered = 0x8E8282CC
    },
    squid = {
        objectID = id.Obj.PENG_POW_SQUID,
        size = 40,
        shadowColorHovered = 0x8E8282CC
    },
    shiftingTombs = {
        sprite = id.Sprite.MENAPHOS_TOMBS_ICON_SARCOPHAGUS,
        size = 32,
        shadowColor = 0x000000FF,
        shadowColorHovered = 0x9A4521CC
    },
    sophanemSlayerDungeon = {
        normal = {sprite = id.Sprite.RS3_ICON_LEAGUES_RELIC_TELEPORT_SLAYER_LOCKED},
        hovered = {sprite = id.Sprite.RS3_ICON_LEAGUES_RELIC_TELEPORT_SLAYER_ACTIVE},
        size = 32,
        shadowColor = 0x9A4521FF,
        shadowColorHovered = 0x9A4521C
    },
    bigBookOPiracy = {
        objectID = id.Obj.FEVER_PIRACY_BOOK,
        size = 40
    },

    nextArrow = {
        sprite = id.Sprite.RIGHTARROW,
        size = 35,
        shadowColor = 0x00000099,
    },
    prevArrow = {
        sprite = id.Sprite.LEFTARROW,
        size = 35,
        shadowColor = 0x00000099
    },



}

return teleportIcons
