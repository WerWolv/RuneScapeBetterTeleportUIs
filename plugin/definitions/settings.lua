-- Listed in UI order. Keys are also the PersistentDB keys; keep them stable.
-- boolean: checkbox; number: slider (min/max/step); string: text field.
-- Optional description adds explanatory text below the control.
return {
    {
        key = "showTeleportHotkeys",
        type = "boolean",
        label = "Show teleport hotkeys",
        description = "Displays the keyboard shortcut of each teleport next to its icon",
        default = false,
    },
}
