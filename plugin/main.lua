local teleportMaps = require("impl/teleport_maps")
local settings = require("impl/settings")

function PluginShutdown()
    teleportMaps.Stop()
    settings.Stop()
end

settings.Start()
teleportMaps.Start()
