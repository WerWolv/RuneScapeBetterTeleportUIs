-- Menu modules may export one concrete class or a list of page classes.
local modules = {
    require("menus/wilderness_obelisks"),
    require("menus/wilderness_sword"),
    require("menus/drakans_medallion"),
    require("menus/ring_of_duelling"),
    require("menus/games_necklace"),
    require("menus/combat_bracelet"),
    require("menus/crystal_teleport_seed"),
    require("menus/crystal_teleport_seed_prifddinas"),
    require("menus/passing_bracelet"),
    require("menus/underworld_grimoire"),
    require("menus/leelas_favour"),
    require("menus/big_book_o_piracy"),
    require("menus/globetrotter_arm_guards"),
    require("menus/daves_spellbook"),
    require("menus/tirannwn_quiver"),
    require("menus/desert_amulet"),
    require("menus/enchanted_lyre"),
    require("menus/passage_of_the_abyss"),
    require("menus/amulet_of_glory"),
    require("menus/ring_of_respawn"),
    require("menus/skills_necklace"),
    require("menus/delvers_anklet"),
    require("menus/dungeoneering_cape"),
    require("menus/fairy_rings"),
    (require("menus/slayer_cape")),
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
