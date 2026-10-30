-- Groups are listed in UI order within their tab. Setting keys are persistent; keep them stable.
-- Built-in types: boolean, number (min/max/step), string, label. Custom types use a module path.
local interfaces = {}
for _, interface in ipairs(require("definitions/teleport_interfaces")) do
    interfaces[#interfaces + 1] = {
        key = interface.key,
        type = "boolean",
        label = interface.label,
        default = true,
    }
end
table.sort(interfaces, function(a, b) return a.label < b.label end)

return {
    {
        tab = "General",
        label = "Display",
        description = "Control how teleport destinations are displayed",
        settings = {
            {
                key = "showTeleportHotkeys",
                type = "boolean",
                label = "Show teleport hotkeys",
                description = "Displays the keyboard shortcut of each teleport next to its icon",
                default = false,
            },
        },
    },
    {
        tab = "Fairy Rings",
        label = "Search",
        description = "Allows minor typos when searching Fairy Ring destinations",
        settings = {
            {
                key = "fuzzyFairyRingSearch",
                type = "boolean",
                label = "Enable fuzzy search",
                default = true,
            },
        },
    },
    {
        tab = "Fairy Rings",
        label = "Custom search aliases",
        description = "Register custom aliases for each teleport destination",
        settings = {
            {
                key = "fairyRingAliases",
                type = "impl/settings/fairy_ring_aliases",
                default = "",
            },
        },
    },
    {
        tab = "Teleport Interfaces",
        label = "Available UI improvements",
        description = "Options to toggle each of the available UI enhancements on or off",
        settings = interfaces,
    },
}
