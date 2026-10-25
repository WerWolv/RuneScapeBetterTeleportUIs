local description = {}

description.SKILL = {
    AGILITY         = 16038,
    ARCHAEOLOGY     = 16039,
    ATTACK          = 16040,
    CONSTITUTION    = 16041,
    CONSTRUCTION    = 16042,
    COOKING         = 16043,
    CRAFTING        = 16044,
    DEFENCE         = 16045,
    DIVINATION      = 16046,
    DUNGEONEERING   = 16047,
    FARMING         = 16048,
    FIREMAKING      = 16049,
    FISHING         = 16050,
    FLETCHING       = 16051,
    HERBLORE        = 16052,
    HUNTING         = 16053,
    INVENTION       = 16054,
    MAGIC           = 16055,
    MINING          = 16056,
    PRAYER          = 16057,
    RANGED          = 16058,
    RUNECRAFTING    = 16059,
    SLAYER          = 16060,
    SMITHING        = 16061,
}

local skillInfo = {
    [description.SKILL.AGILITY]         = { name = "Agility",       color = 0x8AA8E8},
    [description.SKILL.ARCHAEOLOGY]     = { name = "Archaeology",   color = 0xD6B784},
    [description.SKILL.ATTACK]          = { name = "Attack",        color = 0xE87575},
    [description.SKILL.CONSTITUTION]    = { name = "Constitution",  color = 0xEF8C8C},
    [description.SKILL.CONSTRUCTION]    = { name = "Construction",  color = 0xD6B98C},
    [description.SKILL.COOKING]         = { name = "Cooking",       color = 0xC995DF},
    [description.SKILL.CRAFTING]        = { name = "Crafting",      color = 0xD4AD7D},
    [description.SKILL.DEFENCE]         = { name = "Defence",       color = 0x85B5E8},
    [description.SKILL.DIVINATION]      = { name = "Divination",    color = 0xC695E8},
    [description.SKILL.DUNGEONEERING]   = { name = "Dungeoneering", color = 0xD6A879},
    [description.SKILL.FARMING]         = { name = "Farming",       color = 0x93C978},
    [description.SKILL.FIREMAKING]      = { name = "Firemaking",    color = 0xF2A65A},
    [description.SKILL.FISHING]         = { name = "Fishing",       color = 0x82C6DF},
    [description.SKILL.FLETCHING]       = { name = "Fletching",     color = 0x78C9B5},
    [description.SKILL.HERBLORE]        = { name = "Herblore",      color = 0x82C982},
    [description.SKILL.HUNTING]         = { name = "Hunter",        color = 0xC7AD8B},
    [description.SKILL.INVENTION]       = { name = "Invention",     color = 0xE8CB75},
    [description.SKILL.MAGIC]           = { name = "Magic",         color = 0x91B6EF},
    [description.SKILL.MINING]          = { name = "Mining",        color = 0xACB9CC},
    [description.SKILL.PRAYER]          = { name = "Prayer",        color = 0xE8DDA5},
    [description.SKILL.RANGED]          = { name = "Ranged",        color = 0x95C878},
    [description.SKILL.RUNECRAFTING]    = { name = "Runecrafting",  color = 0xDDD4A3},
    [description.SKILL.SLAYER]          = { name = "Slayer",        color = 0xCE9696},
    [description.SKILL.SMITHING]        = { name = "Smithing",      color = 0xB5BFD0},
}

-- Adds a skill requirement description
function description.LevelRequirement(level, skill)
    local info = assert(skillInfo[skill], "Unknown skill sprite: " .. tostring(skill))
    return string.format("- Level <col=ffffff>%d</col> <sprite=%d><col=%06x>%s</col><br>",
        level, skill, info.color, info.name)
end

-- Adds a world location description
function description.Location(name)
    return string.format("- <sprite=%d> <col=ffffff>%s</col><br>",
        id.Sprite.ABILITY_ICON_TOOLTIP_TARGET_AOE,
        name
    )
end

return description
