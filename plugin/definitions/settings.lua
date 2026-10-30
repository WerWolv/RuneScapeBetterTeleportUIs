-- Listed in UI order. Keys are also the PersistentDB keys; keep them stable.
-- Built-in types: boolean, number (min/max/step), string. Custom types use a module path.
-- Widgets choose label/description placement using the shared styling helpers.
return {
    {
        key = "showTeleportHotkeys",
        tab = "General",
        type = "boolean",
        label = "Show teleport hotkeys",
        description = "Displays the keyboard shortcut of each teleport next to its icon",
        default = false,
    },
    {
        key = "fuzzyFairyRingSearch",
        tab = "Fairy Rings",
        type = "boolean",
        label = "Fuzzy Fairy Ring search",
        description = "Allows minor typos when searching Fairy Ring destinations",
        default = true,
    },
    {
        key = "fairyRingAliases",
        tab = "Fairy Rings",
        type = "impl/settings/fairy_ring_aliases",
        label = "Custom search aliases",
        description = "Register custom aliases for each teleport destination",
        default = "",
    },
}
