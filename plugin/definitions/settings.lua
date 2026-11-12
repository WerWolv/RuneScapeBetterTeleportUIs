-- Groups are listed in UI order within their tab. Setting keys are persistent; keep them stable.
-- Built-in types: boolean, number (min/max/step), string, label. Custom types use a module path.
-- A group's widget can replace the standard group renderer with a custom module.
-- Interface rows can declare details = { groups... } to open a cog-wheel subpage.
local interfaceSettings = {
    ["maps/fairy_rings/fairy_rings"] = {
        {
            label = "Interface",
            settings = {
                {
                    key = "fairyRingMapByDefault",
                    type = "boolean",
                    label = "Use map by default",
                    description = "When disabled, opens the enhanced regular UI instead. Applies the next time you open Fairy Rings.",
                    default = true,
                },
                {
                    key = "showFairyRingMapCodes",
                    type = "boolean",
                    label = "Show fairy ring codes",
                    description = "Displays codes on map icons and Other destinations buttons. When disabled, the list uses compact name-only rows.",
                    default = false,
                },
            },
        },
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
    ["maps/jewellery_box/jewellery_box"] = {
        {
            label = "Custom teleport categories",
            description = "Create categories and choose the teleports included in each one",
            fillHeight = true,
            settings = {
                {
                    key = "jewelleryBoxCustomCategories",
                    type = "impl/settings/teleport_categories",
                    default = "",
                    categories = require("menus/maps/jewellery_box/categories"),
                },
            },
        },
    },
    ["maps/teleport_nexus/teleport_nexus"] = {
        {
            label = "Custom teleport categories",
            description = "Create categories and choose the teleports included in each one",
            fillHeight = true,
            settings = {
                {
                    key = "nexusCustomCategories",
                    type = "impl/settings/teleport_categories",
                    default = "",
                    categories = require("menus/maps/teleport_nexus/categories"),
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
        item = interface.item,
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
                default = true,
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
