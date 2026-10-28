local description = {}

description.SKILL = {
    AGILITY         = id.Sprite.HITMARK_ICON_SKILL_AGILITY,
    ARCHAEOLOGY     = id.Sprite.HITMARK_ICON_SKILL_ARCHAEOLOGY,
    ATTACK          = id.Sprite.HITMARK_ICON_SKILL_ATTACK,
    CONSTITUTION    = id.Sprite.HITMARK_ICON_SKILL_CONSTITUTION,
    CONSTRUCTION    = id.Sprite.HITMARK_ICON_SKILL_CONSTRUCTION,
    COOKING         = id.Sprite.HITMARK_ICON_SKILL_COOKING,
    CRAFTING        = id.Sprite.HITMARK_ICON_SKILL_CRAFTING,
    DEFENCE         = id.Sprite.HITMARK_ICON_SKILL_DEFENCE,
    DIVINATION      = id.Sprite.HITMARK_ICON_SKILL_DIVINATION,
    DUNGEONEERING   = id.Sprite.HITMARK_ICON_SKILL_DUNGEONEERING,
    FARMING         = id.Sprite.HITMARK_ICON_SKILL_FARMING,
    FIREMAKING      = id.Sprite.HITMARK_ICON_SKILL_FIREMAKING,
    FISHING         = id.Sprite.HITMARK_ICON_SKILL_FISHING,
    FLETCHING       = id.Sprite.HITMARK_ICON_SKILL_FLETCHING,
    HERBLORE        = id.Sprite.HITMARK_ICON_SKILL_HERBLORE,
    HUNTING         = id.Sprite.HITMARK_ICON_SKILL_HUNTING,
    INVENTION       = id.Sprite.HITMARK_ICON_SKILL_INVENTION,
    MAGIC           = id.Sprite.HITMARK_ICON_SKILL_MAGIC,
    MINING          = id.Sprite.HITMARK_ICON_SKILL_MINING,
    PRAYER          = id.Sprite.HITMARK_ICON_SKILL_PRAYER,
    RANGED          = id.Sprite.HITMARK_ICON_SKILL_RANGED,
    RUNECRAFTING    = id.Sprite.HITMARK_ICON_SKILL_RUNECRAFTING,
    SLAYER          = id.Sprite.HITMARK_ICON_SKILL_SLAYER,
    SMITHING        = id.Sprite.HITMARK_ICON_SKILL_SMITHING
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

function description.CombatLevel(level)
    return string.format("- Level <col=ffffff>%d</col>  <sprite=9286> <col=85B5E8>Combat</col><br>", level)
end

-- Adds a world location description
function description.Location(name)
    return string.format("- <sprite=%d> <col=ffffff>%s</col><br>",
        id.Sprite.TOPLEVEL_WORLDMAP_BUTTON_0,
        name
    )
end

function description.Text(text)
    return string.format("- %s<br>", text)
end

return description
