local text = {}

function text.StripFormatting(value)
    return ((value or ""):gsub("<[^>]*>", ""))
end

function text.Trim(value)
    return ((value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function text.Clean(value)
    return text.Trim(text.StripFormatting(value))
end

function text.IsBlank(value)
    return value == nil or value:match("^%s*$") ~= nil
end

-- Native option numbers remain shortcut keys even when their artwork is rearranged.
function text.Hotkey(name)
    return name:match("^%s*(%d+)%.")
end

return text
