local TitledFrame = {}

local function sprite(parent, spriteID)
    local control = ui.Sprite.new(parent)
    control.spriteID = spriteID
    control.clickthrough = true
    return control
end

-- Native modal artwork follows the returned layer's size; the caller owns the layer.
function TitledFrame.New(parent, title)
    local root = ui.Layer.new(parent)
    root.clickthrough = true

    local background = sprite(root, id.Sprite.RS3_MODAL_WINDOW_CONTENT_TILE)
    background:SetPos(8, 32)
    background:SetSize(-16, -40, 1.0, 1.0)
    background.isTiling = true

    local left = sprite(root, id.Sprite.RS3_MODAL_WINDOW_1_SIDE_TILE)
    left:SetPos(0, 32)
    left:SetSize(8, -48, 0, 1.0)
    left.isTiling = true

    local right = sprite(root, id.Sprite.RS3_MODAL_WINDOW_1_SIDE_TILE)
    right:SetPos(-8, 32, 1.0, 0)
    right:SetSize(8, -48, 0, 1.0)
    right.isTiling = true
    right.isFlippedHorizontally = true

    local bottom = sprite(root, id.Sprite.RS3_MODAL_WINDOW_1_BOTTOM_TILE)
    bottom:SetPos(16, -8, 0, 1.0)
    bottom:SetSize(-32, 8, 1.0, 0)
    bottom.isTiling = true

    local bottomLeft = sprite(root, id.Sprite.RS3_MODAL_WINDOW_1_BOTTOM_CORNER)
    bottomLeft:SetPos(0, -16, 0, 1.0)
    bottomLeft:SetSize(16, 16)

    local bottomRight = sprite(root, id.Sprite.RS3_MODAL_WINDOW_1_BOTTOM_CORNER)
    bottomRight:SetPos(-16, -16, 1.0, 1.0)
    bottomRight:SetSize(16, 16)
    bottomRight.isFlippedHorizontally = true

    local headerLeft = sprite(root, id.Sprite.RS3_MODAL_WINDOW_1_TITLE_CORNER)
    headerLeft:SetSize(28, 32)

    local headerTile = sprite(root, id.Sprite.RS3_MODAL_WINDOW_1_TITLE_TILE)
    headerTile:SetPos(28, 0)
    headerTile:SetSize(-56, 32, 1.0, 0)
    headerTile.isTiling = true

    local headerRight = sprite(root, id.Sprite.RS3_MODAL_WINDOW_1_TITLE_CORNER)
    headerRight:SetPos(-28, 0, 1.0, 0)
    headerRight:SetSize(28, 32)
    headerRight.isFlippedHorizontally = true

    local heading = ui.Text.new(root)
    heading:SetPos(10, 2)
    heading:SetSize(-20, 28, 1.0, 0)
    heading.content = title
    heading.font = id.Font.CINZEL_13PT_BOLD
    heading.rgba = 0xF4E4B8FF
    heading.maxLines = 1
    heading:AlignTo(ui.AlignMode.CENTRE)
    heading.clickthrough = true

    return root
end

return TitledFrame
