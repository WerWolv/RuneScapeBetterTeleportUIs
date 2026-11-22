local teleportMaps = require("impl/teleport_maps")

local highlight = {}

-- Example Code: Fairy Rings
--
-- local targets = api.Highlight.GetTargets("fairyRings")
-- for _, target in ipairs(targets or {}) do
--     print(target.key, target.name, target.disabled)
-- end
--
-- local handle, reason = api.Highlight.Create("fairyRings", "AKQ")
-- if handle == nil then
--     print(reason)
--     return
-- end
--
-- Later, release the highlight and unlock the search bar:
-- handle:Release()

-- Example Code: Amulet of Glory
--
-- local handle, reason = api.Highlight.Create("amuletOfGlory", "Edgeville") -- Also accepts 1 or "1".
-- if handle == nil then
--     print(reason)
--     return
-- end
--
-- Applies whenever the map opens, until released:
-- handle:Release()

---@class TeleportHighlight
---@field Release fun(self: TeleportHighlight): boolean Safe to call repeatedly.

---Create a highlight that persists across openings until Release() or plugin shutdown.
---Exclusive interfaces remain locked while closed. Unavailable targets wait until they can be shown.
---Maps accept destination text or shortcuts; Fairy Rings accept codes.
---Returns nil and a reason if the request is invalid or the interface is locked.
---@param interfaceKey string
---@param buttonKey string|number
---@return TeleportHighlight?, string?
function highlight.Create(interfaceKey, buttonKey)
    return teleportMaps.CreateHighlight(interfaceKey, buttonKey)
end

---Return a copy of the open interface's targets: { key, name, disabled }.
---Use these keys for menus with their own destination identifiers.
---@param interfaceKey string
---@return table?, string?
function highlight.GetTargets(interfaceKey)
    return teleportMaps.GetHighlightTargets(interfaceKey)
end

return highlight
