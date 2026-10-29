local components = {}

local collections = {
    [ui.ComponentType.LAYER]          = true,
    [ui.ComponentType.PANEL]          = true,
    [ui.ComponentType.GRID]           = true,
    [ui.ComponentType.PAGED_LAYER]    = true,
    [ui.ComponentType.PAGED_CAROUSEL] = true,
    [ui.ComponentType.GROUP_BOX]      = true,
}

-- Native wrappers may refer to the same component through multiple collection paths.
function components.Key(control)
    return table.concat({ control.interfaceID, control.staticID, control.categoryID, control.dynamicID }, ":")
end

-- Visit each component once. Returning false prunes that component's descendants.
-- A shared visited table also deduplicates overlapping roots.
function components.Walk(root, callback, visited)
    visited = visited or {}

    local function visit(control)
        local key = components.Key(control)

        if visited[key] then
            return false
        end

        visited[key] = true

        if callback(control) ~= false and collections[control.type] then
            control:IterateStaticComponents(visit)
            control:IterateDynamicComponents(visit)
        end

        return false
    end

    visit(root)
end

-- Inventory artwork is passive and never displays the native quantity overlay.
function components.ItemSprite(parent, objectID)
    local sprite = ui.Sprite.new(parent)
    sprite.associatedObjectID = objectID
    sprite.associatedObjectQuantity = 1
    sprite.associatedObjectQuantityMode = ui.ObjectQuantityDisplayMode.NEVER
    sprite.clickthrough = true

    return sprite
end

-- Passive, single-line labels used by cards, shortcut badges and charge counters.
function components.CenteredLabel(parent, font)
    local label = ui.Text.new(parent)
    label.font = font
    label:AlignTo(ui.AlignMode.CENTRE)
    label.isShadowed = true
    label.maxLines = 1
    label.clickthrough = true

    return label
end

return components
