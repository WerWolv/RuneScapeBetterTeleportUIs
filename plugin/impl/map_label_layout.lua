local layout = {}
local gap = 0

local function overlap(a, b)
    return math.max(0, math.min(a.x + a.width, b.x + b.width) - math.max(a.x, b.x))
        * math.max(0, math.min(a.y + a.height, b.y + b.height) - math.max(a.y, b.y))
end

local function better(count, area, bestCount, bestArea)
    return count < bestCount or count == bestCount and area < bestArea
end

local function candidate(item, direction, variant)
    local anchor = item.anchor
    local width, height = variant.width, variant.height
    local x = anchor.x + (anchor.width - width) / 2
    local y = anchor.y + (anchor.height - height) / 2
    if direction == 1 then
        y = anchor.y + anchor.height + gap
    elseif direction == 2 then
        x = anchor.x + anchor.width + gap
    elseif direction == 3 then
        x = anchor.x - width - gap
    else
        y = anchor.y - height - gap
    end
    -- Snap away from the icon. Rounding a fractional bottom/right edge down
    -- would make the label collide with its own icon.
    return {
        x = direction == 2 and math.ceil(x) or math.floor(x),
        y = direction == 1 and math.ceil(y) or math.floor(y),
        width = width, height = height, direction = direction, variant = variant,
    }
end

-- Pure geometry: items carry an anchor rectangle and measured label dimensions.
-- Outputs use the same indices; false means that no unobstructed position survived.
local function place(items, obstacles, width, height, margins, allowWrap, uniformOnly)
    local candidates, fixed = {}, {}
    for _, obstacle in ipairs(obstacles or {}) do
        fixed[#fixed + 1] = obstacle
    end
    for _, item in ipairs(items) do
        fixed[#fixed + 1] = item.anchor
    end

    margins = margins or {}
    local viewport = {
        x = -(margins.left or 0), y = -(margins.top or 0),
        width = width + (margins.left or 0) + (margins.right or 0),
        height = height + (margins.top or 0) + (margins.bottom or 0),
    }
    local variantCount = 1
    for index, item in ipairs(items) do
        candidates[index] = {}
        local variants = item.variants or { item }
        if not allowWrap then variants = { variants[1] } end
        variantCount = math.max(variantCount, #variants)
        for direction = 1, 4 do
            candidates[index][direction] = {}
            for _, variant in ipairs(variants) do
                local rect = candidate(item, direction, variant)
                local outside = rect.width * rect.height - overlap(rect, viewport)
                rect.conflicts, rect.area = outside > 0 and 1 or 0, outside
                for _, obstacle in ipairs(fixed) do
                    local area = overlap(rect, obstacle)
                    if area > 0 then
                        rect.conflicts, rect.area = rect.conflicts + 1, rect.area + area
                    end
                end
                table.insert(candidates[index][direction], rect)
            end
        end
    end

    -- Count collision pairs, then use overlap area to break ties.
    local function score(placements)
        local count, area = 0, 0
        for index = 1, #items do
            local rect = placements[index]
            if rect then
                count, area = count + rect.conflicts, area + rect.area
                for other = index + 1, #items do
                    if placements[other] then
                        local collision = overlap(rect, placements[other])
                        if collision > 0 then
                            count, area = count + 1, area + collision
                        end
                    end
                end
            end
        end
        return count, area
    end

    -- First try every label below, right, left, then above.
    local best, bestCount, bestArea
    for direction = 1, 4 do
        for variant = 1, variantCount do
            local placements = {}
            for index = 1, #items do
                local choices = candidates[index][direction]
                placements[index] = choices[math.min(variant, #choices)]
            end
            local count, area = score(placements)
            if count == 0 then
                return placements
            end
            if best == nil or better(count, area, bestCount, bestArea) then
                best, bestCount, bestArea = placements, count, area
            end
        end
    end

    if uniformOnly then return nil end

    local function conflicts(index, rect)
        local count, area = rect.conflicts, rect.area
        for other = 1, #items do
            if other ~= index and best[other] then
                local collision = overlap(rect, best[other])
                if collision > 0 then
                    count, area = count + 1, area + collision
                end
            end
        end
        return count, area
    end

    -- Repair only conflicting labels. Strict improvements prevent oscillation;
    -- the pass bound also caps work on unusually dense maps.
    for _ = 1, math.max(1, #items * 4) do
        local changed = false
        for index = 1, #items do
            local rect = best[index]
            local count, area = conflicts(index, rect)
            if count > 0 then
                local replacement = rect
                for direction = 1, 4 do
                    for _, alternative in ipairs(candidates[index][direction]) do
                        local nextCount, nextArea = conflicts(index, alternative)
                        if better(nextCount, nextArea, count, area) then
                            replacement, count, area = alternative, nextCount, nextArea
                        end
                        if count == 0 then
                            break
                        end
                    end
                    if count == 0 then
                        break
                    end
                end
                if replacement ~= rect then
                    best[index], changed = replacement, true
                end
            end
        end
        if not changed then
            break
        end
    end

    -- Remove the most troublesome remaining label until there are no collisions.
    -- Later rows lose ties, making the result deterministic without hiding both
    -- members of every overlapping pair.
    while true do
        local remove, worstCount, worstArea = nil, 0, 0
        for index = 1, #items do
            if best[index] then
                local count, area = conflicts(index, best[index])
                if count > 0 and (count > worstCount or count == worstCount and area >= worstArea) then
                    remove, worstCount, worstArea = index, count, area
                end
            end
        end
        if remove == nil then
            -- Deleting one conflict may make a different direction/line width
            -- viable for another previously hidden label.
            for index = 1, #items do
                if not best[index] then
                    for direction = 1, 4 do
                        for _, alternative in ipairs(candidates[index][direction]) do
                            if conflicts(index, alternative) == 0 then
                                best[index] = alternative
                                break
                            end
                        end
                        if best[index] then break end
                    end
                end
            end
            return best
        end
        best[remove] = false
    end
end

-- Exhaust all single-line directions/repairs first. Wrapping must rescue more
-- labels to replace that result; otherwise keep the simpler single-line layout.
function layout.Place(items, obstacles, width, height, margins, allowWrap, uniformOnly)
    local unwrapped = place(items, obstacles, width, height, margins, false, uniformOnly)
    if uniformOnly then return unwrapped end
    local function count(positions)
        local total = 0
        for index = 1, #items do
            if positions[index] then total = total + 1 end
        end
        return total
    end
    local visible = count(unwrapped)
    if allowWrap == false or visible == #items then return unwrapped end
    local wrapped = place(items, obstacles, width, height, margins, true)
    if count(wrapped) <= visible then return unwrapped end

    -- Keep only the line breaks needed to preserve the rescued labels.
    margins = margins or {}
    local viewport = {
        x = -(margins.left or 0), y = -(margins.top or 0),
        width = width + (margins.left or 0) + (margins.right or 0),
        height = height + (margins.top or 0) + (margins.bottom or 0),
    }
    local fixed = {}
    for _, obstacle in ipairs(obstacles or {}) do fixed[#fixed + 1] = obstacle end
    for _, item in ipairs(items) do fixed[#fixed + 1] = item.anchor end
    for index, item in ipairs(items) do
        local original = item.variants and item.variants[1] or item
        if wrapped[index] and wrapped[index].variant ~= original then
            for direction = 1, 4 do
                local rect = candidate(item, direction, original)
                local fits = overlap(rect, viewport) == rect.width * rect.height
                for _, obstacle in ipairs(fixed) do
                    fits = fits and overlap(rect, obstacle) == 0
                end
                for other = 1, #items do
                    if other ~= index and wrapped[other] then
                        fits = fits and overlap(rect, wrapped[other]) == 0
                    end
                end
                if fits then
                    wrapped[index] = rect
                    break
                end
            end
        end
    end
    return wrapped
end

return layout
