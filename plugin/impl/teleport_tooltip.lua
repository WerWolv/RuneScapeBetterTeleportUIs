local text = require("impl/text")
local teleportTooltip = {}
local maxWidth = 240
local paddingX, paddingY = 8, 5
local separatorGap = 7

local function lines(value)
    local normalized = value:gsub("<br%s*/?>", "\n"):gsub("\n$", "")
    return (normalized .. "\n"):gmatch("(.-)\n")
end

local function textWidth(font, value)
    local width = 0

    for line in lines(value) do
        local ok, measured = pcall(function()
            return font:GetStringWidth(line, false)
        end)

        width = math.max(width, ok and measured or #text.StripFormatting(line) * 7)
    end

    return width
end

local function textHeight(font, value, width)
    local ok, height = pcall(function()
        return font:GetStringHeightAndLineCount(value, width, font.baseline, false, false, false)
    end)

    if ok then
        return math.max(18, height)
    end

    local lineCount = 0

    for line in lines(value) do
        lineCount = lineCount + math.max(1, math.ceil(textWidth(font, line) / width))
    end

    return lineCount * (font.baseline or 18)
end


-- Attach a tooltip with title and optional description to the cursor
function teleportTooltip.Attach(target, parent, title, description)
    if text.IsBlank(description) then
        return prettyui.Tooltip.attach(target, parent, {
            text = title,
            maxWidth = maxWidth,
        }, {followCursor = true})
    end

    local font = config.Font.MUSEO_SANS_15PT_REGULAR
    local width = math.max(
        40,
        math.max(textWidth(font, title), textWidth(font, description)) + paddingX * 4
    )

    -- Reserve separate regions so the title, divider, and wrapped description cannot overlap.
    local contentWidth = width - paddingX * 2
    local titleHeight = textHeight(font, title, contentWidth)
    local descriptionHeight = textHeight(font, description, contentWidth)
    local separatorY = paddingY + titleHeight + separatorGap
    local descriptionY = separatorY + 1 + separatorGap

    local tooltip = prettyui.Tooltip.attach(target, parent, {
        text = title,
        width = width,
        height = descriptionY + descriptionHeight + paddingY,
    }, {followCursor = true})

    tooltip.label:SetPos(paddingX, paddingY)
    tooltip.label:SetSize(contentWidth, titleHeight)

    local separator = ui.Rectangle.new(tooltip.root)
    separator:SetPos(paddingX, separatorY)
    separator:SetSize(contentWidth, 1)
    separator.fill = true
    separator.rgba = 0xAFA27F80
    separator.clickthrough = true

    local body = ui.Text.new(tooltip.root)
    body:SetPos(paddingX, descriptionY)
    body:SetSize(contentWidth, descriptionHeight)
    body.font = id.Font.MUSEO_SANS_15PT_REGULAR
    body.content = description
    body.rgba = 0xD4CBB9FF
    body.maxLines = 0
    body.clickthrough = true

    return tooltip
end

return teleportTooltip
