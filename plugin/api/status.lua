local teleportMaps = require("impl/teleport_maps")

local status = {}

-- Example Code
--
-- local interfaceKey = api.Status.GetCurrentInterface()
-- if interfaceKey == nil then
--     print("No recognized teleport interface is open")
-- elseif api.Status.IsEnabled() then
--     print(interfaceKey .. " is showing its custom presentation")
-- else
--     print(interfaceKey .. " is open with its custom presentation disabled")
-- end

---Return the current interface key, or nil if none is open.
---Also identifies interfaces whose custom presentation is disabled.
---@return string?
function status.GetCurrentInterface()
    local key = teleportMaps.GetStatus()

    return key
end

---Return whether the current interface's custom presentation is showing.
---@return boolean
function status.IsEnabled()
    local _, enabled = teleportMaps.GetStatus()

    return enabled
end

return status
