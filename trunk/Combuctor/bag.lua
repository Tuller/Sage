--[[
	CombuctorBag
		A bag button object
--]]

CombuctorBag = CombuctorUtil:CreateWidgetClass('Button')

local SIZE = 30
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)
local unused = {}
local id = 1

function CombuctorBag:Create()
	local bag = self:New(CreateFrame('Button', format('CombuctorBag%d', id)))
	local name = bag:GetName()
	bag:SetWidth(SIZE); bag:SetHeight(SIZE)

	local icon = bag:CreateTexture(name .. 'IconTexture', 'BORDER')
	icon:SetAllPoints(bag)

	local count = bag:CreateFontString(name .. 'Count', 'OVERLAY')
	count:SetFontObject('NumberFontNormalSmall')
	count:SetJustifyH('RIGHT')
	count:SetPoint('BOTTOMRIGHT', -2, 2)

	local normalTexture = bag:CreateTexture(name .. 'NormalTexture')
	normalTexture:SetTexture('Interface/Buttons/UI-Quickslot2')
	normalTexture:SetWidth(NORMAL_TEXTURE_SIZE)
	normalTexture:SetHeight(NORMAL_TEXTURE_SIZE)
	normalTexture:SetPoint('CENTER', 0, -1)
	bag:SetNormalTexture(normalTexture)

	local pushedTexture = bag:CreateTexture()
	pushedTexture:SetTexture('Interface/Buttons/UI-Quickslot-Depress')
	pushedTexture:SetAllPoints(bag)
	bag:SetPushedTexture(pushedTexture)

	local highlightTexture = bag:CreateTexture()
	highlightTexture:SetTexture('Interface/Buttons/ButtonHilight-Square')
	highlightTexture:SetAllPoints(bag)
	bag:SetHighlightTexture(highlightTexture)

	bag:RegisterForClicks('anyUp')
	bag:RegisterForDrag('LeftButton')

	bag:SetScript('OnShow', self.OnShow)
	bag:SetScript('OnEnter', self.OnEnter)
	bag:SetScript('OnLeave', self.OnLeave)
	bag:SetScript('OnClick', self.OnClick)
	bag:SetScript('OnDragStart', self.OnDrag)
	bag:SetScript('OnReceiveDrag', self.OnClick)

	id = id + 1
	return bag
end

function CombuctorBag:Get()
	local f = next(unused)
	if f then
		unused[f] = nil
		return f
	end
	return self:Create()
end

function CombuctorBag:Set(parent, id)
	self:SetID(id)
	self:SetParent(parent)

	if id == BACKPACK_CONTAINER or id == BANK_CONTAINER then
		SetItemButtonTexture(self, 'Interface/Buttons/Button-Backpack-Up')
	end
	self:Update()
end

function CombuctorBag:Release()
	unused[self] = true

	self.cached = nil
	self.hasItem = nil
	self:SetParent(nil)
	self:Hide()
	getglobal(self:GetName() .. 'Count'):Hide()
end


--[[ Update ]]--

function CombuctorBag:Update()
	self:UpdateTexture()
	self:UpdateLock()

	--update tooltip
	if GameTooltip:IsOwned(self) then
		self:OnEnter()
		self:UpdateCursor()
	end

	-- Update repair all button status
	if MerchantRepairAllIcon then
		local repairAllCost, canRepair = GetRepairAllCost()
		if canRepair then
			SetDesaturation(MerchantRepairAllIcon, nil)
			MerchantRepairAllButton:Enable()
		else
			SetDesaturation(MerchantRepairAllIcon, true)
			MerchantRepairAllButton:Disable()
		end
	end
end

function CombuctorBag:UpdateLock()
	local bagID = self:GetID()
	local player = self:GetParent():GetPlayer()

	if IsInventoryItemLocked(CombuctorUtil:GetInvSlot(bagID)) and not CombuctorUtil:IsCachedBag(bagID, player) then
		SetItemButtonDesaturated(self, true)
	else
		SetItemButtonDesaturated(self, nil)
	end
end

function CombuctorBag:UpdateCursor()
	local invID = CombuctorUtil:GetInvSlot(self:GetID())
	if CursorCanGoInSlot(invID) then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

--actually, update texture and count
function CombuctorBag:UpdateTexture()
	local bagID = self:GetID()
	if bagID > 0 then
		local parent = self:GetParent()
		local player = parent:GetPlayer()

		if CombuctorUtil:IsCachedBag(bagID, player) then
			if BagnonDB then
				local link, count = select(2, BagnonDB:GetBagData(self:GetID(), player))
				if link then
					self.hasItem = true
					SetItemButtonTexture(self, select(10, GetItemInfo(link)))
				else
					SetItemButtonTexture(self, 'Interface/PaperDoll/UI-PaperDoll-Slot-Bag')
					self.hasItem = nil
				end
				SetItemButtonTextureVertexColor(self, 1, 1, 1)
				self:SetCount(count)
			end
		else
			local texture = GetInventoryItemTexture('player', CombuctorUtil:GetInvSlot(self:GetID()))
			if texture then
				self.hasItem = true

				SetItemButtonTexture(self, texture)
				SetItemButtonTextureVertexColor(self, 1, 1, 1)
			else
				self.hasItem = nil

				SetItemButtonTexture(self, 'Interface/PaperDoll/UI-PaperDoll-Slot-Bag')
				if bagID > (GetNumBankSlots() + 4) then
					SetItemButtonTextureVertexColor(self, 1, 0.1, 0.1)
				else
					SetItemButtonTextureVertexColor(self, 1, 1, 1)
				end
			end
			self:SetCount(GetInventoryItemCount('player', CombuctorUtil:GetInvSlot(self:GetID())))
		end
	end
end

function CombuctorBag:SetCount(count)
	local text = getglobal(self:GetName() .. 'Count')
	if self:GetID() > 0 then
		local count = count or 0
		if count > 1 then
			if count > 999 then
				text:SetText(format('%.1fk', count/1000))
			else
				text:SetText(count)
			end
			text:Show()
		else
			text:Hide()
		end
	else
		text:Hide()
	end
end


--[[ Frame Events ]]--

function CombuctorBag:OnClick(button)
	local parent = self:GetParent()
	local player = parent:GetPlayer()
	local bagID = self:GetID()

	if not CombuctorUtil:IsCachedBag(bagID, player) then
		if CursorHasItem() and not CombuctorUtil:IsCachedBag(bagID, player) then
			if bagID == KEYRING_CONTAINER then
				PutKeyInKeyRing()
			elseif bagID == BACKPACK_CONTAINER then
				PutItemInBackpack()
			else
				PutItemInBag(ContainerIDToInventoryID(bagID))
			end
		elseif bagID > (GetNumBankSlots() + 4) then
			self:PurchaseSlot()
		end
	end
end

function CombuctorBag:OnDrag()
	local parent = self:GetParent()
	local player = parent:GetPlayer()
	local bagID = self:GetID()

	if not(CombuctorUtil:IsCachedBag(bagID, player) or bagID <= 0) then
		PlaySound('BAGMENUBUTTONPRESS')
		PickupBagFromSlot(CombuctorUtil:GetInvSlot(bagID))
	end
end

function CombuctorBag:OnShow()
	if self:GetID() > 0 and self:GetParent() then
		self:UpdateTexture()
	end
end

--tooltip functions
function CombuctorBag:OnEnter()
	local frame = self:GetParent()
	local player = frame:GetPlayer()
	local bagID = self:GetID()

	self:AnchorTooltip()

	--backpack tooltip
	if bagID == BACKPACK_CONTAINER then
		GameTooltip:SetText(BACKPACK_TOOLTIP, 1, 1, 1)
	--bank specific code
	elseif bagID == BANK_CONTAINER then
		GameTooltip:SetText('Bank', 1, 1, 1)
	--keyring specific code...again
	elseif bagID == KEYRING_CONTAINER then
		GameTooltip:SetText(KEYRING, 1, 1, 1)
	--cached bags
	elseif CombuctorUtil:IsCachedBag(bagID, player) then
		local link = select(2, BagnonDB:GetBagData(bagID, player))
		if link then
			GameTooltip:SetHyperlink(link)
		else
			GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
		end
	else
		if not GameTooltip:SetInventoryItem('player', CombuctorUtil:GetInvSlot(bagID)) then
			if bagID > (GetNumBankSlots() + 4) then
				GameTooltip:SetText(BANK_BAG_PURCHASE, 1, 1, 1)
				SetTooltipMoney(GameTooltip, GetBankSlotCost(GetNumBankSlots()))
			else
				GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
			end
		end
	end
	GameTooltip:Show()
end
CombuctorBag.UpdateTooltip = CombuctorBag.OnEnter

function CombuctorBag:OnLeave()
	GameTooltip:Hide()
end

function CombuctorBag:AnchorTooltip()
	if self:GetRight() > (GetScreenWidth()/2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
end


function CombuctorBag:PurchaseSlot()
	if not StaticPopupDialogs['CONFIRM_BUY_BANK_SLOT_COMBUCTOR'] then
		StaticPopupDialogs['CONFIRM_BUY_BANK_SLOT_COMBUCTOR'] = {
			text = TEXT(CONFIRM_BUY_BANK_SLOT),
			button1 = TEXT(YES),
			button2 = TEXT(NO),

			OnAccept = function() PurchaseSlot() end,

			OnShow = function() MoneyFrame_Update(this:GetName().. 'MoneyFrame', GetBankSlotCost(GetNumBankSlots())) end,

			hasMoneyFrame = 1,
			timeout = 0,
			hideOnEscape = 1,
		}
	end

	PlaySound('igMainMenuOption')
	StaticPopup_Show('CONFIRM_BUY_BANK_SLOT_COMBUCTOR')
end