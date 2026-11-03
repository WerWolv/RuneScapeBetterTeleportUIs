local components = require("impl/ui/components")

local native = {}

-- Read only direct dynamic children. Clipped rows still belong to the menu,
-- so use hidden rather than visibleGlobal, and reject incomplete snapshots.
function native.ReadDynamicRows(parent, parseRow)
    local rows, seen, malformed = {}, {}, false

    parent:IterateDynamicComponents(function(control)
        local key = components.Key(control)

        if control.parent == parent and not control.hidden and not seen[key] then
            seen[key] = true

            local row = parseRow(control)

            if row == nil then
                malformed = true
            else
                rows[#rows + 1] = row
            end
        end

        return false
    end)

    if malformed then
        return nil, "malformed"
    end

    if #rows == 0 then
        return nil, "empty"
    end

    -- Nexus roots share dynamic ID zero and differ by category; other native
    -- lists may use multiple dynamic IDs within the same category.
    table.sort(rows, function(a, b)
        if a.row.categoryID ~= b.row.categoryID then
            return a.row.categoryID < b.row.categoryID
        end

        return a.row.dynamicID < b.row.dynamicID
    end)

    for index, row in ipairs(rows) do
        row.index = index
    end

    return rows
end

-- Capture the host's original dimensions and offsets before any resizing.
function native.ReadLayoutHost(window, frameID, contentID, name)
    local frame = assert(ui.Interfaces:GetComponent(frameID))
    local content = assert(ui.Interfaces:GetComponent(contentID))

    assert(window.parent == content and content.parent == frame, "Unexpected " .. name .. " host hierarchy")

    return content, { frame, content }, {
        content = content,
        width = frame.width - content.width,
        height = frame.height - content.height,
        contentWidth = content.width,
        contentHeight = content.height,
        left = content.xyGlobal.x - frame.xyGlobal.x,
        top = content.xyGlobal.y - frame.xyGlobal.y,
    }
end

-- Share the size calculation while leaving each adapter's anchoring and drag
-- offsets under its control. The result is the available host content size.
function native.FitLayoutHost(session, baseWidth, baseHeight, sizeMultiplier)
    local viewport = assert(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__VIEWPORT))
    local padding = session.hostPadding
    local multiplier = sizeMultiplier or 1
    local insetX = session.left + session.right + 16
    local insetY = session.top + session.bottom + 16
    local width = (baseWidth - insetX) * multiplier + insetX
    local height = (baseHeight - insetY) * multiplier + insetY

    return math.max(1, math.floor(math.min(width, viewport.width - padding.width))),
        math.max(1, math.floor(math.min(height, viewport.height - padding.height)))
end

return native
