-- Menu modules may export one concrete class or a list of page classes.
local registry = {}
for _, definition in ipairs(require("definitions/teleport_interfaces")) do
    local exported = require("menus/" .. definition.module)
    if type(exported.New) == "function" then
        exported.enabledSetting = definition.key
        registry[#registry + 1] = exported
    else
        for _, class in ipairs(exported) do
            class.enabledSetting = definition.key
            -- Pages exported together share placement while navigating an open menu.
            class.pageGroup = exported
            registry[#registry + 1] = class
        end
    end
end

return registry
