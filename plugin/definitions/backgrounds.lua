-- This file contains definitions of backgrounds used in the teleport interfaces
-- 
-- Each entry of this table has the following fields
-- - width: The width of the image
-- - height: The height of the image
-- - image (only if sprites is not defined): File name stored under resources/backgrounds
-- - sprites (only if image is not defined): A 2D Array of Sprite IDs. Use {{ id.Sprite.Something }} if the sprite contains the full image
-- - crop (optional): x, y, width and height of the crop area

return {
    pirate_islands = {
        image = "pirate_islands",
        width = 805,
        height = 785,
    },
    menaphos = {
        image = "menaphos",
        width = 1024,
        height = 882,
    },
    city_of_um = {
        image = "city_of_um",
        width = 888,
        height = 852,
    },
    wilderness = {
        image = "wilderness",
        width = 1024,
        height = 872,
    },
    wildernessWest = {
        image = "wilderness",
        width = 1024,
        height = 872,
        crop = { x = 0, y = 80, width = 512, height = 792 }
    },
    morytaniaSouth = {
        image = "southern_morytania",
        width = 851,
        height = 667,
    },
    runescape_surface_south = {
        sprites = {
            {id.Sprite.THAS_GIELINOR_MAP_0, id.Sprite.THAS_GIELINOR_MAP_1},
            {id.Sprite.THAS_GIELINOR_MAP_2, id.Sprite.THAS_GIELINOR_MAP_3},
            {id.Sprite.THAS_GIELINOR_MAP_4, id.Sprite.THAS_GIELINOR_MAP_5},
        },
        width = 512,
        height = 384,
        crop = { x = 97, y = 129, width = 293, height = 174 }
    },
    runescape_surface = {
        sprites = {
            {id.Sprite.THAS_GIELINOR_MAP_0, id.Sprite.THAS_GIELINOR_MAP_1},
            {id.Sprite.THAS_GIELINOR_MAP_2, id.Sprite.THAS_GIELINOR_MAP_3},
            {id.Sprite.THAS_GIELINOR_MAP_4, id.Sprite.THAS_GIELINOR_MAP_5},
        },
        width = 512,
        height = 384,
        crop = { x = 10, y = 33, width = 491, height = 270 }
    },
    tirannwn = {
        sprites = {{ id.Sprite.ELFCITY_TELEPORT_MAP}},
        width = 496,
        height = 294,
        crop = { x = 196, y = 0, width = 300, height = 270 }
    },
    prifddinas = {
        sprites = {{ id.Sprite.ELFCITY_TELEPORT_MAP}},
        width = 496,
        height = 294,
        crop = { x = 210, y = 7, width = 121, height = 134 }
    }
}
