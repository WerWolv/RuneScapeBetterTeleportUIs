local log = require("impl/log")

local cleanup = {}

-- A failed cleanup must be visible without preventing independent resources
-- from being released (native controls may already have been destroyed).
function cleanup.Try(context, callback)
    local ok, message = pcall(callback)

    if not ok then
        log.Once("Unable to " .. context .. ": " .. tostring(message))
    end

    return ok
end

-- Detach first so reentrant or repeated teardown cannot release the same owner twice.
function cleanup.Release(owner, key, method)
    local resource = owner[key]
    owner[key] = nil

    if resource == nil then
        return
    end

    method = method or "Destroy"

    cleanup.Try(method .. " " .. key, function()
        resource[method](resource)
    end)
end

return cleanup
