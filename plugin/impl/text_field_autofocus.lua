-- Native-keyboard bridge adapted from PrettyRS/fairyrings (BSD-3-Clause).
-- See licenses/PRETTYRS_FAIRYRINGS_LICENSE.

local TextFieldAutoFocus = {}
TextFieldAutoFocus.__index = TextFieldAutoFocus

local function encodeCharacter(code)
    if code < 0x80 then
        return string.char(code)
    elseif code < 0x800 then
        return string.char(0xC0 + code // 64, 0x80 + code % 64)
    elseif code < 0x10000 then
        return string.char(0xE0 + code // 4096, 0x80 + code // 64 % 64, 0x80 + code % 64)
    end

    return string.char(
        0xF0 + code // 262144,
        0x80 + code // 4096 % 64,
        0x80 + code // 64 % 64,
        0x80 + code % 64
    )
end

-- The caller owns the field/listener and chooses which keys retain their native behavior.
function TextFieldAutoFocus:New(field, listener, options)
    return setmetatable({
        field = field,
        listener = listener,
        hookID = options.hookID,
        forwardKey = options.forwardKey,
        font = options.font,
        focused = false,
        selected = false,
    }, self)
end

function TextFieldAutoFocus:Attach()
    self.caret = ui.Rectangle.new(self.field.root.parent)
    self.caret.fill = true
    self.caret.clickthrough = true

    self.onChange = self.field.onChange
    self.handleChange = function(field, reason, value)
        self.selected = false

        -- Programmatic edits can emit delayed changes without giving the field focus.
        if reason == ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS
            or reason == ui.InputFieldActionResult.SUBMIT_ON_ESCAPE then
            self.focused = false
        end

        self.blinkStart = self.tick or 0
        self:UpdateCaret()

        if self.onChange then
            self.onChange(field, reason, value)
        end
    end
    self.field.onChange = self.handleChange

    self.field.root:Subscribe(ui.Hook.ONCLICK, self.hookID, function()
        self.focused = true
        self.selected = false
        self:UpdateCaret()

        return true
    end)

    self.listener:Subscribe(ui.Hook.ONKEY, self.hookID, function(_, key, character)
        return self:OnKey(key, character)
    end)

    Event.Logic.Subscribe(self.hookID, function(event)
        if self.tick == nil then
            self.blinkStart = event.logicTick
        end

        self.tick = event.logicTick
        self:UpdateCaret()
    end)

    self:UpdateCaret()
end

-- Draw beside the supplied field so its background cannot cover the fake caret.
function TextFieldAutoFocus:UpdateCaret()
    local root = self.field.root
    local caret = self.caret

    caret.hidden = self.focused or self.selected or not root.visibleGlobal
        or root.enabled == false or Keyboard.IsBlocked()
        or ((self.tick or 0) - (self.blinkStart or 0)) % 50 >= 25

    if caret.hidden then
        return
    end

    local value = self.field:GetText()
    local margin = root.contentMargin
    local _, length = value:gsub("[^\128-\191]", "")
    local width = length * 8
    local height = 18

    local ok, measuredWidth, measuredHeight = pcall(function()
        local font = self.font or config.Font.FromID(root.text.font)

        return font:GetStringWidth(value, false), font.baseline
    end)

    if ok then
        width = measuredWidth
        height = measuredHeight
    end

    local availableWidth = root.width - margin.left - margin.right
    local availableHeight = root.height - margin.top - margin.bottom

    if availableWidth < 1 or availableHeight < 1 then
        caret.hidden = true
        return
    end

    height = math.min(height, availableHeight) - 2

    caret:SetPos(
        root.x + 2 + margin.left + math.min(width, availableWidth - 1),
        root.y - 2 + margin.top + math.floor((availableHeight - height) / 2)
    )
    caret:SetSize(1, height)
    caret.rgba = root.caretRGBA
    caret.alpha = root.alpha
    caret:MoveToFront()
end

function TextFieldAutoFocus:OnKey(key, character)
    if self.focused or not self.field.root.visibleGlobal or Keyboard.IsBlocked() then
        return true
    end

    if self.forwardKey and self.forwardKey(key, character) then
        return true
    end

    local value = self.field:GetText()
    local control = Keyboard.IsControlDown()

    if character == 1 or (control and key == GameKey.A) then
        self.selected = value ~= ""
        self:UpdateCaret()

        return false
    end

    if control or Keyboard.IsAltDown() or Keyboard.IsMetaDown() then
        return true
    end

    if key == GameKey.BACKSPACE then
        -- Remove the final leading byte together with all of its continuation bytes.
        value = self.selected and "" or value:gsub("[^\128-\191][\128-\191]*$", "")
    elseif character == 8 or character == 127 then
        -- The character event must not delete again after the Backspace key event.
        return false
    elseif key == GameKey.ESCAPE and value ~= "" then
        value = ""
    elseif key == GameKey.DELETE and self.selected then
        value = ""
    elseif character ~= nil and character >= 32 and character <= 0x10FFFF
        and (character < 0xD800 or character > 0xDFFF) then
        value = self.selected and "" or value

        local _, length = value:gsub("[^\128-\191]", "")

        if length < self.field.root.maxLength then
            value = value .. encodeCharacter(character)
        end
    else
        return true
    end

    self.selected = false

    local changed = value ~= self.field:GetText()
    self.field:SetText(value, false)
    self.blinkStart = self.tick or 0
    self:UpdateCaret()

    if changed and self.onChange then
        self.onChange(self.field, ui.InputFieldActionResult.CONTENT_CHANGE, value)
    end

    return false
end

function TextFieldAutoFocus:Destroy()
    Event.Logic.Unsubscribe(self.hookID)

    if self.caret ~= nil then
        pcall(function()
            self.caret:Destroy()
        end)
        self.caret = nil
    end

    pcall(function()
        self.listener:Unsubscribe(ui.Hook.ONKEY, self.hookID)
    end)

    pcall(function()
        self.field.root:Unsubscribe(ui.Hook.ONCLICK, self.hookID)
    end)

    if self.field.onChange == self.handleChange then
        self.field.onChange = self.onChange
    end
end

return TextFieldAutoFocus
