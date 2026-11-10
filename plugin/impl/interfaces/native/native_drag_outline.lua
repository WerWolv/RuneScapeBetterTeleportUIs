local NativeLayout = require("impl/interfaces/native/native_layout")
local components = require("impl/ui/components")

local NativeDragOutline = {}
NativeDragOutline.__index = NativeDragOutline

-- The native drag handler resolves its window ID through this same config.
-- Match the host so another window's shared layout guides are never resized.
local function draggedHost()
    local windowID = var.VarClient.TOPLEVEL_V2_WINDOW_BEING_DRAGGED.value
    local data = config.Enum.TOPLEVEL_V2_WINDOW_ID_TO_DATA:GetOutputValue(windowID)

    if type(data) == "number" then
        data = data >= 0 and config.Struct.FromID(data) or nil
    end

    if data == nil then
        return nil
    end

    local host = data:GetParamValue(config.Param.TOPLEVEL_V2_WINDOW_LAYER)

    if type(host) == "number" then
        return host >= 0 and ui.Interfaces:GetComponent(host) or nil
    end

    return host
end

function NativeDragOutline.New(host)
    return setmetatable({ host = host }, NativeDragOutline)
end

function NativeDragOutline:Restore()
    if self.layout ~= nil then
        self.layout:Restore()
        self.layout = nil
    end
end

-- Native dragging writes both guides from its saved layout, independently of
-- Lua's fitted host. Correct their draw rectangles after the final menu layout.
function NativeDragOutline:Update(window)
    -- Recover the latest native positions before adding the visible inset.
    -- This also prevents drift when several draws share one native logic tick.
    self:Restore()

    local host = draggedHost()

    if host == nil or components.Key(host) ~= components.Key(self.host) then
        return
    end

    local guides, movingGuide = {}, nil

    for _, componentID in ipairs({
        id.Component.TOPLEVEL_V2__LAYOUT_GUIDE,
        id.Component.TOPLEVEL_V2__LAYOUT_GUIDE_2,
    }) do
        local guide = ui.Interfaces:GetComponent(componentID)

        if guide ~= nil and guide.visibleGlobal then
            guides[#guides + 1] = guide

            if componentID == id.Component.TOPLEVEL_V2__LAYOUT_GUIDE then
                movingGuide = guide
            end
        end
    end

    local windowPosition, hostPosition = window.xyGlobal, host.xyGlobal
    local insetX = windowPosition.x - hostPosition.x
    local insetY = windowPosition.y - hostPosition.y

    self.layout = NativeLayout.FromControls(guides)
    self.layout:Apply(function()
        for _, guide in ipairs(guides) do
            local x, y = guide.x + insetX, guide.y + insetY

            -- The proposed native guide is clamped using the saved size and
            -- can stop before the fitted window. Follow the final visible
            -- rectangle; the second guide continues to mark the drag origin.
            if guide == movingGuide then
                local parentPosition = guide.parent.xyGlobal

                x = windowPosition.x - parentPosition.x
                y = windowPosition.y - parentPosition.y
            end

            guide:SetSize(window.width, window.height)
            guide:SetPos(x, y)
        end
    end)
end

return NativeDragOutline
