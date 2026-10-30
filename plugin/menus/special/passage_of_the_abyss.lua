local SlotMenu = require("impl/interfaces/slot_menu")
local userSettings = require("impl/settings")
local components = require("impl/components")
local HotkeyBadge = require("impl/hotkey_badge")
local descriptions = require("definitions/descriptions")

local PassageOfTheAbyss = SlotMenu:Extend("passageOfTheAbyss")

local slotCount, slotSize, slotGap, slotPadding = 6, 36, 4, 6

local function destinations(destinations)
    local result = descriptions.Location("Destinations:")

    for _, dest in ipairs(destinations) do
        result = result .. "        " .. dest .. "<br>"
    end

    return result
end

-- Define every compactable jewellery type independently of the player's six slot assignments.
function PassageOfTheAbyss:Define()
    return {
        title = "Passage of the Abyss",
        items = {
            ["amulet of glory"] = {
                item = id.Obj.AMULET_OF_GLORY_4,
                description = destinations({
                    "Edgeville",
                    "Karamja",
                    "Draynor Village",
                    "Al Kharid",
                }),
            },
            ["combat bracelet"] = {
                item = id.Obj.JEWL_BRACELET_OF_COMBAT_4,
                description = destinations({
                    "Warriors' Guild",
                    "Champions' Guild",
                    "Edgeville Monastery",
                    "Ranging Guild",
                }),
            },
            ["delver's anklet"] = {
                item = id.Obj.PLATINUM_DELVERS_ANKLET,
                description = destinations({
                    "Brimhaven Dungeon",
                    "Fremennik Slayer Dungeon",
                    "Polypore Dungeon",
                }),
            },
            ["dig site pendant"] = {
                item = id.Obj.NECKLACE_OF_DIGSITE_5,
                description = destinations({
                    "Varrock Dig Site",
                    "Senntisten Temple",
                    "Exam Centre",
                }),
            },
            ["enlightened amulet"] = {
                item = id.Obj.ENCHANTED_TOPAZ_AMULET_NEW,
                description = destinations({
                    "Lumbridge Swamp",
                    "South of the Graveyard of Shadows",
                    "Desert bandit camp entrance",
                }),
            },
            ["ferocious ring"] = {
                item = id.Obj.SLAYGUILD_RING_5,
                description = destinations({
                    "Kuradal",
                    "Morvran",
                }),
            },
            ["games necklace"] = {
                item = id.Obj.NECKLACE_OF_MINIGAMES_8,
                description = destinations({
                    "Troll Invasion",
                    "Barbarian Outpost",
                    "Gamers' Grotto",
                    "Agoroth",
                    "Corporeal Beast",
                    "Burgh de Rott",
                    "Tears of Guthix",
                }),
            },
            ["ring of duelling"] = {
                item = id.Obj.RING_OF_DUELING_8,
                description = destinations({
                    "Het's Oasis",
                    "Castle Wars Arena",
                    "Warforge Dig Site",
                    "Fist of Guthix",
                }),
            },
            ["ring of respawn"] = {
                item = id.Obj.ENCHANTED_JADE_RING_NEW,
                description = destinations({
                    "Lumbridge",
                    "Falador",
                    "Camelot",
                    "Soul Wars",
                    "Burthorpe",
                }),
            },
            ["ring of slaying"] = {
                item = id.Obj.SMKI_RING_OF_SLAYING_8,
                description = destinations({
                    "Pollnivneach (Sumona)",
                    "Morytania Slayer Tower",
                    "Fremennik Slayer Dungeon",
                    "Tarn's Lair",
                }),
            },
            ["ring of wealth"] = {
                item = id.Obj.RING_OF_WEALTH_4,
                description = destinations({
                    "Miscellania throne room",
                    "Grand Exchange",
                }),
            },
            ["skills necklace"] = {
                item = id.Obj.JEWL_NECKLACE_OF_SKILLS_4,
                description = destinations({
                    "Fishing Guild",
                    "Mining Guild",
                    "Crafting Guild",
                    "Cooking Guild",
                    "Invention Guild",
                    "Farming Guild",
                    "Runecrafting Guild",
                }),
            },
            ["traveller's necklace"] = {
                item = id.Obj.ENCHANTED_JADE_NECKLACE_NEW,
                description = destinations({
                    "Wizards' Tower",
                    "Outpost",
                    "South of the desert eagle's eyrie",
                }),
            },
        },
    }
end

-- Recognize the item picker, excluding the similar jewellery-replacement dialog.
local function isItemPicker(snapshot)
    return snapshot.prompt ~= nil and snapshot.prompt:lower() == "pick an item"
end

-- Match the six native slots directly against the supported jewellery catalogue.
function PassageOfTheAbyss:Match(snapshot)
    if not isItemPicker(snapshot) or #snapshot.nativeRows ~= slotCount + 1 then
        return nil, "expected Pick an item with six slots and Cancel"
    end

    local group = {
        title = self.definition.title,
        entries = {},
    }

    local rows = {}

    for index, native in ipairs(snapshot.nativeRows) do
        local name     = next(native.labels)
        local itemName = name and name:match("^" .. index .. "%.%s+(.+)$")

        if itemName == nil or native.index ~= index then 
            return nil, "missing item slot " .. index
        end

        itemName = itemName:gsub("%.$", "")

        local normalized = itemName:lower()

        if index == slotCount + 1 then
            if normalized ~= "cancel" then 
                return nil, "expected Cancel after the six slots"
            end
            
            group.entries[name] = { hidden = true }
        elseif normalized == "empty slot" then
            group.entries[name] = { empty = true, hidden = true }
        else
            local item = self.definition.items[normalized]

            if item == nil then
                return nil, "unknown Passage jewellery: " .. itemName 
            end

            group.entries[name] = {
                objectID = item.item,
                nameOverride = itemName,
                description = item.description,
            }
        end

        rows[#rows + 1] = {
            name = name, 
            entryKey = name, 
            row = native.row, 
            click = native.click, 
            native = native,
        }
    end

    return {
        group = group,
        title = group.title,
        rows = rows,
        unusedEntries = 0,
        snapshot = snapshot,
        window = snapshot.window,
        content = snapshot.content,
    }
end

-- Invalidate the selection if the same rows are reused for a different native prompt.
function PassageOfTheAbyss:Matches(snapshot)
    return isItemPicker(snapshot) and SlotMenu.Matches(self, snapshot)
end

-- Empty slots have no destination while filled slots retain native availability checks.
function PassageOfTheAbyss:IsDisabled(row)
    return row.destination.empty == true or SlotMenu.IsDisabled(self, row)
end

-- Hide Pick an item without changing the text used to recognize this interface.
function PassageOfTheAbyss:UpdateTitle()
    local prompt = self.session.title and self.session.title.control
    local text = prompt and prompt.content

    SlotMenu.UpdateTitle(self)

    if prompt ~= nil then
        prompt.content = text
        prompt.alpha = 0
    end
end

-- Create six click-through inventory visuals over the original native input controls.
function PassageOfTheAbyss:BeginVisuals()
    SlotMenu.BeginVisuals(self)

    for index = 1, slotCount do
        local row   = self.session.rows[index]
        local slot  = self:CreateSlot(row, true)
        local layer = slot.layer

        if not row.destination.empty then
            local item = components.ItemSprite(layer, row.destination.objectID)

            slot.item = item
            slot.hotkey = HotkeyBadge.New(self.slotLayer, index)
        end
    end
end

-- Fit a compact row of standard-sized inventory slots without space for the hidden prompt.
function PassageOfTheAbyss:CalculateLayout()
    local showHotkeys = userSettings.Get("showTeleportHotkeys")
    local padding = showHotkeys and 12 or slotPadding
    local spacing = showHotkeys and 12 or slotGap
    local session   = self.session
    local available = math.max(1, session.parent.width - session.left - session.right - 16)
    local scale     = math.min(1, available / (slotSize * slotCount + spacing * (slotCount - 1) + padding * 2))
    local size      = math.max(1, math.floor(slotSize * scale))
    local gap       = math.floor(spacing * scale)
    local inset     = math.floor(padding * scale)
    
    return {
        width = size * slotCount + gap * (slotCount - 1) + inset * 2,
        height = size + inset * 2,
        slotSize = size,
        gap = gap,
        inset = inset,
    }
end

-- Move each filled slot's original click target over its item without changing native actions.
function PassageOfTheAbyss:ApplyLayout(layout)
    self:LayoutWindow(layout.width, layout.height)
    self.slotLayer:SetSize(layout.width, layout.height)

    local origin = self.slotLayer.xyGlobal

    for index, row in ipairs(self.session.rows) do
        local slot = self.slots[index]
        local x    = layout.inset + (index - 1) * (layout.slotSize + layout.gap)
        local size = slot and slot.item and layout.slotSize or 0

        self:HideRowArtwork(row)
        self:LayoutRow(row, origin.x + x, origin.y + layout.inset, size, size)

        if slot ~= nil then
            slot.layer:SetPos(x, layout.inset)
            slot.layer:SetSize(layout.slotSize, layout.slotSize)
            slot.background:SetSize(layout.slotSize, layout.slotSize)

            if slot.item ~= nil then
                local inset = math.floor(layout.slotSize * 2 / slotSize)

                slot.item:SetPos(inset, inset)
                slot.item:SetSize(layout.slotSize - inset * 2, layout.slotSize - inset * 2)
            end
        end
    end
end

-- Determine hover using the original item-slot controls instead of map coordinates.
function PassageOfTheAbyss:GetHovered()
    for _, slot in ipairs(self.slots) do
        local row = slot.row

        if slot.item ~= nil and row.click.visibleGlobal and row.click.isMouseOver then
            return row.name 
        end
    end
end

-- Refresh item icons, hover outlines, slot hotkeys and native-context tooltips.
function PassageOfTheAbyss:UpdateVisuals(layout, hovered)
    for _, slot in ipairs(self.slots) do
        local row = slot.row

        slot.background.alpha = row.disabled and 0.5 or 1

        if slot.item ~= nil then
            local highlighted = row.name == hovered and not row.disabled

            slot.item.outlineWidth = highlighted and 1 or 0
            slot.item.shadowRGBA   = highlighted and 0xFFFFFFCC or 0x00000000
            slot.item.colour        = row.disabled and Vector4.new(0.45, 0.45, 0.45, 1) or Vector4.new(1, 1, 1, 1)

            slot.hotkey:Update(slot.layer, {
                disabled = row.disabled,
                scale = layout.slotSize / slotSize,
            })
        end
    end

    SlotMenu.UpdateVisuals(self, layout, hovered)
end

return PassageOfTheAbyss
