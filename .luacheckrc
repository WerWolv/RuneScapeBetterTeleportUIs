std = "lua54" -- RuneScape uses Lua 5.4.8 currently
codes = true

unused_args = false
max_line_length = false

exclude_files = {
    "build/**",
    "dist/**",
}

files["plugin/**/*.lua"] = {
    read_globals = {
        "Event",
        "ExecuteConsoleCommand",
        "GameKey",
        "Keyboard",
        "Mouse",
        "LocShapeType",
        "PersistentDB",
        "Plugin",
        "Vector3",
        "Vector4",
        "config",
        "game",
        "id",
        "prettyui",
        "ui",
        "var",
    },
}

files["plugin/main.lua"] = {
    globals = { "PluginShutdown" },
}
