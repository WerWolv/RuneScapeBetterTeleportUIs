local StringSetting = require("impl/settings/string")
local Categories = require("impl/teleport_categories")
local IconGrid = require("impl/teleport_icon_grid")
local text = require("impl/text")

local CategorySetting = StringSetting:Extend()
local rowHeight = 30

function CategorySetting:CreateControl(host)
    local editor = { rows = {} }
    local definition = self.definition.categories

    -- Resolve the menu after the shared settings registry has finished loading.
    local menu = require(definition.menu):New()
    local names = {}

    for name, destination in pairs(menu.definition.entries) do
        names[destination.categoryKey or name] = destination
    end

    editor.destinations = {}
    for name in pairs(names) do
        editor.destinations[#editor.destinations + 1] = name
    end

    table.sort(editor.destinations)

    editor.category = host:AddList({
        height = 1, entryHeight = rowHeight, width = -12, widthAnchor = 0.36,
        _onEntryClick = function(_, categoryID)
            if not editor.updating then
                self:SelectCategory(categoryID)
            end
        end,
    })
    editor.onScrollWheel = function(component, delta)
        return editor.category:_OnScrollWheel(component, delta)
    end

    editor.creation = ui.Layer.new(host.content)
    editor.creation:SetSize(-12, rowHeight, 0.36, 0)
    editor.newName = prettyui.TextField.new(editor.creation, {
        x = 0, y = 1, width = -34, widthAnchor = 1, height = rowHeight - 2,
        placeholder = "New category", maxLength = 40,
        onChange = function(_, reason)
            if self.control ~= editor or editor.updating or editor.closed then return end
            if reason == ui.InputFieldActionResult.SUBMIT then
                self:CreateCategory()
            else
                self:UpdateCreateState()
            end
        end,
    })
    editor.create = prettyui.SimpleButton.new(editor.creation, id.Sprite.RS3_ICON_ADDITIONAL_50PX_2, function()
        self:CreateCategory()
    end, {
        x = -28, y = 1, xAnchor = 1, width = 28, height = 28, iconSize = 20, disabled = true,
    })

    local eventID = "teleportMapsCategoryMenu:" .. self.definition.key
    Event.MiniMenuReady.Subscribe(eventID, function(event)
        if self.control ~= editor or editor.closed or not editor.category.root.visibleGlobal
            or not editor.category.viewport.isMouseOver then
            return
        end

        for categoryID, control in pairs(editor.rows) do
            if control.row.root.isMouseOver and not control.delete.root.isMouseOver
                and editor.editingID ~= categoryID then
                local function available()
                    return self.control == editor and not editor.closed and editor.category.root.visibleGlobal
                        and self:GetCategory(categoryID) ~= nil
                end

                event.miniMenu:Add("Rename", function()
                    if available() then self:BeginRename(categoryID) end
                end)
                -- Native menu entries display in reverse order; keep selection as the default action.
                event.miniMenu:Add("Select", function()
                    if available() then self:SelectCategory(categoryID) end
                end)
                return
            end
        end
    end)

    local setScrollPosition = editor.category.SetScrollPosition
    editor.category.SetScrollPosition = function(control, position)
        setScrollPosition(control, position)
        self:RefreshInputClipping(editor)
    end

    local destroy = editor.category.Destroy
    editor.category.Destroy = function(control)
        if editor.closed then return end
        editor.closed = true
        Event.MiniMenuReady.Unsubscribe(eventID)
        self:ClearCategoryControls(editor)
        editor.newName:Destroy()
        editor.create:Destroy()
        editor.creation:Destroy()
        if editor.grid ~= nil then
            editor.grid:Destroy()
        end

        destroy(control)
    end

    editor.grid = IconGrid.New(host.content)
    local entries = {}

    for _, name in ipairs(editor.destinations) do
        local destination = names[name]

        entries[#entries + 1] = {
            key = name,
            name = name,
            icons = menu.GetCategoryIcon and menu:GetCategoryIcon(destination)
                or destination.icons or menu.definition.icons,
        }
    end

    editor.grid:Build(entries, function(index)
        self:ToggleDestination(index)
    end)

    return editor
end

-- Both panes always fill the available height, including while validating names.
function CategorySetting:Layout(width, height)
    local editor = self.control
    local split = math.floor(width * 0.36)
    local bodyHeight = math.max(1, height)

    local listY = rowHeight + 4
    editor.creation:SetSize(math.max(1, split - 12), rowHeight)
    editor.category.root:SetPos(0, listY)
    editor.category:SetSize(math.max(1, split - 12), math.max(1, bodyHeight - listY))
    editor.grid:Layout(split, 0, math.max(1, width - split), bodyHeight)
end

function CategorySetting:GetCategory(categoryID)
    local editor = self.control

    if editor == nil or editor.data == nil then
        return nil
    end

    for _, category in ipairs(editor.data.entries) do
        if category.id == (categoryID or editor.selectedID) then
            return category
        end
    end
end

function CategorySetting:UpdateCreateState()
    local editor = self.control
    local name = text.Clean(editor.newName:GetText())
    local valid = Categories.NameError(name, editor.data, self.definition.categories.builtins) == nil
    editor.create:SetDisabled(not valid)
    return name, valid
end

function CategorySetting:ShowCategory()
    local editor = self.control
    local category = self:GetCategory()
    editor.category:UnselectAll()
    if category ~= nil then
        editor.category:SetSelected(category.id, true, false)
    end

    editor.grid:SetSelection(category and category.destinations or {}, category ~= nil)
end

function CategorySetting:SelectCategory(categoryID)
    if self:GetCategory(categoryID) == nil then
        return
    end

    self:FinishRename(ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
    self.control.selectedID = categoryID
    self:ShowCategory()
end

function CategorySetting:CreateCategory()
    local editor = self.control
    self:FinishRename(ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
    local name, valid = self:UpdateCreateState()

    if not valid then
        return
    end

    local category = { id = editor.data.nextID, name = name, destinations = {} }
    editor.data.nextID = category.id + 1
    editor.data.entries[#editor.data.entries + 1] = category
    editor.selectedID = category.id
    editor.newName:SetText("", false)
    self:Set(Categories.Serialize(editor.data))
end

function CategorySetting:ToggleDestination(index)
    local editor = self.control
    local category = self:GetCategory()
    local destination = editor.destinations[index]

    if category ~= nil and destination ~= nil and not editor.updating then
        category.destinations[destination] = not category.destinations[destination] or nil
        self:Set(Categories.Serialize(editor.data))
    end
end

function CategorySetting:BeginRename(categoryID, draft)
    local editor = self.control
    if editor.editingID == categoryID then
        return
    end

    self:FinishRename(ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
    local category = self:GetCategory(categoryID)
    local control = editor.rows[categoryID]

    if category == nil or control == nil then
        return
    end

    editor.editingID = categoryID
    if control.input == nil then
        control.input = prettyui.TextField.new(control.row.root, {
            x = 4, y = 1, width = -38, widthAnchor = 1, height = rowHeight - 2,
            maxLength = 40,
            _onScrollWheel = editor.onScrollWheel,
            onChange = function(_, reason)
                if self.control ~= editor or editor.updating or editor.closed
                    or editor.editingID ~= categoryID then
                    return
                end

                if reason == ui.InputFieldActionResult.SUBMIT
                    or reason == ui.InputFieldActionResult.SUBMIT_ON_ESCAPE
                    or reason == ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS then
                    self:FinishRename(reason)
                end
            end,
        })
    end

    control.row.label.hidden = true
    control.input:SetText(draft or category.name, false)
    control.input.root.hidden = false

    local top = control.row.root.y
    local bottom = top + rowHeight - editor.category.viewport.height
    editor.category:SetScrollPosition(math.max(bottom, math.min(editor.category.scrollY, top)))
end

function CategorySetting:FinishRename(reason)
    local editor = self.control
    local categoryID = editor.editingID
    local control = editor.rows[categoryID]
    if control == nil then
        return
    end

    local category = self:GetCategory(categoryID)
    local name = text.Clean(control.input:GetText())
    local error = Categories.NameError(name, editor.data, self.definition.categories.builtins, categoryID)
    if error ~= nil and reason == ui.InputFieldActionResult.SUBMIT then
        return
    end

    -- Clear the editing state before hiding the input, which may emit focus loss.
    editor.editingID = nil
    control.input.root.hidden = true
    control.row.label.hidden = false

    if category ~= nil and error == nil and reason ~= ui.InputFieldActionResult.SUBMIT_ON_ESCAPE then
        category.name = name
        self:Set(Categories.Serialize(editor.data))
    end
end

function CategorySetting:DeleteCategory(categoryID)
    local editor = self.control

    for index, category in ipairs(editor.data.entries) do
        if category.id == categoryID then
            table.remove(editor.data.entries, index)
            if editor.selectedID == categoryID then
                editor.selectedID = nil
            end

            self:Set(Categories.Serialize(editor.data))
            return
        end
    end
end

function CategorySetting:RefreshInputClipping(editor)
    local function refresh(input, row)
        if input == nil then return end
        local top = row.root.y - editor.category.scrollY
        input:_SetContentClipped(top < 0 or top + rowHeight > editor.category.viewport.height)
    end

    for _, control in pairs(editor.rows) do
        refresh(control.input, control.row)
    end
end

function CategorySetting:ClearCategoryControls(editor)
    for _, control in pairs(editor.rows) do
        if control.input ~= nil then control.input:Destroy() end
        control.delete:Destroy()
    end

    editor.rows = {}
end

function CategorySetting:BuildCategoryControls(choices)
    local editor = self.control

    for index, row in ipairs(editor.category.rows) do
        local categoryID = choices[index].id
        row.label:SetSize(-40, rowHeight, 1.0, 0)
        row.label.clickthrough = true

        local button = prettyui.Sprite.new(row.root, id.Sprite.AIF_COMBAR_TRASHCAN_0, {
            x = -30, y = 3, xAnchor = 1, width = 24, height = 24,
            _onScrollWheel = editor.onScrollWheel,
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
            self:DeleteCategory(categoryID)
            return false
        end)

        editor.rows[categoryID] = { row = row, delete = button }
    end

    self:RefreshInputClipping(editor)
end

function CategorySetting:UpdateControl()
    local editor = self.control
    editor.updating = true
    editor.data = Categories.Parse(self.value)

    if self:GetCategory() == nil then
        editor.selectedID = editor.data.entries[1] and editor.data.entries[1].id or nil
    end

    local choices, labels = {}, {}
    for _, category in ipairs(editor.data.entries) do
        choices[#choices + 1] = { id = category.id, text = category.name }
        labels[#labels + 1] = category.id .. "\t" .. category.name
    end

    local signature = table.concat(labels, "\n")
    if editor.categorySignature ~= signature then
        local editingID = editor.editingID
        local editing = editor.rows[editingID]
        local renameDraft = editing and editing.input:GetText()
        editor.editingID = nil
        self:ClearCategoryControls(editor)
        editor.category:SetEntries(choices)
        self:BuildCategoryControls(choices)
        editor.categorySignature = signature
        if editingID ~= nil and self:GetCategory(editingID) ~= nil then
            self:BeginRename(editingID, renameDraft)
        end
    end

    self:UpdateCreateState()
    self:ShowCategory()
    editor.updating = false
end

return CategorySetting
