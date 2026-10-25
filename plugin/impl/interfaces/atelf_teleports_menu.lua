local TeleportMenu = require("impl/teleport_menu")
local AtelfTeleportsMenu = TeleportMenu:Extend()
AtelfTeleportsMenu.interface = AtelfTeleportsMenu
AtelfTeleportsMenu.interfaceName = "ATELF_TELEPORTS (" .. id.Interface.ATELF_TELEPORTS .. ")"

-- Discover the native quiver button by component identity rather than its changing display label.
function AtelfTeleportsMenu:ReadInterface()
    local window = ui.Interfaces:GetComponent(id.Component.ATELF_TELEPORTS__MAINMODAL_WINDOW)
    if window == nil or not window.visibleGlobal then
        return nil
    end

    local content = ui.Interfaces:GetComponent(id.Component.ATELF_TELEPORTS__MAINMODAL_WINDOW_CONTENT)
    local button = ui.Interfaces:GetComponent(id.Component.ATELF_TELEPORTS__ELFCITY_TELE_ELUNED)
    if content == nil or button == nil then 
        return nil
    end

    return {
        window = window,
        content = content,
        nativeRows = {{
            index = 1,
            labels = {ELFCITY_TELE_ELUNED = true},
            row = button,
            click = button,
            disabled = not button.visibleGlobal,
        }},
    }
end

-- Leave the client's layout untouched unless a concrete menu supplies an override.
function AtelfTeleportsMenu:CalculateLayout()
    return {}
end

-- Apply explicit overrides; empty layouts leave positioning to the client.
function AtelfTeleportsMenu:ApplyLayout(layout)
    for _, row in ipairs(self.session.menu.rows) do
        local control = row.click
        local position = layout and layout[row.entryKey]
        local overridden = position ~= nil and (position.x ~= nil or position.y ~= nil)
        if control ~= nil and overridden then
            assert(type(position.x) == "number" and type(position.y) == "number",
                "Native button position overrides require numeric x and y")
            if control.visibleGlobal then
                control:SetPos(position.x, position.y)
            end
        end
    end
end

return AtelfTeleportsMenu
