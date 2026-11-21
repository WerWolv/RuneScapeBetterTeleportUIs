local cleanup = require("impl/cleanup")

local InputShield = {}
InputShield.__index = InputShield

function InputShield.New(parent)
    local root = prettyui.NewComponent(ui.Layer, parent, { categoryID = "auto" })
    root.clickthrough = true

    return setmetatable({ root = root, tiles = {} }, InputShield)
end

-- Partition the window around native hitboxes. A solid overlay would also
-- swallow their actions because injected native controls cannot be reordered.
local function partition(width, height, holes)
    local cuts, seen, clipped = { 0, height }, { [0] = true, [height] = true }, {}

    for _, hole in ipairs(holes) do
        local left, top = math.max(0, hole.x), math.max(0, hole.y)
        local right, bottom = math.min(width, hole.x + hole.width), math.min(height, hole.y + hole.height)

        if right > left and bottom > top then
            clipped[#clipped + 1] = { left = left, top = top, right = right, bottom = bottom }

            for _, y in ipairs({ top, bottom }) do
                if not seen[y] then
                    cuts[#cuts + 1], seen[y] = y, true
                end
            end
        end
    end

    table.sort(cuts)

    local regions, previous = {}, {}

    for index = 1, #cuts - 1 do
        local top, bottom = cuts[index], cuts[index + 1]
        local intervals, current = {}, {}

        for _, hole in ipairs(clipped) do
            if hole.top < bottom and hole.bottom > top then
                intervals[#intervals + 1] = hole
            end
        end

        table.sort(intervals, function(a, b)
            return a.left < b.left
        end)

        local function fill(left, right)
            if right <= left then
                return
            end

            local key = left .. ":" .. right
            local region = previous[key]

            -- Merge equal gaps in adjacent bands to keep the input layer small.
            if region ~= nil then
                region.height = bottom - region.y
            else
                region = { x = left, y = top, width = right - left, height = bottom - top }
                regions[#regions + 1] = region
            end

            current[key] = region
        end

        local left = 0

        for _, interval in ipairs(intervals) do
            fill(left, interval.left)
            left = math.max(left, interval.right)
        end

        fill(left, width)
        previous = current
    end

    return regions
end

function InputShield:Layout(width, height, holes)
    local regions = partition(width, height, holes)
    self.root:SetSize(width, height)

    for index, region in ipairs(regions) do
        local tile = self.tiles[index]

        if tile == nil then
            tile = prettyui.NewComponent(ui.Layer, self.root)
            tile.enabled = true
            tile.clickthrough = false
            self.tiles[index] = tile
        end

        tile:SetPos(region.x, region.y)
        tile:SetSize(region.width, region.height)
        tile.hidden = false
    end

    for index = #regions + 1, #self.tiles do
        self.tiles[index].hidden = true
    end

    self.root:MoveToFront()
end

function InputShield:Destroy()
    cleanup.Release(self, "root")
    self.tiles = {}
end

return InputShield
