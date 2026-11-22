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
-- local handle, reason = api.Highlight.Create("amuletOfGlory", "edgeville")
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
---Button IDs use ClueTrainer spots.id where available, lowercased except Fairy Ring codes.
---IDs are case-sensitive. GetTargets() returns the exact accepted IDs.
---Names and hotkeys are not accepted. Numeric IDs such as obelisk "13" are strings.
---Returns nil and a reason if the request is invalid or the interface is locked.
---@param interfaceKey string
---@param buttonID string
---@return TeleportHighlight?, string?
function highlight.Create(interfaceKey, buttonID)
    return teleportMaps.CreateHighlight(interfaceKey, buttonID)
end

---Return a copy of the open interface's targets: { key, name, disabled }.
---Each key is a stable button ID accepted by Create().
---@param interfaceKey string
---@return table?, string?
function highlight.GetTargets(interfaceKey)
    return teleportMaps.GetHighlightTargets(interfaceKey)
end

return highlight
