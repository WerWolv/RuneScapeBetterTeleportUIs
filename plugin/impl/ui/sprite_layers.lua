local cleanup = require("impl/cleanup")
local log = require("impl/log")

local SpriteLayers = {}
SpriteLayers.__index = SpriteLayers

local function isArray(image)
    return type(image) == "table" and (image[1] ~= nil or next(image) == nil)
end

-- Image resources are objects; only plain sequences represent layered artwork.
function SpriteLayers.LoadImages(images)
    if images == nil then
        return false
    end

    local array = isArray(images)
    local count = array and #images or 1
    local ready = count > 0

    for index = 1, count do
        local image = array and images[index] or images

        if type(image) ~= "number" then
            if not image.loaded then
                local result = image:Load()

                if not image.loaded then
                    log.Once("Image load failed: " .. tostring(image.path) .. ": " .. tostring(result))
                end
            end

            ready = image.loaded and ready
        end
    end

    return ready
end

-- All layers share a rectangle. Array order is back-to-front, including after state changes.
function SpriteLayers.New(parent, images, bounds)
    local root = prettyui.NewComponent(ui.Layer, parent, { categoryID = "auto" })
    root:SetPos(bounds.x or 0, bounds.y or 0)
    root:SetSize(bounds.width, bounds.height)
    root.clickthrough = true

    local self = setmetatable({
        root = root,
        sprites = {},
        images = {},
    }, SpriteLayers)
    self:SetSprite(images)

    return self
end

function SpriteLayers:SetSprite(images)
    -- Resources must load in their owning plugin, before PrettyUI assigns them
    -- to a native sprite from the dependency's execution context.
    if images ~= nil and not SpriteLayers.LoadImages(images) then
        self.root.hidden = true
        return false
    end

    self.root.hidden = false
    local array = isArray(images)
    local count = images == nil and 0 or array and #images or 1

    -- Keep spare controls for states with fewer layers, avoiding allocation churn on hover.
    for index = count + 1, #self.sprites do
        self.sprites[index].root.hidden = true
    end

    for index = 1, count do
        local image = array and images[index] or images
        local sprite = self.sprites[index]

        if sprite == nil then
            sprite = prettyui.Sprite.new(self.root, image, {
                width = self.root.width,
                height = self.root.height,
            })
            sprite.root:SetSize(0, 0, 1, 1)
            sprite.root.clickthrough = true

            self.sprites[index] = sprite
        elseif self.images[index] ~= image then
            sprite:SetSprite(image)
        end

        if self.images[index] ~= image then
            if self.rgba ~= nil then
                sprite.root.rgba = self.rgba
            end
            if self.alpha ~= nil then
                sprite.root.alpha = self.alpha
            end
        end

        sprite.root.hidden = false
        self.images[index] = image
    end

    self.count = count
    return true
end

-- Native layers do not propagate tint or opacity to their drawable children.
function SpriteLayers:SetRGBA(color)
    if self.rgba == color and self.alpha == (color & 0xFF) / 255 then
        return
    end

    self.rgba = color
    self.alpha = (color & 0xFF) / 255

    for _, sprite in ipairs(self.sprites) do
        sprite.root.rgba = color
    end
end

function SpriteLayers:SetAlpha(alpha)
    if self.alpha == alpha then
        return
    end

    self.alpha = alpha

    for _, sprite in ipairs(self.sprites) do
        sprite.root.alpha = alpha
    end
end

function SpriteLayers:Destroy()
    for index = #self.sprites, 1, -1 do
        cleanup.Release(self.sprites, index)
    end

    cleanup.Release(self, "root")
end

return SpriteLayers
