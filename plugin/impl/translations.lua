local languages = require("translations/languages")
local constants = require("definitions/constants")

local translations = {}
local english = {}
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

function translations.Get(key, dictionary)
    dictionary = dictionary or translations.Current()
    local value = dictionary[key]
    assert(value == nil or type(value) == "string", "Translation must be a string: " .. tostring(key))
    return value or key
end

return translations
