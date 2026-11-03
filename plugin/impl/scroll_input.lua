local components = require("impl/components")

local ScrollInput = {}
local handlers = setmetatable({}, { __mode = "k" })
local scopes = setmetatable({}, { __mode = "k" })

-- Custom controls use the public scroll position API. Keep nested panes as
-- separate input scopes, forwarding wheel input only when they reach an edge.
function ScrollInput.For(view, step, parent)
    local state = handlers[view]

    if state == nil then
        state = { step = step or 32, parent = parent }

        state.callback = function(component, delta)
            if view.root == nil then
                return true
            end

            if view.scrollable ~= false then
                local previous = view.scrollY
                view:SetScrollPosition(previous + delta * state.step)

                if view.scrollY ~= previous then
                    return false
                end
            end

            if state.parent ~= nil then
                return state.parent(component, delta)
            end

            return true
        end

        handlers[view] = state
        scopes[view.root] = state.callback
    end

    return state.callback
end

-- Only call on plugin-owned trees. Descendants added later must be bound after
-- construction; a registered nested view retains its own scrolling behavior.
function ScrollInput.Bind(root, handler)
    components.Walk(root, function(control)
        local nested = scopes[control]

        if nested ~= nil and nested ~= handler then
            ScrollInput.Bind(control, nested)

            return false
        end

        control:Subscribe(ui.Hook.ONSCROLLWHEEL, handler)
    end)
end

return ScrollInput
