local text = require("impl/text")
local aliases = {}

-- Read the original comma-separated format as well as escaped, individually registered aliases.
function aliases.Parse(value)
    local result = {}
    local escaped = value:sub(1, 3) == "v2\n"

    for line in value:gmatch("[^\r\n]+") do
        local code, names = line:match("^([ABCD][IJKL][PQRS])=(.*)$")

        if code ~= nil then
            result[code] = result[code] or {}

            for name in names:gmatch("[^,]+") do
                if escaped then
                    name = name:gsub("%%(%x%x)", function(hex)
                        return string.char(tonumber(hex, 16))
                    end)
                end

                name = text.Clean(name)

                if name ~= "" then
                    result[code][#result[code] + 1] = name
                end
            end
        end
    end

    return result
end

function aliases.Serialize(entries)
    local lines = {}

    for code, names in pairs(entries) do
        local encoded = {}

        for _, name in ipairs(names) do
            encoded[#encoded + 1] = name:gsub("[%%,\r\n]", function(character)
                return string.format("%%%02X", character:byte())
            end)
        end

        if #encoded > 0 then
            lines[#lines + 1] = code .. "=" .. table.concat(encoded, ",")
        end
    end

    table.sort(lines)
    return "v2\n" .. table.concat(lines, "\n")
end

return aliases
