local languages = require("translations/languages")
local constants = require("definitions/constants")

local translations = {}
local english = require("translations/en")
local cachedOption, cachedSetting, cachedTable

-- Option labels are documented as English, independent of the client language.
function translations.Current()
    if constants.debugLanguage ~= nil then
        local module = languages[constants.debugLanguage]
        return module and require(module) or english
    end

    local option = game and game.options and game.options.Language
    if option == nil then
        return english
    end

    local setting = option.setting
    if option ~= cachedOption or setting ~= cachedSetting then
        local language = option:GetLabel(setting)
        local module = languages[language]
        cachedTable = module and require(module) or english
        cachedOption, cachedSetting = option, setting
    end

    return cachedTable
end

local function lookup(language, section, key)
    local entries = language[section]
    local value = entries and entries[key]
    assert(value == nil or type(value) == "string", section .. " translation must be a string: " .. tostring(key))
    return value
end

-- Canonical English labels/patterns remain the fallback for native matching.
function translations.GetMapping(key, language)
    local value = lookup(language or translations.Current(), "mappings", key)
    return value or key
end

-- For titles, descriptions and other custom text, with English defaults.
function translations.Localize(key)
    local value = lookup(translations.Current(), "localization", key)
        or lookup(english, "localization", key)
    assert(value ~= nil, "Missing localization: " .. tostring(key))
    return value
end

return translations
