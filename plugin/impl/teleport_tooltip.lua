local teleportTooltip = {}
local maxWidth = 240
local paddingX, paddingY = 8, 5
local separatorGap = 7

local function textWidth(font, text)
    local ok, width = pcall(function() return font:GetStringWidth(text, false) end)
    return ok and width or #text * 7
end

local function textHeight(font, text, width)
    local ok, height = pcall(function()
        return font:GetStringHeightAndLineCount(text, width, font.baseline, false, false, false)
    end)
    return ok and math.max(18, height) or math.max(1, math.ceil(#text * 7 / width)) * 18
end

function teleportTooltip.Attach(target, parent, title, description)
    if description == nil or description:match("^%s*$") then
        return prettyui.Tooltip.attach(target, parent, {
            text = title,
            maxWidth = maxWidth,
        }, {followCursor = true})
    end

    local font = config.Font.MUSEO_SANS_15PT_REGULAR
    local width = math.max(
        40, math.min(maxWidth,
            math.max(
                textWidth(font, title), 
                textWidth(font, description)
            ) + paddingX * 2
        )
    )

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
