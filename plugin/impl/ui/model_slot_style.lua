local ModelSlotStyle = {}

local properties = {
    { "model", "alpha", "modelAlpha" },
    { "background", "alpha", "backgroundAlpha" },
    { "background", "rgb", "backgroundRGB" },
    { "label", "alpha", "labelAlpha" },
    { "label", "rgba", "labelRGBA" },
    { "placeholder", "alpha", "modelAlpha" },
    { "placeholder", "rgba", "labelRGBA" },
}

-- Styles are stable definition tables. Apply changed properties directly because
-- native layer opacity does not propagate to child artwork.
function ModelSlotStyle.Apply(slot, style)
    local previous = slot.appliedStyle
    if previous == style then
        return
    end

    for _, property in ipairs(properties) do
        local control = slot[property[1]]
        local value = style[property[3]]
        if control ~= nil and value ~= nil and (previous == nil or previous[property[3]] ~= value) then
            control[property[2]] = value
        end
    end

    local brightness = style.modelBrightness or 1
    local previousBrightness = previous and previous.modelBrightness or 1
    if slot.model ~= nil and brightness ~= previousBrightness then
        local environment = slot.model.environment
        slot.modelLighting = slot.modelLighting or {
            ambient = environment.ambient,
            contrast = environment.contrast,
            bloomScale = environment.bloomScale,
        }
        for property, value in pairs(slot.modelLighting) do
            environment[property] = value * brightness
        end
        slot.model.environment = environment
    end

    slot.appliedStyle = style
end

return ModelSlotStyle
