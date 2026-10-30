local StringSetting = require("impl/settings/string")
local aliases = require("impl/fairy_ring_aliases")
local text = require("impl/text")
local FairyRingAliases = StringSetting:Extend()

function FairyRingAliases:CreateControl(host)
    self:AddLabel(host)
    self:AddDescription(host)

    local codes = {}

    for first in ("ABCD"):gmatch(".") do
        for middle in ("IJKL"):gmatch(".") do
            for last in ("PQRS"):gmatch(".") do
                codes[#codes + 1] = first .. middle .. last
            end
        end
    end

    local editor = { codes = codes, buttons = {} }
    editor.field = host:AddTextField({
        placeholder = "Alias name",
        width = -206,
        widthAnchor = 1,
        onChange = function() self:UpdateRegisterButton() end,
    })

    host:AddSprite(id.Sprite.V2_BOOK_ARROWS_4, {
        inline = true, x = -184, xAnchor = 1, width = 24, height = 24, offsetY = 3,
    })
    editor.destination = host:AddComboBox({
        entries = codes,
        selectedID = 1,
        inline = true,
        x = -152,
        xAnchor = 1,
        width = 100,
        onChange = function() self:UpdateRegisterButton() end,
    })

    editor.register = host:AddSimpleButton(id.Sprite.RS3_ICON_ADDITIONAL_50PX_2, function()
        self:RegisterAlias()
    end, {
        inline = true, x = -44, xAnchor = 1, width = 30, height = 30,
        iconSize = 22, disabled = true
    })
    -- SimpleButton's constructor does not apply position anchors.
    editor.register.root:SetPos(-44, editor.register.root.y, 1)

    -- Disabled buttons receive no hover events. Use an enabled sibling as the error target.
    local buttonParent = editor.register.root.parent
    editor.errorTarget = ui.Layer.new(buttonParent)
    editor.errorTarget:SetPos(-44, editor.register.root.y, 1)
    editor.errorTarget:SetSize(30, 30)
    editor.errorTarget.enabled = true
    editor.errorTarget.clickthrough = false
    editor.errorTarget.hidden = true
    editor.errorTarget:Subscribe(ui.Hook.ONCLICK, function() return false end)

    local destroyButton = editor.register.Destroy
    editor.register.Destroy = function(button)
        if editor.errorTooltip then editor.errorTooltip:Destroy() end
        editor.errorTarget:Destroy()
        destroyButton(button)
    end

    host:AddText({ text = "Alias", height = 24 })
    host:AddText({ text = "Ring code", inline = true, x = -146, xAnchor = 1, width = 90, height = 24 })
    local list = host:AddList({ height = 210, entryHeight = 30 })
    editor.list = list

    list.root:Subscribe(ui.Hook.ONRESIZE, function()
        list:SetScrollPosition(list.scrollY)
    end)

    -- Release PrettyUI button state before the list destroys its native row layers.
    local destroy = list.Destroy
    list.Destroy = function(control)
        self:ClearButtons()
        destroy(control)
    end

    return editor
end

function FairyRingAliases:GetAliasError(name, code)
    if name == "" then
        return "Enter an alias name."
    end

    if code == nil then
        return "Choose a ring code."
    end

    for _, existing in ipairs(self.control.entries[code] or {}) do
        if existing:lower() == name:lower() then
            return "This alias is already registered for " .. code .. "."
        end
    end
end

function FairyRingAliases:UpdateRegisterButton()
    local editor = self.control
    local name = text.Clean(editor.field:GetText())
    local code = editor.codes[editor.destination:GetSelectedID()]
    local message = self:GetAliasError(name, code)

    editor.register:SetDisabled(message ~= nil)
    if message then
        if editor.errorTooltip then
            editor.errorTooltip:SetText(message)
        else
            editor.errorTooltip = prettyui.Tooltip.attach(editor.errorTarget, editor.errorTarget.parent, {
                text = message,
            }, { followCursor = true })
        end
        editor.errorTarget.hidden = false
        editor.errorTarget:MoveToFront()
    else
        if editor.errorTooltip then editor.errorTooltip:Destroy() end
        editor.errorTooltip = nil
        editor.errorTarget.hidden = true
    end
end

function FairyRingAliases:RegisterAlias()
    local editor = self.control
    local name = text.Clean(editor.field:GetText())
    local code = editor.codes[editor.destination:GetSelectedID()]

    if self:GetAliasError(name, code) ~= nil then
        self:UpdateRegisterButton()
        return
    end

    editor.entries[code] = editor.entries[code] or {}
    editor.entries[code][#editor.entries[code] + 1] = name
    self:Set(aliases.Serialize(editor.entries))
    editor.field:SetText("", false)
    self:UpdateRegisterButton()
end

function FairyRingAliases:RemoveAlias(code, index)
    table.remove(self.control.entries[code], index)
    self:Set(aliases.Serialize(self.control.entries))
end

function FairyRingAliases:ClearButtons()
    for _, button in ipairs(self.control.buttons) do
        button:Destroy()
    end

    self.control.buttons = {}
end

function FairyRingAliases:UpdateControl()
    local editor = self.control
    editor.entries = aliases.Parse(self.value)
    local rows = {}

    for code, names in pairs(editor.entries) do
        for index, name in ipairs(names) do
            rows[#rows + 1] = { label = name, code = code, index = index }
        end
    end

    table.sort(rows, function(a, b)
        if a.label:lower() == b.label:lower() then
            return a.code < b.code
        end

        return a.label:lower() < b.label:lower()
    end)

    self:ClearButtons()
    editor.list:SetEntries(rows)

    for index, row in ipairs(editor.list.rows) do
        local entry = rows[index]
        row.label:SetSize(-144, 30, 1)
        row.label.clickthrough = true
        prettyui.Text.new(row.root, {
            text = entry.code, x = -128, xAnchor = 1, width = 80, height = 30,
        }).clickthrough = true
        local button = prettyui.Sprite.new(row.root, id.Sprite.AIF_COMBAR_TRASHCAN_0, {
            x = -30, y = 3, xAnchor = 1, width = 24, height = 24,
        })
        button.root.clickthrough = false
        button.root:Subscribe(ui.Hook.ONMOUSEOVER, function()
            button.root.spriteID = id.Sprite.AIF_COMBAR_TRASHCAN_1
            return true
        end)
        button.root:Subscribe(ui.Hook.ONMOUSELEAVE, function()
            button.root.spriteID = id.Sprite.AIF_COMBAR_TRASHCAN_0
            return true
        end)
        button.root:Subscribe(ui.Hook.ONCLICK, function()
            self:RemoveAlias(entry.code, entry.index)
            return false
        end)
        editor.buttons[#editor.buttons + 1] = button
    end

    self:UpdateRegisterButton()
end

return FairyRingAliases
