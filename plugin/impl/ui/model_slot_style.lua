local ModelSlotStyle = {}
local highlightBrightness = 1.75
local unfocusedBrightness = 0.2

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
    local highlighted = slot.highlightLighting == true
    local previouslyHighlighted = slot.appliedHighlight == true
    local unfocused = slot.unfocusedLighting == true
    if previous == style and highlighted == previouslyHighlighted and unfocused == (slot.appliedUnfocused == true) then
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
    if highlighted then
        brightness = math.max(1, brightness) * highlightBrightness
    elseif unfocused and brightness > 0 then
        brightness = brightness * unfocusedBrightness
    end
    local previousBrightness = slot.appliedBrightness or 1
    if slot.model ~= nil and (brightness ~= previousBrightness or highlighted ~= previouslyHighlighted) then
        local environment = slot.model.environment
        if slot.modelLighting == nil then
            local sun = environment.sunRGB
            -- Native vectors can be views into the temporary environment wrapper.
            -- Keep only scalar values so restoration never depends on its lifetime.
            slot.modelLighting = {
                ambient = environment.ambient,
                contrast = environment.contrast,
                bloomScale = environment.bloomScale,
                sunRGB = { x = sun.x, y = sun.y, z = sun.z },
            }
        end
        for _, property in ipairs({ "ambient", "contrast", "bloomScale" }) do
            environment[property] = slot.modelLighting[property] * brightness
        end
        local sun = slot.modelLighting.sunRGB
        environment.sunRGB = highlighted and Vector3.new(1, 0.8, 0.65) or Vector3.new(sun.x, sun.y, sun.z)
        slot.model.environment = environment
    end

    slot.appliedStyle, slot.appliedHighlight, slot.appliedBrightness = style, highlighted, brightness
    slot.appliedUnfocused = unfocused
    if slot.modelParts ~= nil then
        for _, part in ipairs(slot.modelParts) do
            part.highlightLighting = highlighted
            part.unfocusedLighting = unfocused
            ModelSlotStyle.Apply(part, style)
        end
    end
end

-- Reapply only the lighting when API ownership changes, even if the style is cached.
function ModelSlotStyle.SetHighlighted(slot, highlighted, unfocused)
    slot.highlightLighting = highlighted
    slot.unfocusedLighting = unfocused == true
    if slot.appliedStyle ~= nil then
        ModelSlotStyle.Apply(slot, slot.appliedStyle)
    end
end

return ModelSlotStyle
