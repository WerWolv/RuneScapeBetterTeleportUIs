local ContentLayer = {}

-- SimpleView supplies a guarded category-zero root through PrettyUI's public API.
-- Use that root as a plain mount for nested content hosts (including tooltips).
-- Keep this wrapper: scrolling widgets place their drag overlays beside their roots.
-- Its unused scrolling surfaces are passive; retain the owner for full teardown.
function ContentLayer.New(parent)
    local view = prettyui.SimpleView.new(parent, {
        categoryID = "auto",
        width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        scrollable = false,
    })
    view:SetClickthrough(true)

    return view
end

return ContentLayer
