-- Shared defaults; concrete menus may supply their own styles and state selection.
return {
    normal = {
        modelAlpha = 1, modelBrightness = 1,
        backgroundAlpha = 1, backgroundRGB = 0xC0C0C0,
        labelAlpha = 1, labelRGBA = 0xFFE3A3FF,
    },
    hovered = {
        modelAlpha = 1, modelBrightness = 1,
        backgroundAlpha = 1, backgroundRGB = 0xFFFFFF,
        labelAlpha = 1, labelRGBA = 0xFFFFFFFF,
    },
    disabled = {
        modelAlpha = 0.4, modelBrightness = 1,
        backgroundAlpha = 0.4, backgroundRGB = 0xC0C0C0,
        labelAlpha = 0.6, labelRGBA = 0x9D978AFF,
    },
    label = {
        font = id.Font.MUSEO_SANS_11PT_REGULAR,
        backgroundRGBA = 0x000000FF,
        inset = 0, paddingX = 4, paddingY = 2,
    },
}
