-- This file contains definitions of backgrounds used in the teleport interfaces
-- 
-- Each entry of this table has the following fields
-- - width: The width of the image
-- - height: The height of the image
-- - image (only if sprites is not defined): A Plugin.resources.backgrounds resource object
-- - sprites (only if image is not defined): A 2D Array of Sprite IDs. Use {{ id.Sprite.Something }} if the sprite contains the full image
-- - crop (optional): x, y, width and height of the crop area

return {
    pirate_islands = {
        image = Plugin.resources.backgrounds.pirate_islands,
        width = 805,
        height = 785,
    },
    menaphos = {
        image = Plugin.resources.backgrounds.menaphos,
        width = 1024,
        height = 882,
    },
    cityOfUm = {
        image = Plugin.resources.backgrounds.city_of_um,
        width = 888,
        height = 852,
    },
    wilderness = {
        image = Plugin.resources.backgrounds.wilderness,
        width = 1024,
        height = 872,
    },
    morytaniaSouth = {
        image = Plugin.resources.backgrounds.southern_morytania,
        width = 851,
        height = 667,
    },
    runescapeSurface = {
        sprites = {{id.Sprite.RS3_LODESTONE_WORLDMAP_ACTIVE}},
        width = 560,
        height = 320,
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
        crop = { x = 210, y = 7, width = 123, height = 135 }
    }
}
