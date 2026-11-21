local settings = require("impl/settings")

local labels = {}

-- Menus opt out in :Define(); otherwise the global display setting applies.
function labels.Enabled(definition)
    return settings.Get("showTeleportNames")
        and (definition == nil or definition.showTeleportNames ~= false)
end

return labels
