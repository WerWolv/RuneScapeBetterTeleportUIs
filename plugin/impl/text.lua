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

-- Partial-word edit distance: internal gaps, extra letters, replacements and
-- adjacent swaps all consume the budget. Unentered leading/trailing text is free.
local function wordScore(value, word, limit)
    local distance = 0

    if not value:find(word, 1, true) then
        if limit == 0 then
            return -math.huge
        end

        local previous, beforePrevious = {}, nil

        for j = 0, #value do
            previous[j] = 0
        end

        for i = 1, #word do
            local current = { [0] = i }
            distance = i

            for j = 1, #value do
                local cost = word:byte(i) == value:byte(j) and 0 or 1
                current[j] = math.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)

                if i > 1 and j > 1 and word:byte(i) == value:byte(j - 1)
                    and word:byte(i - 1) == value:byte(j) then
                    current[j] = math.min(current[j], beforePrevious[j - 2] + 1)
                end

                distance = math.min(distance, current[j])
            end

            beforePrevious, previous = previous, current
        end
    end

    if distance > limit then
        return -math.huge
    end

    return #word * 16 - distance * 22 + (value == word and 32 or 0)
        + (value:sub(1, #word) == word and 4 or 0)
end

-- Every query word must match a name or alias; nil means no eligible alignment.
function text.FuzzyScore(values, query, allowTypos)
    query = text.Trim(query):lower()
    local total, exact = 0, 0

    for word in query:gmatch("%S+") do
        local limit = (allowTypos == false or #query <= 3) and 0 or (#word >= 8 and 2 or 1)
        local best = -math.huge

        for _, value in ipairs(values) do
            value = value:lower()

            if value == query then
                exact = 32
            end

            -- Do not assemble a query word from letters in unrelated destination words.
            for candidate in value:gmatch("%S+") do
                best = math.max(best, wordScore(candidate, word, limit))
            end
        end

        if best == -math.huge then
            return nil
        end

        total = total + best
    end

    return total + exact
end

-- Native option numbers remain shortcut keys even when their artwork is rearranged.
function text.Hotkey(name)
    return name:match("^%s*(%d+)%.")
end

return text
