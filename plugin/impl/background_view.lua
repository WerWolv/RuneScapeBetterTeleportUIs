local geometry = require("impl/map_geometry")
local backgroundView = {}
backgroundView.__index = backgroundView

-- Create a viewport whose artwork has a uniform lifetime across all background types.
function backgroundView.New(parent)
    local layer = ui.Layer.new(parent)
    layer.hidden = true
    layer.clickthrough = true
    return setmetatable({layer = layer}, backgroundView)
end

-- Shade the visible viewport rather than the uncropped source image.
function backgroundView:ShowVignette(option, width, height)
    local settings = type(option) == "table" and option or {}
    local depth = option and math.max(0, math.floor(math.min(settings.width or 32, width / 2, height / 2))) or 0
    local opacity = math.max(0, math.min(1, settings.opacity or 0.65))
    local key = table.concat({ width, height, depth, opacity }, ":")

    if self.vignetteKey == key then
        return
    end

    if self.vignette ~= nil then
        self.vignette:Destroy()
        self.vignette = nil
    end

    self.vignetteKey = key

    if depth == 0 or opacity == 0 then
        return
    end

    self.vignette = ui.Layer.new(self.artwork)
    self.vignette:SetSize(width, height)
    self.vignette.clickthrough = true

    local function strip(x, y, stripWidth, stripHeight, alpha)
        local rectangle = ui.Rectangle.new(self.vignette)
        rectangle:SetPos(x, y)
        rectangle:SetSize(stripWidth, stripHeight)
        rectangle.fill = true
        rectangle.rgba = alpha
        rectangle.clickthrough = true
    end

    -- Blend independent edge fades so corners darken smoothly without diagonal ring creases.
    for inset = 0, depth - 1 do
        local fade = 1 - inset / depth
        local alpha = math.floor(255 * opacity * fade * fade + 0.5)

        strip(0, inset, width, 1, alpha)
        strip(0, height - inset - 1, width, 1, alpha)
        strip(inset, 0, 1, height, alpha)
        strip(width - inset - 1, 0, 1, height, alpha)
    end
end

-- Destroy explicit sprite wrappers before their containing artwork layer.
function backgroundView:Clear()
    if self.vignette ~= nil then
        self.vignette:Destroy()
        self.vignette = nil
    end

    self.vignetteKey = nil

    if self.sprite ~= nil then
        self.sprite:Destroy()
        self.sprite = nil
    end

    if self.artwork ~= nil then
        self.artwork:Destroy()
        self.artwork = nil
    end
end

-- Release plugin-owned background components even if the native modal has already closed.
function backgroundView:Destroy()
    pcall(function() self:Clear() end)
    pcall(function() self.layer:Destroy() end)
end

-- Load and display a background, rebuilding artwork only when its source or geometry changes.
function backgroundView:Show(background, width, height, vignette)
    local image = background.sprites or background.sprite or background.image
    if image == nil then
        error("Background resource missing (set image to a Plugin.resources reference, or use sprite/sprites)")
    end

    if background.sprites == nil and background.sprite == nil and not image.loaded then
        local result = image:Load()
        if not image.loaded then
            error("Image load failed: " .. tostring(image.path) .. ": " .. tostring(result))
        end
    end

    local crop = geometry.Bounds(background)
    local view = table.concat({
        background.width, 
        background.height, 
        crop.x, 
        crop.y,
        crop.width, 
        crop.height, 
        width, 
        height
    }, ":")

    if self.image ~= image or self.view ~= view then
        self:Clear()
    end

    self.layer:SetSize(width, height)

    if self.artwork == nil then
        self.artwork = ui.Layer.new(self.layer)
        self.artwork:SetSize(width, height)
        self.artwork.clickthrough = true

        if background.sprites ~= nil then
            local grid = background.sprites
            assert(type(grid) == "table" and #grid > 0, "Background sprites must contain rows")

            local columns = type(grid[1]) == "table" and #grid[1] or 0
            assert(columns > 0, "Each background sprite row must be a non-empty table")

            for _, row in ipairs(grid) do
                assert(type(row) == "table" and #row == columns, "Background sprite rows must have equal lengths")
                for _, spriteID in ipairs(row) do
                    assert(type(spriteID) == "number", "Background tiles must be numeric sprite IDs")
                end
            end

            -- Shared rounded tile boundaries prevent seams, including across cropped maps.
            for rowIndex, row in ipairs(grid) do
                for columnIndex, spriteID in ipairs(row) do
                    local x, y, tileWidth, tileHeight = geometry.Rectangle(
                        background,
                        (columnIndex - 1) * background.width / columns,
                        (rowIndex - 1) * background.height / #grid,
                        background.width / columns, 
                        background.height / #grid, 
                        width, 
                        height
                    )

                    local tile = ui.Sprite.new(self.artwork)
                    tile:SetPos(x, y)
                    tile:SetSize(tileWidth, tileHeight)
                    tile.spriteID = spriteID
                    tile.clickthrough = true
                end
            end
        else
            local x, y, fullWidth, fullHeight = geometry.Rectangle(
                background,
                0, 0, 
                background.width, background.height, 
                width, height
            )

            self.sprite = prettyui.Sprite.new(
                self.artwork, 
                image, 
                {
                    x = x, 
                    y = y, 
                    width = fullWidth, 
                    height = fullHeight,
                }
            )
        end
        
        self.artwork:MoveToBack()
    end

    if vignette == nil then
        vignette = background.vignette
    end

    if vignette == nil then
        vignette = true
    end

    self:ShowVignette(vignette, width, height)

    self.image, self.view = image, view
    self.layer.hidden = false
    self.layer:MoveToFront()
end

return backgroundView
