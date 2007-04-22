--[[
	ui.lua
		A UI for Ludwig
--]]

LWUI_SHOWN = 14
LWUI_STEP = LWUI_SHOWN

local L = LUDWIG_LOCALS
local DEFAULT_FILTER = 'any'
local ITEM_SIZE = 24
local displayList, displayChanged --all things to display on the list
local filter = {}


--[[
	OnX Functions
--]]

function LudwigUI_OnLoad()
	local frameName = this:GetName()

	local offset = -6
	local item = CreateFrame("Button", frameName .. "Item1", this, "LudwigItem")
	item:SetPoint("TOPLEFT", frameName .. "Search", "BOTTOMLEFT", 2, offset)
	item:SetPoint("BOTTOMRIGHT", frameName .. "ScrollFrame", "TOPLEFT", -2, offset - ITEM_SIZE)
	item:SetID(1)

	offset = -2
	for i = 2, LWUI_SHOWN do
		item = CreateFrame("Button", frameName .. "Item" .. i, this, "LudwigItem")
		item:SetPoint("TOPLEFT", frameName .. "Item" .. i-1, "BOTTOMLEFT", 0, offset)
		item:SetPoint("BOTTOMRIGHT", frameName .. "Item" .. i-1, "BOTTOMRIGHT", 0, offset - ITEM_SIZE)
		item:SetID(2)
	end
	this:SetHeight(72 + ((-offset) + ITEM_SIZE)*LWUI_SHOWN)
	this:GetParent():SetHeight(72 + ((-offset) + ITEM_SIZE)*LWUI_SHOWN)
end

function LudwigUI_OnShow()
	displayChanged = true
	Ludwig:ReloadDB()
end

function LudwigUI_OnHide()
	for i in pairs(displayList) do
		displayList[i] = nil
	end
	displayChanged = true
end

function LudwigUIFilter_OnShow()
	this:GetParent():SetWidth(this:GetParent():GetWidth() + this:GetWidth())
	LudwigUIFilterToggle:LockHighlight()
end

function LudwigUIFilter_OnHide()
	this:GetParent():SetWidth(this:GetParent():GetWidth() - this:GetWidth())
	LudwigUIFilterToggle:UnlockHighlight()
end

function LudwigUIText_OnTextChanged()
	filter.name = this:GetText()
	displayChanged = true
	LudwigUIScrollBar_Update()
end

function LudwigUI_SetMinLevel(level)
	filter.minLevel = level
	displayChanged = true
	LudwigUIScrollBar_Update()
end

function LudwigUI_SetMaxLevel(level)
	filter.maxLevel = level
	displayChanged = true
	LudwigUIScrollBar_Update()
end

function LudwigUI_OnMousewheel(scrollframe, direction)
	local scrollbar = getglobal(scrollframe:GetName() .. "ScrollBar")
	scrollbar:SetValue(scrollbar:GetValue() - direction * (scrollbar:GetHeight() / 2))
	LudwigUIScrollBar_Update()
end

function LudwigUIItem_OnEnter()
	GameTooltip:SetOwner(this)
	GameTooltip:SetHyperlink(Ludwig:GetItemLink(this:GetID()))
	GameTooltip:ClearAllPoints()

	if this:GetLeft() < (UIParent:GetRight() / 2) then
		if this:GetTop() < (UIParent:GetTop() / 3) then
			GameTooltip:SetPoint("BOTTOMLEFT", this, "BOTTOMRIGHT", -4, -3)
		else
			GameTooltip:SetPoint("TOPLEFT", this, "TOPRIGHT", -4, 3)
		end
	else
		if this:GetTop() < (UIParent:GetTop() / 3) then
			GameTooltip:SetPoint("BOTTOMRIGHT", this, "BOTTOMLEFT", -4, -3)
		else
			GameTooltip:SetPoint("TOPRIGHT", this, "TOPLEFT", -4, 3)
		end
	end
	GameTooltip:Show()
end

function LudwigUI_Load()
	UIDropDownMenu_Initialize(LudwigUIFilterQuality, LudwigUI_Quality_Initialize)
	UIDropDownMenu_Initialize(LudwigUIFilterType, LudwigUI_Type_Initialize)
	UIDropDownMenu_Initialize(LudwigUIFilterSubType, LudwigUI_SubType_Initialize)
	UIDropDownMenu_Initialize(LudwigUIFilterEquipSlot, LudwigUI_EquipSlot_Initialize)
end


--[[
	Scrollbar Functions
--]]

function LudwigUIScrollBar_Update()
	--update list only if there are changes
	if not displayList or displayChanged then
		displayChanged = nil
		displayList = Ludwig:GetItems(filter.name, filter.quality, filter.type, filter.subType, filter.loc, filter.minLevel, filter.maxLevel, filter.player)
	end

	local size = #displayList
	LudwigUITitle:SetText(format(L['Ludwig: Displaying %d Items'], size))
	FauxScrollFrame_Update(LudwigUIScrollFrame, size, LWUI_SHOWN, LWUI_STEP)

	local offset = LudwigUIScrollFrame.offset
	for index = 1, LWUI_SHOWN, 1 do
		local rIndex = index + offset
		local lwb = getglobal("LudwigUIItem".. index)

		if rIndex < size + 1 then
			local id = displayList[rIndex]
			lwb:SetText(Ludwig:GetItemName(id, true))
			lwb:SetID(id)
			getglobal(lwb:GetName() ..  "Texture"):SetTexture(Ludwig:GetItemTexture(id))
			lwb:Show()
		else
			lwb:Hide()
		end
	end
end


--[[
	Dropdown Menus
--]]

function LudwigUI_Refresh()
	Ludwig:ReloadDB()
	displayChanged = 1
	LudwigUIScrollBar_Update()
end

--Filter reset
function LudwigUI_ResetFilters()
	for i in pairs(filter) do
		filter[i] = nil
	end

	UIDropDownMenu_SetSelectedValue(LudwigUIFilterQuality, DEFAULT_FILTER)
	UIDropDownMenu_SetSelectedValue(LudwigUIFilterType, DEFAULT_FILTER)
	UIDropDownMenu_SetSelectedValue(LudwigUIFilterSubType, DEFAULT_FILTER)
	UIDropDownMenu_SetSelectedValue(LudwigUIFilterEquipSlot, DEFAULT_FILTER)

	UIDropDownMenu_Initialize(LudwigUIFilterQuality, LudwigUI_Quality_Initialize)
	UIDropDownMenu_Initialize(LudwigUIFilterType, LudwigUI_Type_Initialize)
	UIDropDownMenu_Initialize(LudwigUIFilterSubType, LudwigUI_SubType_Initialize)
	UIDropDownMenu_Initialize(LudwigUIFilterEquipSlot, LudwigUI_EquipSlot_Initialize)

	displayChanged = true
	LudwigUIScrollBar_Update()
end

local info = {}
local function AddItem(text, action, value, selectedValue)
	info.text = text
	info.func = action
	info.value = value
	info.checked = value == selectedValue
	UIDropDownMenu_AddButton(info)
end

local function AddDropDownButtons(selectedValue, action, ...)
	for i = 1, select('#', ...) do
		AddItem(select(i, ...), action, i, selectedValue)
	end
end


--[[ Quality ]]--

function LudwigUI_Quality_OnShow()
	UIDropDownMenu_Initialize(this, LudwigUI_Quality_Initialize)
	UIDropDownMenu_SetWidth(88, this)
end

function LudwigUI_Quality_OnClick()
	UIDropDownMenu_SetSelectedValue(LudwigUIFilterQuality, this.value)

	if this.value == DEFAULT_FILTER then
		filter.quality = nil
	else
		filter.quality = this.value
	end

	displayChanged = 1
	LudwigUIScrollBar_Update()
end

--add all buttons to the dropdown menu
function LudwigUI_Quality_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(LudwigUIFilterQuality) or DEFAULT_FILTER

	AddItem(L['Any'], LudwigUI_Quality_OnClick, DEFAULT_FILTER, selectedValue)
	for i = 6, 0, -1 do
		local hex = select(4, GetItemQualityColor(i))
		AddItem(hex .. getglobal("ITEM_QUALITY" .. i .. "_DESC") .. "|r", LudwigUI_Quality_OnClick, i, selectedValue)
	end

	UIDropDownMenu_SetSelectedValue(LudwigUIFilterQuality, selectedValue)
end


--[[ Type ]]--

function LudwigUI_Type_OnShow()
	UIDropDownMenu_Initialize(this, LudwigUI_Type_Initialize)
	UIDropDownMenu_SetWidth(128, this)
end

function LudwigUI_Type_OnClick()
	UIDropDownMenu_SetSelectedValue(LudwigUIFilterType, this.value)

	--category change, so reset subtype
	filter.subType = nil
	if this.value == DEFAULT_FILTER then
		filter.type = nil
	else
		filter.type = LudwigUI_GetType(this.value)
	end

	if not filter.subType then
		UIDropDownMenu_SetSelectedValue(LudwigUIFilterSubType, DEFAULT_FILTER)
		UIDropDownMenu_Initialize(LudwigUIFilterSubType, LudwigUI_SubType_Initialize)
	end
	if not filter.type then
		UIDropDownMenu_SetSelectedValue(LudwigUIFilterEquipSlot, DEFAULT_FILTER)
		UIDropDownMenu_Initialize(LudwigUIFilterEquipSlot, LudwigUI_EquipSlot_Initialize)
	end
	displayChanged = true

	LudwigUIScrollBar_Update()
end

function LudwigUI_Type_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(LudwigUIFilterType) or DEFAULT_FILTER

	AddItem(L['Any'], LudwigUI_Type_OnClick, DEFAULT_FILTER, selectedValue)
	AddDropDownButtons(selectedValue, LudwigUI_Type_OnClick, GetAuctionItemClasses())

	local nextI = select('#', GetAuctionItemClasses()) + 1
	AddItem(L['Quest'], LudwigUI_Type_OnClick, nextI, selectedValue)
	AddItem(L['Key'], LudwigUI_Type_OnClick, nextI + 1, selectedValue)


	UIDropDownMenu_SetSelectedValue(LudwigUIFilterType, selectedValue)
end


--[[ Subtype ]]--

function LudwigUI_SubType_OnShow()
	UIDropDownMenu_Initialize(this, LudwigUI_SubType_Initialize)
	UIDropDownMenu_SetWidth(128, this)
end

function LudwigUI_SubType_OnClick()
	UIDropDownMenu_SetSelectedValue(LudwigUIFilterSubType, this.value)

	filter.loc = nil
	if this.value == DEFAULT_FILTER then
		filter.subType = nil
	else
		filter.subType = LudwigUI_GetSubType(this.value)
	end
	if not filter.loc then
		UIDropDownMenu_SetSelectedValue(LudwigUIFilterEquipSlot, DEFAULT_FILTER)
		UIDropDownMenu_Initialize(LudwigUIFilterEquipSlot, LudwigUI_EquipSlot_Initialize)
	end

	displayChanged = true
	LudwigUIScrollBar_Update()
end

function LudwigUI_SubType_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(LudwigUIFilterSubType) or DEFAULT_FILTER

	AddItem(L['Any'], LudwigUI_SubType_OnClick, DEFAULT_FILTER, selectedValue)

	local type = UIDropDownMenu_GetSelectedValue(LudwigUIFilterType)
	if tonumber(type) then
		AddDropDownButtons(selectedValue, LudwigUI_SubType_OnClick, GetAuctionItemSubClasses(type))
		if type == 5 then
			local nextI = select('#', GetAuctionItemSubClasses(type)) + 1
			AddItem(L['Devices'], LudwigUI_SubType_OnClick, nextI, selectedValue)
			AddItem(L['Explosives'], LudwigUI_SubType_OnClick, nextI + 1, selectedValue)
			AddItem(L['Gems'], LudwigUI_SubType_OnClick, nextI + 2, selectedValue)
			AddItem(L['Parts'], LudwigUI_SubType_OnClick, nextI + 3, selectedValue)
		elseif type == 10 then
			local nextI = select('#', GetAuctionItemSubClasses(type)) + 1
			AddItem(L['Junk'], LudwigUI_SubType_OnClick, nextI, selectedValue)
		end

		UIDropDownMenu_SetSelectedValue(LudwigUIFilterSubType, selectedValue)
	else
		UIDropDownMenu_SetSelectedValue(LudwigUIFilterSubType, DEFAULT_FILTER)
	end
end


--[[ Equip Slot ]]--

function LudwigUI_EquipSlot_OnShow()
	UIDropDownMenu_Initialize(this, LudwigUI_EquipSlot_Initialize)
	UIDropDownMenu_SetWidth(128, this)
end

function LudwigUI_EquipSlot_OnClick()
	UIDropDownMenu_SetSelectedValue(LudwigUIFilterEquipSlot, this.value)

	if this.value == DEFAULT_FILTER then
		filter.loc = nil
	else
		filter.loc = LudwigUI_GetEquipSlot(this.value)
	end

	displayChanged = true
	LudwigUIScrollBar_Update()
end

local function AddEqupSlotButtons(selectedValue, action, ...)
	for i = 1, select('#', ...) do
		AddItem(getglobal(select(i, ...)), action, i, selectedValue)
	end
end

function LudwigUI_EquipSlot_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(LudwigUIFilterEquipSlot) or DEFAULT_FILTER

	AddItem(L['Any'], LudwigUI_EquipSlot_OnClick, DEFAULT_FILTER, selectedValue)

	local type = UIDropDownMenu_GetSelectedValue(LudwigUIFilterType)
	local subType = tonumber(UIDropDownMenu_GetSelectedValue(LudwigUIFilterSubType))

	if type and subType then
		AddEqupSlotButtons(selectedValue, LudwigUI_EquipSlot_OnClick, GetAuctionInvTypes(type, subType))
		UIDropDownMenu_SetSelectedValue(LudwigUIFilterEquipSlot, selectedValue)
	else
		UIDropDownMenu_SetSelectedValue(LudwigUIFilterEquipSlot, DEFAULT_FILTER)
	end
end


--[[ Utility Functions ]]--

function LudwigUI_GetType(index)
	local maxI = select('#', GetAuctionItemClasses())
	if index == maxI + 1 then
		return L['Quest']
	elseif index == maxI + 2 then
		return L['Key']
	end
	return select(index, GetAuctionItemClasses())
end

function LudwigUI_GetSubType(index)
	local type = tonumber(UIDropDownMenu_GetSelectedValue(LudwigUIFilterType))
	if type then
		if type == 5 then
			local nextI = select('#', GetAuctionItemSubClasses(type)) + 1
			if index == nextI then
				return L['Devices']
			elseif index == nextI + 1 then
				return L['Explosives']
			elseif index == nextI + 2 then
				return L['Gems']
			elseif index == nextI + 2 then
				return L['Parts']
			end
		elseif type == 10 then
			local nextI = select('#', GetAuctionItemSubClasses(type)) + 1
			if index == nextI then
				return L['Junk']
			end
		end
		return select(index, GetAuctionItemSubClasses(type))
	end
end

function LudwigUI_GetEquipSlot(index)
	local type = tonumber(UIDropDownMenu_GetSelectedValue(LudwigUIFilterType))
	local subType = tonumber(UIDropDownMenu_GetSelectedValue(LudwigUIFilterSubType))

	if type and subType then
		return select(index, GetAuctionInvTypes(type, subType))
	end
end