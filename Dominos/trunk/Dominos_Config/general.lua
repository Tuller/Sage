﻿--[[
	general.lua
		The general panel of the Dominos options menu
--]]

local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
local Dominos = Dominos
local Options = Dominos.Options

--[[ Buttons ]]--

--toggle config mode
local lock = Options:NewButton('Config Mode', 136, 22)
lock.UpdateText = function(self) self:SetText(Dominos:Locked() and L.EnterConfigMode or L.ExitConfigMode) end
lock:SetScript('OnShow', lock.UpdateText)
lock:SetScript('OnClick', function(self) Dominos:ToggleLockedFrames() self:UpdateText() end)
lock:SetPoint('TOPLEFT', 12, -72)

--toggle keybinding mode
local bind = Options:NewButton(L.EnterBindingMode, 136, 22)
bind:SetScript('OnClick', function(self) LibStub('LibKeyBound-1.0'):Activate() HideUIPanel(InterfaceOptionsFrame) end)
bind:SetPoint('LEFT', lock, 'RIGHT', 4, 0)


--[[ Check Buttons ]]--

--local action bar button positions
--[[
local lockButtons = Options:NewCheckButton(L.LockActionButtons)
lockButtons:SetScript('OnShow', function(self)
	self:SetChecked(GetCVarBool('lockActionBars'))
end)
lockButtons:SetScript('OnClick', function(self)
	local value = self:GetChecked() and '1' or '0'
	SetCVar('lockActionBars', value)
	setglobal('LOCK_ACTIONBAR', value)
end)
lockButtons:SetPoint('TOPLEFT', lock, 'BOTTOMLEFT', 0, -24)
--]]

--show empty buttons
local showEmpty = Options:NewCheckButton(L.ShowEmptyButtons)
showEmpty:SetScript('OnShow', function(self)
	self:SetChecked(Dominos:ShowGrid())
end)
showEmpty:SetScript('OnClick', function(self)
	Dominos:SetShowGrid(self:GetChecked())
end)
showEmpty:SetPoint('TOPLEFT', lock, 'BOTTOMLEFT', 0, -24)
--showEmpty:SetPoint('TOP', lockButtons, 'BOTTOM', 0, -10)

--show keybinding text
local showBindings = Options:NewCheckButton(L.ShowBindingText)
showBindings:SetScript('OnShow', function(self)
	self:SetChecked(Dominos:ShowBindingText())
end)
showBindings:SetScript('OnClick', function(self)
	Dominos:SetShowBindingText(self:GetChecked())
end)
showBindings:SetPoint('TOP', showEmpty, 'BOTTOM', 0, -10)

--show macro text
local showMacros = Options:NewCheckButton(L.ShowMacroText)
showMacros:SetScript('OnShow', function(self)
	self:SetChecked(Dominos:ShowMacroText())
end)
showMacros:SetScript('OnClick', function(self)
	Dominos:SetShowMacroText(self:GetChecked())
end)
showMacros:SetPoint('TOP', showBindings, 'BOTTOM', 0, -10)

--show tooltips
local showTooltips = Options:NewCheckButton(L.ShowTooltips)
showTooltips:SetScript('OnShow', function(self)
	self:SetChecked(Dominos:ShowTooltips())
end)
showTooltips:SetScript('OnClick', function(self)
	Dominos:SetShowTooltips(self:GetChecked())
end)
showTooltips:SetPoint('TOP', showMacros, 'BOTTOM', 0, -10)


--[[ Dropdowns ]]--

do
	local info = {}
	local function AddItem(text, value, func, checked, arg1)
		info.text = text
		info.func = func
		info.value = value
		info.checked = checked
		info.arg1 = arg1
		UIDropDownMenu_AddButton(info)
	end

	local function AddClickActionSelector(self, name, action)
		local dd = self:NewDropdown(name)

		dd:SetScript('OnShow', function(self)
			UIDropDownMenu_SetWidth(self, 110)
			UIDropDownMenu_Initialize(self, self.Initialize)
			UIDropDownMenu_SetSelectedValue(self, GetModifiedClick(action) or 'NONE')
		end)

		local function Item_OnClick(self)
			SetModifiedClick(action, self.value)
			UIDropDownMenu_SetSelectedValue(dd, self.value)
			SaveBindings(GetCurrentBindingSet())
		end

		function dd:Initialize()
			local selected = GetModifiedClick(action) or 'NONE'

			AddItem(ALT_KEY, 'ALT', Item_OnClick, 'ALT' == selected)
			AddItem(CTRL_KEY, 'CTRL', Item_OnClick, 'CTRL' == selected)
			AddItem(SHIFT_KEY, 'SHIFT', Item_OnClick, 'SHIFT' == selected)
			AddItem(NONE_KEY, 'NONE', Item_OnClick, 'NONE' == selected)
		end
		return dd
	end

	local function AddRightClickTargetSelector(self)
		local dd = self:NewDropdown(L.RightClickUnit)

		dd:SetScript('OnShow', function(self)
			UIDropDownMenu_SetWidth(self, 110)
			UIDropDownMenu_Initialize(self, self.Initialize)
			UIDropDownMenu_SetSelectedValue(self, Dominos:GetRightClickUnit() or 'NONE')
		end)

		local function Item_OnClick(self)
			Dominos:SetRightClickUnit(self.value ~= 'NONE' and self.value or nil)
			UIDropDownMenu_SetSelectedValue(dd, self.value)
		end

		function dd:Initialize()
			local selected = Dominos:GetRightClickUnit()  or 'NONE'

			AddItem(L.RCUPlayer, 'player', Item_OnClick, 'player' == selected)
			AddItem(L.RCUFocus, 'focus', Item_OnClick, 'focus' == selected)
			AddItem(L.RCUToT, 'targettarget', Item_OnClick, 'targettarget' == selected)
			AddItem(NONE_KEY, 'NONE', Item_OnClick, 'NONE' == selected)
		end
		return dd
	end

	local function AddPossessBarSelector(self)
		local dd = self:NewDropdown(L.PossessBar)

		dd:SetScript('OnShow', function(self)
			UIDropDownMenu_SetWidth(self, 110)
			UIDropDownMenu_Initialize(self, self.Initialize)
			UIDropDownMenu_SetSelectedValue(self, Dominos:GetPossessBar().id)
		end)

		local function Item_OnClick(self)
			Dominos:SetPossessBar(self.value)
			UIDropDownMenu_SetSelectedValue(dd, self.value)
		end

		function dd:Initialize()
			local selected = Dominos:GetPossessBar().id

			for i = 1, Dominos:NumBars() do
				AddItem('Action Bar ' .. i, i, Item_OnClick, i == selected)
			end
			AddItem('Pet Bar', 'pet', Item_OnClick, 'pet' == selected)
		end
		return dd
	end

	local quickMove = AddClickActionSelector(Options, L.QuickMoveKey, 'PICKUPACTION')
	quickMove:SetPoint('TOPRIGHT', -10, -120)

	local rightClickUnit = AddRightClickTargetSelector(Options)
	rightClickUnit:SetPoint('TOP', quickMove, 'BOTTOM', 0, -16)

	local possess = AddPossessBarSelector(Options)
	possess:SetPoint('TOP', rightClickUnit, 'BOTTOM', 0, -16)
end
