local InputClipping = {}
local fields = { "emptyTextRGBA", "caretRGBA", "errorCaretRGBA", "selectionHighlightRGBA" }

-- Native input content can draw outside an ancestor's viewport. Suppress its
-- visual content while clipped, preserving focus, the draft and the field frame.
function InputClipping.Update(control, clipped)
    local root = control.input.root

    if clipped and control.inputAppearance == nil then
        local saved = { textRGBA = root.text.rgba, shadowed = root.text.isShadowed }
        control.inputAppearance = saved

        for _, field in ipairs(fields) do
            saved[field] = root[field]
            root[field] = 0
        end

        root.text.rgba = 0
        root.text.isShadowed = false
    elseif not clipped and control.inputAppearance ~= nil then
        local saved = control.inputAppearance

        for _, field in ipairs(fields) do
            root[field] = saved[field]
        end

        root.text.rgba = saved.textRGBA
        root.text.isShadowed = saved.shadowed
        control.inputAppearance = nil
    end
end

return InputClipping
