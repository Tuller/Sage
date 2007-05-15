--[[
	BongosActionButton
		A Bongos ActionButton
--]]

BongosActionButton = CreateFrame("CheckButton")
local Button_MT = {__index = BongosActionButton}

local BUTTON_NAME = "BongosActionButton%d"
local SIZE = 36
local MAX_BUTTONS = 120 --the current maximum amount of action buttons

local buttons = {}
local maxStance = 7
local maxPage = 5


--[[ constructorish ]]--

local function OnUpdate(self, elapsed) self:OnUpdate(elapsed) end
local function PostClick(self) self:PostClick() end
local function OnDragStart(self) self:OnDragStart() end
local function OnReceiveDrag(self) self:OnReceiveDrag() end
local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end
-- local function OnShow(self) self:Update(true) end
local function OnAttributeChanged(self, var, val) 
	if(var == "state-parent" and self:GetParent() and self:GetParent():IsVisible()) then
		self:Update(true)
	end
end

--Create an Action Button with the given ID and parent
function BongosActionButton:Create(id)
	local button = CreateFrame("CheckButton", format(BUTTON_NAME, id), nil, "SecureActionButtonTemplate, ActionButtonTemplate")
	setmetatable(button, Button_MT)
	
	button:SetScript("OnUpdate", OnUpdate)
	button:SetScript("PostClick", PostClick)
	button:SetScript("OnDragStart", OnDragStart)
	button:SetScript("OnReceiveDrag", OnReceiveDrag)
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)
	button:SetScript("OnShow", OnShow)
	button:SetScript("OnAttributeChanged", OnAttributeChanged)
	
	button:SetAttribute("type", "action")
	button:SetAttribute("checkselfcast", true)
	button:SetAttribute("useparent-unit", true)
	button:SetAttribute("useparent-statebutton", true)
	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp")

	button:SetAttribute("action", id)
	if(id <= 12) then
		local class = select(2, UnitClass("player"))
		if(class == "ROGUE") then
			button:SetAttribute("*action-s1", id + 72)
		elseif(class == "DRUID") then
			button:SetAttribute("*action-s1", id + 96)
			button:SetAttribute("*action-s3", id + 72)
			button:SetAttribute("*action-s4", id + 84)
			button:SetAttribute("*action-help", id + 12)
		elseif(class == "WARRIOR") then
			button:SetAttribute("*action-s1", id + 96)
			button:SetAttribute("*action-s2", id + 72)
			button:SetAttribute("*action-s3", id + 84)
		end
		
		for i = 1, 5 do
			button:SetAttribute(format("*action-p%d", i), id + (i*12))
		end
	end

	button:Style()
	button:Hide()
	
	buttons[id] = button
	return button
end


--[[ attach and remove ]]--

function BongosActionButton:Set(id, parent)
	local button = buttons[id] or self:Create(id)
	parent:Attach(button)
	parent:SetAttribute("addchild", button)

	return button
end

function BongosActionButton:Release()
	self:SetParent(nil)
	self:ClearAllPoints()
	self:Hide()
end

--adjust the looks of the button, currently uses a zoomed layout
function BongosActionButton:Style()
	local name = self:GetName()
	getglobal(name .. "Icon"):SetTexCoord(0.06, 0.94, 0.06, 0.94)
	getglobal(name .. "Border"):SetVertexColor(0, 1, 0, 0.6)
	getglobal(name .. "NormalTexture"):SetVertexColor(1, 1, 1, 0.5)
end

function BongosActionButton:Get(id)
	return buttons[id]
end


--[[ OnX Functions ]]--

function BongosActionButton:OnUpdate(elapsed)
	local name = self:GetName()
	if not getglobal(name .. "Icon"):IsShown() then return end

	--update flashing
	if self.flashing == 1 then
		self.flashtime = self.flashtime - elapsed
		if self.flashtime <= 0 then
			local overtime = -self.flashtime
			if overtime >= ATTACK_BUTTON_FLASH_TIME then
				overtime = 0
			end
			self.flashtime = ATTACK_BUTTON_FLASH_TIME - overtime

			local flashTexture = getglobal(name .. "Flash")
			if flashTexture:IsShown() then
				flashTexture:Hide()
			else
				flashTexture:Show()
			end
		end
	end

	-- Handle range indicator
	if self.rangeTimer then
		if self.rangeTimer < 0 then
			local pagedID = self:GetPagedID()
			local hotkey = getglobal(name .. "HotKey")

			if IsActionInRange(pagedID) == 0 then
				hotkey:SetVertexColor(1, 0.1, 0.1)

				if BongosActionMain:RangeColoring() and IsUsableAction(pagedID) then
					local r,g,b = BongosActionMain:GetRangeColor()
					getglobal(name .. "Icon"):SetVertexColor(r,g,b)
				end
			else
				hotkey:SetVertexColor(0.6, 0.6, 0.6)

				if IsUsableAction(pagedID) then
					getglobal(name .. "Icon"):SetVertexColor(1, 1, 1)
				end
			end
			self.rangeTimer = TOOLTIP_UPDATE_TIME
		else
			self.rangeTimer = self.rangeTimer - elapsed
		end
	end

	-- Tooltip stuff, probably for the cooldown timer
	if self.nextTooltipUpdate then
		self.nextTooltipUpdate = self.nextTooltipUpdate - elapsed
		if self.nextTooltipUpdate <= 0 then
			if GameTooltip:IsOwned(self) then
				self:UpdateTooltip(self)
			else
				self.nextTooltipUpdate = nil
			end
		end
	end
end

function BongosActionButton:PostClick()
	self:UpdateState()
end

function BongosActionButton:OnDragStart()
	if not(BongosActionMain:ButtonsLocked()) or BongosActionBar.showEmpty or BongosActionMain:IsQuickMoveKeyDown() then
		PickupAction(self:GetPagedID())
		self:UpdateState()
	end
end

function BongosActionButton:OnReceiveDrag()
	PlaceAction(self:GetPagedID())
	self:UpdateState()
end

function BongosActionButton:OnEnter()
	self:UpdateTooltip()
	KeyBound:Set(self)
end

function BongosActionButton:OnLeave()
	self.nextTooltipUpdate = nil
	GameTooltip:Hide()
end


--[[ Update Code ]]--

--Updates the icon, count, cooldown, usability color, if the button is flashing, if the button is equipped,  and macro text.
function BongosActionButton:Update(force)
	if not self:GetParent() then return end

	local name = self:GetName()
	local action = self:GetPagedID(force)
	local icon = getglobal(name .. "Icon")
	local cooldown = getglobal(name .. "Cooldown")
	local texture = GetActionTexture(action)

	if texture then
		icon:SetTexture(texture)
		icon:Show()
		self.rangeTimer = -1
	
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	else
		icon:Hide()
		self.rangeTimer = nil
		cooldown:Hide()
		
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot")
		getglobal(name .. "HotKey"):SetVertexColor(0.6, 0.6, 0.6)
	end

	if HasAction(action) then
		self:UpdateState()
		self:UpdateUsable()
		self:UpdateCooldown()
		self:UpdateFlash()
	else
		cooldown:Hide()
	end
	self:UpdateCount()

	-- Add a green border if button is an equipped item
	local border = getglobal(name .. "Border")
	if IsEquippedAction(action) then
		border:SetVertexColor(0, 1, 0, 0.6)
		border:Show()
	else
		border:Hide()
	end

	if GameTooltip:IsOwned(self) then
		self:UpdateTooltip()
	else
		self.nextTooltipUpdate = nil
	end

	-- Update Macro Text
	getglobal(name .. "Name"):SetText(GetActionText(action))
end

--Update the cooldown timer
function BongosActionButton:UpdateCooldown()
	local start, duration, enable = GetActionCooldown(self:GetPagedID())
	CooldownFrame_SetTimer(getglobal(self:GetName().."Cooldown"), start, duration, enable)
end

--Update item count
function BongosActionButton:UpdateCount()
	local text = getglobal(self:GetName() .. "Count")
	local action = self:GetPagedID()

	if IsConsumableAction(action) then
		text:SetText(GetActionCount(action))
	else
		text:SetText("")
	end
end

--Update if a button is checked or not
function BongosActionButton:UpdateState()
	local action = self:GetPagedID()
	self:SetChecked(IsCurrentAction(action) or IsAutoRepeatAction(action))
end

--colors the action button if out of mana, out of range, etc
function BongosActionButton:UpdateUsable()
	local action = self:GetPagedID()
	local icon = getglobal(self:GetName() .. "Icon")

	local isUsable, notEnoughMana = IsUsableAction(action)
	if isUsable then
		if BongosActionMain:RangeColoring() and IsActionInRange(action) == 0 then
			local r,g,b = BongosActionMain:GetRangeColor()
			icon:SetVertexColor(r,g,b)
		else
			icon:SetVertexColor(1, 1, 1)
		end
	elseif notEnoughMana then
		--Make the icon blue if out of mana
		icon:SetVertexColor(0.5, 0.5, 1)
	else
		--Skill unusable
		icon:SetVertexColor(0.3, 0.3, 0.3)
	end
end

function BongosActionButton:UpdateFlash()
	local action = self:GetPagedID()
	if (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) then
		self:StartFlash()
	else
		self:StopFlash()
	end
end

function BongosActionButton:StartFlash()
	self.flashing = 1
	self.flashtime = 0
	self:UpdateState()
end

function BongosActionButton:StopFlash()
	self.flashing = 0
	getglobal(self:GetName() .. "Flash"):Hide()
	
	self:UpdateState()
end

function BongosActionButton:UpdateSlot()
	local changed = self:UpdateVisibility(self:ShowingEmpty())
	if changed then
		SecureStateHeader_Refresh(self:GetParent())
	else
		self:Update()
	end
end

function BongosActionButton:UpdateTooltip()
	if BongosActionMain:ShowingTooltips() then
		if GetCVar("UberTooltips") == "1" then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end

		local action = self:GetPagedID()
		if GameTooltip:SetAction(action) then
			self.nextTooltipUpdate = TOOLTIP_UPDATE_TIME
		else
			self.nextTooltipUpdate = nil
		end
	end
end

--show if showing empty buttons, or if the slot has an action, hide otherwise
function BongosActionButton:UpdateVisibility(showEmpty)
	showEmpty = showEmpty or self:ShowingEmpty()

	local newstates
	local normAction = self:GetAttribute("action")
	if showEmpty or HasAction(normAction) then
		newstates = 0
	end
	
	for i = 1, 7 do
		if showEmpty or HasAction(self:GetAttribute("action-s" .. i) or normAction) then
			newstates = (newstates and newstates .. "," .. i) or i
		end
	end
	
	for i = 1, 5 do
		if showEmpty or HasAction(self:GetAttribute("action-p" .. i) or normAction) then
			newstates = (newstates and newstates .. "," .. i+7) or i+7
		end
	end

	if showEmpty or HasAction(self:GetAttribute("action-help") or normAction) then
		newstates = (newstates and newstates .. "," .. 13) or 13
	end
	
	newstates = newstates or "!*"
	if(self.id == 1) then Bongos:Print(newstates) end
	
	local oldstates = self:GetAttribute("showstates")
	if not oldstates or oldstates ~= newstates then
		self:SetAttribute("showstates", newstates)
		return true
	end
end


--[[ Hotkey Functions ]]--

function BongosActionButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. "HotKey"):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. "HotKey"):Hide()
	end
end

function BongosActionButton:UpdateHotkey()
	getglobal(self:GetName() .. "HotKey"):SetText(self:GetHotkey() or '')
end

function BongosActionButton:GetHotkey()
	local key = GetBindingKey(format("CLICK %s:LeftButton", self:GetName()))
	if key then
		return KeyBound:ToShortKey(key)
	end
end


--[[ Macro Functions ]]--

function BongosActionButton:ShowMacro(show)
	if show then
		getglobal(self:GetName() .. "Name"):Show()
	else
		getglobal(self:GetName() .. "Name"):Hide()
	end
end


--[[ Utility Functions ]]--

function BongosActionButton:GetPagedID(update)
	if not self.id or update then
		if self:GetParent() then
			self.id = SecureButton_GetModifiedAttribute(self, "action", SecureStateChild_GetEffectiveButton(self)) or 1
		else
			self.id = 1
		end
	end
	return self.id
end

function BongosActionButton:ForAll(method, ...)
	for _, button in pairs(buttons) do
		local action = button[method]
		if action then
			action(button, ...)
		end
	end
end

function BongosActionButton:ForAllShown(method, ...)
	for _, button in pairs(buttons) do
		if button:IsShown() then
			local action = button[method]
			if action then
				action(button, ...)
			end
		end
	end
end

--does the action to every single button matching the given id
function BongosActionButton:ForID(id, method, ...)
	for _,button in pairs(buttons) do
		if button:GetPagedID() == id then
			local action = button[method]
			if action then
				action(button, ...)
			end
		end
	end
end

--does the action to every single button being shown with an action
function BongosActionButton:ForAllWithAction(action, ...)
	for _,button in pairs(buttons) do
		if button:GetParent() and button:IsShown() and HasAction(button:GetPagedID()) then
			local action = button[method]
			if action then
				action(button, ...)
			end
		end
	end
end


--[[ Access ]]--

function BongosActionButton:ShowingEmpty()
	return BongosActionBar.showEmpty or BongosActionMain:ShowingEmptyButtons()
end

function BongosActionButton:Get(id)
	return buttons[id]
end