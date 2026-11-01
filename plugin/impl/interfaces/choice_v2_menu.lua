local ModalChoiceMenu = require("impl/interfaces/modal_choice_menu")
local text = require("impl/text")
local ChoiceV2Menu = ModalChoiceMenu:Extend()
ChoiceV2Menu.interface = ChoiceV2Menu
ChoiceV2Menu.interfaceName = "CHOICE_V2 (" .. id.Interface.CHOICE_V2 .. ")"
ChoiceV2Menu.nativeInterface = {
    id = id.Interface.CHOICE_V2,
    prefix = "CHOICE_V2__",
    window = "WINDOW",
    content = "CONTENT",
    options = "OPTIONS",
    close = "CLOSE",
    titleParent = "BORDER",
    titleFont = id.Font.CINZEL_13PT_BOLD,
    frame = {"BACKGROUND", "BORDER"},
    optionCount = 5,
    lastStaticID = 40,
    directButtons = true,
}

-- Keep the native message window as the movable host.
function ChoiceV2Menu:GetLayoutHost(window)
    local frame = assert(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__MES_WINDOW))
    local content = assert(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__MES_WINDOW_CONTENT))
    assert(content.parent == frame and window.parent == content, "Unexpected CHOICE_V2 host hierarchy")
    return content, {frame, content}, {
        width = frame.width - content.width,
        height = frame.height - content.height,
    }
end

-- Match the modal's available area without overwriting the client's drag offsets.
function ChoiceV2Menu:UpdateLayoutHost(session, sizeMultiplier)
    local frame, content = session.hostContainers[1], session.layoutParent
    local baseWidth, baseHeight = ModalChoiceMenu:GetModalHostSize()
    local viewport = assert(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__VIEWPORT))
    -- Dragging may reset only the frame's size; retain the original margins.
    local paddingX, paddingY = session.hostPadding.width, session.hostPadding.height
    local multiplier = sizeMultiplier or 1
    local insetX = session.left + session.right + 16
    local insetY = session.top + session.bottom + 16
    local width = (baseWidth - insetX) * multiplier + insetX
    local height = (baseHeight - insetY) * multiplier + insetY
    width = math.max(1, math.floor(math.min(width, viewport.width - paddingX)))
    height = math.max(1, math.floor(math.min(height, viewport.height - paddingY)))
    frame:SetSize(width + paddingX, height + paddingY)
    content:SetSize(width, height)
end

-- Native shortcuts and option names are separate labels inside each option's text layer.
function ChoiceV2Menu:ReadOptionLabels(row, index)
    local function component(name)
        return ui.Interfaces:GetComponent(id.Component["CHOICE_V2__" .. name])
    end
    local container = component("OPTION_" .. index .. "_TEXT")
    local label = component("OPTION_TEXT_" .. index)
    local shortcut = component("TEXT_" .. index)
    if container == nil or container.parent ~= row
        or label == nil or label.parent ~= container or not label.visibleGlobal
        or shortcut == nil or shortcut.parent ~= container then
        return {}
    end
    local name, key = text.Clean(label.content), text.Clean(shortcut.content)
    if name == "" then return {} end
    return {[key ~= "" and (key .. " " .. name) or name] = true}
end

return ChoiceV2Menu
