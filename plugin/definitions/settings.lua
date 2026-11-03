-- Groups are listed in UI order within their tab. Setting keys are persistent; keep them stable.
-- Built-in types: boolean, number (min/max/step), string, label. Custom types use a module path.
-- A group's widget can replace the standard group renderer with a custom module.
-- Interface rows can declare details = { groups... } to open a cog-wheel subpage.
local interfaceSettings = {
    ["enhancements/fairy_rings/fairy_rings"] = {
        {
            label = "Search",
            settings = {
                {
                    key = "autoFocusFairyRingSearch",
                    type = "boolean",
                    label = "Automatically focus search",
                    description = "Allows typing to search without clicking the search box first",
                    default = true,
                },
                {
                    key = "fuzzyFairyRingSearch",
                    type = "boolean",
                    label = "Fuzzy destination search",
                    description = "When enabled, typo-ing the search text will still try to find the right destination",
                    default = true,
                },
            },
        },
        {
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
    },
    ["maps/jewellery_box"] = {
        {
            label = "Custom teleport categories",
            description = "Create categories and choose the teleports included in each one",
            fillHeight = true,
            settings = {
                {
                    key = "jewelleryBoxCustomCategories",
                    type = "impl/settings/teleport_categories",
                    default = "",
                    categories = require("definitions/jewellery_box_categories"),
                },
            },
        },
    },
    ["maps/teleport_nexus"] = {
        {
            label = "Custom teleport categories",
            description = "Create categories and choose the teleports included in each one",
            fillHeight = true,
            settings = {
                {
                    key = "nexusCustomCategories",
                    type = "impl/settings/teleport_categories",
                    default = "",
                    categories = require("definitions/nexus_categories"),
                },
            },
        },
    },
}

local interfaces = {}
for _, interface in ipairs(require("definitions/teleport_interfaces")) do
    interfaces[#interfaces + 1] = {
        key = interface.module,
        type = "boolean",
        label = interface.name,
        default = true,
        details = interfaceSettings[interface.module],
    }
end
table.sort(interfaces, function(a, b)
    return a.label < b.label
end)

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
            {
                key = "cropBackgroundMaps",
                type = "boolean",
                label = "Zoom Maps to content",
                description = "When enabled, zooms in on the destination buttons on each of the teleport maps",
                default = false,
            },
            {
                key = "showOriginalUIToggle",
                type = "boolean",
                label = "Show original UI toggle",
                description = "Displays a button to temporarily switch between the original and enhanced menus",
                default = false,
            },
        },
    },
    {
        tab = "Interfaces",
        label = "Available UI enhancements",
        description = "Options to enable or disable each UI change individually",
        widget = "impl/settings/interface_toggles",
        settings = interfaces,
    },
}
