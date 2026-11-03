local log = {}
local seen = {}
local history = {}
local nextSlot = 1
local historyLimit = 20

-- Suppress repeats of the last 20 printed messages, with bounded storage.
function log.Once(message)
    message = tostring(message)

    if seen[message] then
        return
    end

    local oldest = history[nextSlot]

    if oldest ~= nil then
        seen[oldest] = nil
    end

    history[nextSlot] = message
    nextSlot = nextSlot % historyLimit + 1
    seen[message] = true

    print(message)
end

return log
