local placement = require("impl/map_label_layout")
local components = require("impl/ui/components")
local cleanup = require("impl/cleanup")

local MapLabels = {}
MapLabels.__index = MapLabels
MapLabels.expansionPadding = 6
local paddingX, paddingY, shadowSize = 6, 3, 2

local function framedLabel(parent)
    local root = prettyui.NewComponent(ui.Layer, parent)
    root.clickthrough = true

    local shadow = prettyui.NewComponent(ui.Rectangle, root)
    shadow:SetPos(shadowSize, shadowSize)
    shadow:SetSize(-shadowSize, -shadowSize, 1, 1)
    shadow.fill = true
    shadow.rgba = 0x00000080
    shadow.clickthrough = true

    local background = prettyui.NewComponent(ui.Sprite, root)
    background:SetSize(-shadowSize, -shadowSize, 1, 1)
    background.spriteID = id.Sprite.RS3_MODAL_WINDOW_CONTENT_TILE
    background.isTiling = true
    background.clickthrough = true

    local border = prettyui.NewComponent(ui.Rectangle, root)
    border:SetSize(-shadowSize, -shadowSize, 1, 1)
    border.fill = false
    border.outlineThickness = 1
    border.rgba = 0x897952FF
    border.clickthrough = true

    local text = components.CenteredLabel(root, id.Font.MUSEO_SANS_13PT_REGULAR)
    text:SetPos(paddingX, paddingY)
    text:SetSize(-paddingX * 2 - shadowSize, -paddingY * 2 - shadowSize, 1, 1)
    text.rgba = 0xFFE3A3FF
    return { control = root, text = text, background = background, border = border, shadow = shadow }
end

function MapLabels.New(parent)
    return setmetatable({
        parent = parent, labels = {}, obstacles = {}, measurements = {}, plans = {}, planCount = 0,
    }, MapLabels)
end

-- Menus can reserve decorative controls such as counters and map legends.
function MapLabels:AddObstacle(control)
    self.obstacles[#self.obstacles + 1] = control
end

function MapLabels.ControlBounds(control, parent)
    if control == nil or control.hidden or not control.visibleGlobal then
        return nil
    end
    local position, origin = control.xyGlobal, parent.xyGlobal
    return {
        x = position.x - origin.x, y = position.y - origin.y,
        width = control.width, height = control.height,
    }
end

local function rectangleKey(rect)
    return table.concat({ rect.x, rect.y, rect.width, rect.height }, ",")
end

function MapLabels:Hide()
    if self.root ~= nil then
        self.root.hidden = true
    end
end

-- Keep words intact, including UTF-8 names. Each alternative includes the frame.
function MapLabels:Measure(value)
    local name = (value or ""):gsub("<br%s*/?>", " "):gsub("[\r\n]", " ")
    if self.measurements[name] ~= nil then
        return name, self.measurements[name]
    end
    local font = config.Font.MUSEO_SANS_13PT_REGULAR
    local lineHeight = math.ceil(math.max(font.baseline, font.maxAscent + font.maxDescent))
    local variants, seen = {}, {}
    local function add(lines)
        local content = table.concat(lines, "<br>")
        if seen[content] then return end
        seen[content] = true
        local width = 1
        for _, line in ipairs(lines) do
            width = math.max(width, math.ceil(font:GetStringWidth(line, false)))
        end
        variants[#variants + 1] = {
            content = content, lines = #lines,
            width = width + paddingX * 2 + shadowSize,
            height = lineHeight + (#lines - 1) * font.baseline + paddingY * 2 + shadowSize,
        }
    end
    add({ name })
    for _, limit in ipairs({ 140, 105, 70 }) do
        local lines, line = {}, ""
        for word in name:gmatch("%S+") do
            local nextLine = line == "" and word or line .. " " .. word
            if line ~= "" and font:GetStringWidth(nextLine, false) > limit then
                lines[#lines + 1], line = line, word
            else
                line = nextLine
            end
        end
        if line ~= "" then lines[#lines + 1] = line end
        if #lines > 1 and #lines <= 3 then add(lines) end
    end
    self.measurements[name] = variants
    return name, variants
end

-- Planning is independent of controls, so a map can test a larger crop before
-- resizing its native window. Cache a small set of recent candidate layouts.
function MapLabels:Plan(items, obstacles, width, height, margins, allowWrap, uniformOnly)
    local measured = {}
    local signature = { tostring(width), tostring(height), tostring(allowWrap ~= false), tostring(uniformOnly == true) }
    for _, item in ipairs(items) do
        local name, variants = self:Measure(item.name)
        if name ~= "" then
            measured[#measured + 1] = {
                key = item.key, name = name, variants = variants, anchor = item.anchor, alpha = item.alpha,
            }
            signature[#signature + 1] = string.format("%q:%q:%s", tostring(item.key), name, rectangleKey(item.anchor))
        end
    end
    for _, rect in ipairs(obstacles or {}) do
        signature[#signature + 1] = "obstacle:" .. rectangleKey(rect)
    end
    if margins then
        signature[#signature + 1] = table.concat({ margins.left, margins.top, margins.right, margins.bottom }, ",")
    end
    local key = table.concat(signature, "|")
    if self.plans[key] == nil then
        if self.planCount >= 16 then
            self.plans, self.planCount = {}, 0
        end
        self.plans[key] = placement.Place(measured, obstacles, width, height, margins, allowWrap, uniformOnly) or false
        self.planCount = self.planCount + 1
    end
    return self.plans[key], measured
end

-- Items: { key, name, anchor, alpha? }. All rectangles are parent-local pixels.
function MapLabels:Update(items, obstacles, width, height, edgePadding)
    if self.root == nil then
        self.root = prettyui.NewComponent(ui.Layer, self.parent, { categoryID = "auto" })
        self.root.clickthrough = true
    end
    if self.width ~= width or self.height ~= height then
        self.root:SetSize(width, height)
        self.width, self.height = width, height
    end

    local reserved = {}
    for _, rect in ipairs(obstacles or {}) do
        reserved[#reserved + 1] = rect
    end
    for _, control in ipairs(self.obstacles) do
        local rect = MapLabels.ControlBounds(control, self.parent)
        if rect ~= nil then
            reserved[#reserved + 1] = rect
        end
    end
    local inset
    if edgePadding and edgePadding > 0 then
        inset = { left = -edgePadding, right = -edgePadding, top = -edgePadding, bottom = -edgePadding }
    end
    local positions, measured = self:Plan(items, reserved, width, height, inset)
    local visible = 0
    for index = 1, #measured do
        if positions[index] then visible = visible + 1 end
    end
    -- Apply this after all placement attempts, without affecting crop planning.
    self.root.hidden = visible * 2 < #measured
    local active = {}
    for index, item in ipairs(measured) do
        local rect = positions[index]
        if rect then
            local label = self.labels[item.key]
            if label == nil then
                label = framedLabel(self.root)
                self.labels[item.key] = label
            end
            if label.variant ~= rect.variant then
                label.variant, label.name = rect.variant, item.name
                label.text.content = rect.variant.content
                label.text.maxLines = rect.variant.lines
                label.width, label.height = rect.width, rect.height
                label.control:SetSize(label.width, label.height)
            end
            local alpha = item.alpha or 1
            if label.alpha ~= alpha then
                -- Layers do not propagate opacity to their drawable children.
                label.text.alpha = alpha
                label.background.alpha = alpha
                label.border.alpha = alpha
                label.shadow.alpha = alpha * 0.5
                label.alpha = alpha
            end
            active[item.key] = true
            label.control.hidden = false
            if label.x ~= rect.x or label.y ~= rect.y then
                label.control:SetPos(rect.x, rect.y)
                label.x, label.y = rect.x, rect.y
            end
        elseif self.labels[item.key] then
            active[item.key] = true
            self.labels[item.key].control.hidden = true
        end
    end
    for key, label in pairs(self.labels) do
        if not active[key] then
            label.control:Destroy()
            self.labels[key] = nil
        end
    end

end

function MapLabels:Destroy()
    cleanup.Release(self, "root")
    self.labels, self.obstacles = {}, {}
    self.measurements, self.plans, self.planCount = {}, {}, 0
end

return MapLabels
