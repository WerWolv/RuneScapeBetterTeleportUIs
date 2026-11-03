-- Menu modules may export one concrete class or a list of page classes.
local log = require("impl/log")

local registry = {}

for _, definition in ipairs(require("definitions/teleport_interfaces")) do
    local ok, classes = pcall(function()
        local exported = require("menus/" .. definition.module)

        assert(type(exported) == "table", "Menu module must export a class or a list of classes")

        local pages = exported.New == nil
        local entries = pages and exported or { exported }

        if pages then
            local count = 0

            for key in pairs(entries) do
                assert(
                    type(key) == "number" and key >= 1 and key % 1 == 0,
                    "Menu pages must be a contiguous array"
                )

                count = count + 1
            end

            assert(count > 0 and count == #entries, "Menu pages must be a nonempty contiguous array")

            for index = 1, count do
                assert(entries[index] ~= nil, "Menu pages must not contain gaps")
            end
        end

        for _, class in ipairs(entries) do
            assert(
                type(class) == "table" and type(class.New) == "function",
                "Each menu class must provide New"
            )
        end

        for _, class in ipairs(entries) do
            class.enabledSetting = definition.module

            if pages then
                -- Pages exported together share placement while navigating an open menu.
                class.pageGroup = exported
            end
        end

        return entries
    end)

    -- Commit only a fully validated family; a bad page cannot leave half a menu registered.
    if ok then
        for _, class in ipairs(classes) do
            registry[#registry + 1] = class
        end
    else
        log.Once("Unable to load teleport menu " .. tostring(definition.module) .. ": " .. tostring(classes))
    end
end

return registry
