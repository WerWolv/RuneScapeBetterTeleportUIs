local text = require("impl/text")
local aliases = {}

-- Read the original comma-separated format as well as escaped, individually registered aliases.
function aliases.Parse(value)
    local result = {}
    local escaped = value:sub(1, 3) == "v2\n"

    for line in value:gmatch("[^\r\n]+") do
        local code, names = line:match("^([ABCD][IJKL][PQRS])=(.*)$")

        if code ~= nil then
            result[code] = result[code] or {}

            for name in names:gmatch("[^,]+") do
                if escaped then
                    name = name:gsub("%%(%x%x)", function(hex)
                        return string.char(tonumber(hex, 16))
                    end)
                end

                name = text.Clean(name)

                if name ~= "" then
                    result[code][#result[code] + 1] = name
                end
            end
        end
    end

    return result
end

function aliases.Serialize(entries)
    local lines = {}

    for code, names in pairs(entries) do
        local encoded = {}

        for _, name in ipairs(names) do
            encoded[#encoded + 1] = name:gsub("[%%,\r\n]", function(character)
                return string.format("%%%02X", character:byte())
            end)
        end

        if #encoded > 0 then
            lines[#lines + 1] = code .. "=" .. table.concat(encoded, ",")
        end
    end

    table.sort(lines)
    return "v2\n" .. table.concat(lines, "\n")
end

-- Taken with permission from https://github.com/PrettyRS/fairyrings/blob/main/aliases.lua
-- Original code is licensed under BSD 3-Clause which may be found under licenses/PRETTYRS_FAIRYRINGS_LICENSE
aliases.searchAliases = {
    AIQ = {
        "port sarim",
        "rimmington",
        "anvil",
        "ice dungeon",
        "frost dragons"
    },
    AIR = {
        "clue",
        "clue scroll",
        "treasure trail"
    },
    AIS = {
        "guthix"
    },
    ALR = {
        "abby demons",
        "abyssal demons"
    },
    AJR = {
        "fremennik",
        "mountain camp"
    },
    AKP = {
        "home",
        "poh"
    },
    AKQ = {
        "falconry",
        "phoenix lair",
        "fishing colony",
        "eternal magic trees",
        "airuts"
    },
    AKS = {
        "gnome glider",
        "oo'glog",
        "chompy birds"
    },
    ALP = {
        "jiggig"
    },
    ALQ = {
        "araxxor",
        "port phasmatys"
    },
    ALS = {
        "hemenster",
        "seers village",
        "fishing guild"
    },
    BIQ = {
        "kq",
        "bandit camp",
        "mining camp",
        "kalphite cave",
        "kalphite queen"
    },
    BJP = {
        "grove"
    },
    BJQ = {
        "kuradal",
        "slayer",
        "mithril dragons",
        "waterfiends"
    },
    BJR ={
        "brimhaven"
    },
    BIP = {
        "brilliant wisps",
        "mta",
        "mage training arena",
        "het's oasis",
        "slayer"
    },
    BJS = {
        "solak",
        "vinecrawlers",
        "bulbous crawler",
        "moss golem"
    },
    BIS = {
        "ardy",
        "ardougne"
    },
    BKP = {
        "jiggig",
        "incandescent wisps"
    },
    BKR = {
        "nature spirit",
        "nature grotto"
    },
    BKS = {
        "wendlewick",
        "eastfold farm",
        "crabs"
    },
    BLP = {
        "mor ul rek",
        "volcano",
        "karamja"
    },
    BLR = {
        "witchaven",
        "ardougne",
        "keep le faye",
        "pof",
        "player owned farm"
    },
    BLQ = {
        "bandos throne room"
    },
    CIQ = {
        "tree gnome village",
        "castle wars"
    },
    CJR = {
        "camelot",
        "seers village",
        "rellekka"
    },
    CIS = {
        "evil bob"
    },
    CJS = {
        "karamja"
    },
    CKQ = {
        "desert",
        "soul altar",
        "sophanem"
    },
    CKR = {
        "nature altar",
        "shilo village",
        "cairn isle",
        "karambwanji"
    },
    CKS = {
        "temple trekking",
        "paterdomus",
        "slayer tower",
        "mushroom patch"
    },
    CLR = {
        "agility course",
        "monkey"
    },
    CLS = {
        "hazelmere"
    },
    DJP ={
        "ardougne",
        "port khazard",
        "monastery"
    },
    DIP = {
        "trouble brewing",
        "cave horrors"
    },
    DIS = {
        "draynor village",
        "runecrafting guild",
        "lumbridge swamp"
    },
    DJR = {
        "camelot",
        "seers village",
        "rellekka"
    },
    DJS = {
        "summoning obelisk",
        "amlodd",
        "ithell"
    },
    DKP = {
        "karambwans",
        "gnome glider",
        "shipyard"
    },
    DKQ = {
        "rotm",
        "ritual of the mahjarrat",
        "mahjarrat",
        "jas"
    },
    DKR = {
        "varrock",
        "grand exchange",
        "wilderness",
        "ge"
    },
    DKS = {
        "keldagrim",
        "rellekka",
        "fremennik",
        "fremmy",
        "polar hunter area"
    },
    DLP = {
        "bank"
    },
    DLQ ={
        "hunter area",
        "uzer"
    },
    DLS = {
        "canifis",
        "tunnel",
        "barrows",
        "morton",
        "mort'ton"
    }
}

return aliases
