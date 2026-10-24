local destinations = require("definitions/teleport_maps")
local constants = require("definitions/constants")
local modalMap = require("impl/modal_map")
local backgroundView = require("impl/background_view")
local buttonIcon = require("impl/button_icon")
local teleportMaps = {}
local background, icons
local lastLayoutError

-- Destroy plugin-owned artwork and release the native modal session.
local function releaseModal()
    if icons ~= nil then icons:Destroy() end
    if background ~= nil then background:Destroy() end
    icons, background = nil, nil
    modalMap.Release()
end

-- Match the current menu and update its map, native hitboxes, icons and tooltip each frame.
local function draw()
    local ok, message = pcall(function()
        local menu = modalMap.ReadRows(destinations)
        if menu == nil then
            releaseModal()
            return
        end
        if not modalMap.Matches(menu) then
            releaseModal()
            modalMap.Begin(menu)
            background = backgroundView.New(menu.content)
            icons = buttonIcon.New(background.layer)
        end

        local hovered = modalMap.Hovered(menu)
        local width, height = modalMap.Fit(menu.background, constants.maxWidth)
        
        background:Show(menu.background, width, height)
        modalMap.Layout(width, height, background.layer)
        icons:Update(menu, hovered)
        modalMap.UpdateTooltip(hovered)
        lastLayoutError = nil
    end)
    if not ok then
        releaseModal()
        message = tostring(message)
        if message ~= lastLayoutError then
            print("Unable to embed teleport map: " .. message)
            lastLayoutError = message
        end
    end
end

-- Subscribe the renderer to the client's draw event.
function teleportMaps.Start()
    Event.Draw.Subscribe("destinationPreview", draw)
end

-- Stop rendering and remove plugin-owned UI when the plugin unloads.
function teleportMaps.Stop()
    Event.Draw.Unsubscribe("destinationPreview")
    releaseModal()
end

return teleportMaps
