local function definition(path)
    local module, _ = require("menus/" .. path)

    return module
end

-- Menu modules may export one concrete class or a list of page classes.
local modules = {
    definition("maps/wilderness_obelisks"),
    definition("maps/wilderness_sword"),
    definition("maps/drakans_medallion"),
    definition("maps/ring_of_duelling"),
    definition("maps/games_necklace"),
    definition("maps/combat_bracelet"),
    definition("maps/crystal_teleport_seed"),
    definition("maps/crystal_teleport_seed_prifddinas"),
    definition("maps/passing_bracelet"),
    definition("maps/underworld_grimoire"),
    definition("maps/leelas_favour"),
    definition("maps/big_book_o_piracy"),
    definition("maps/globetrotter_arm_guards"),
    definition("maps/daves_spellbook"),
    definition("maps/desert_amulet"),
    definition("maps/enchanted_lyre"),
    definition("maps/amulet_of_glory"),
    definition("maps/ring_of_respawn"),
    definition("maps/skills_necklace"),
    definition("maps/delvers_anklet"),
    definition("maps/dungeoneering_cape"),

    definition("enhancements/fairy_rings"),
    definition("enhancements/tirannwn_quiver"),

    definition("special/passage_of_the_abyss"),
    definition("special/slayer_cape"),
}

local registry = {}
for _, exported in ipairs(modules) do
    if type(exported.New) == "function" then
        registry[#registry + 1] = exported
    else
        for _, class in ipairs(exported) do
            -- Pages exported together share placement while navigating an open menu.
            class.pageGroup = exported
            registry[#registry + 1] = class
        end
    end
end

return registry
