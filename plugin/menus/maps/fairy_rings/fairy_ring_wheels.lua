local cleanup = require("impl/cleanup")

local FairyRingWheels = {}

-- Preserve native turn actions while supplying directional hover cursors.
function FairyRingWheels.Update(session)
    for _, row in ipairs(session.menu.rows) do
        local control = row.click
        local desired = row.destination.cursor

        if desired ~= nil and control.visibleGlobal then
            local cursor = control.cursorConfig
            local override = session.cursorOverrides[row.entryKey]

            if cursor.mouseOverCursor ~= desired then
                if override == nil or cursor.mouseOverCursor ~= override.applied then
                    override = {
                        control = control,
                        original = cursor.mouseOverCursor,
                    }
                    session.cursorOverrides[row.entryKey] = override
                end

                cursor.mouseOverCursor = desired
                override.applied = desired
            end
        end
    end
end

function FairyRingWheels.Restore(session)
    for _, override in pairs(session.cursorOverrides or {}) do
        cleanup.Try("restore Fairy Ring cursor", function()
            local cursor = override.control.cursorConfig

            if cursor.mouseOverCursor == override.applied then
                cursor.mouseOverCursor = override.original
            end
        end)
    end

    session.cursorOverrides = nil
end

return FairyRingWheels
