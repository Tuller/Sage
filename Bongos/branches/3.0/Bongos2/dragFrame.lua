--[[
	dragFrame.lua
--]]

local L = BONGOS_LOCALS

local scaling = false

--[[ Tooltips ]]--

local function DragFrame_OnEnter(self)
	if(not scaling) then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")

		if tonumber(self:GetText()) then
			GameTooltip:SetText(format("ActionBar %s", self:GetText()), 1, 1, 1)
		else
			GameTooltip:SetText(format("%s Bar", self.parent.id:gsub("^%l", string.upper)), 1, 1, 1)
		end

		if self.parent.ShowMenu then
			GameTooltip:AddLine(L.ShowConfig)
		end

		if self.parent:IsShown() then
			GameTooltip:AddLine(L.HideBar)
		else
			GameTooltip:AddLine(L.ShowBar)
		end
		GameTooltip:AddLine(format(L.SetAlpha, ceil(self.parent:GetFrameAlpha()*100)))

		GameTooltip:Show()
	end
end

local function DragFrame_OnLeave(self)
	GameTooltip:Hide()
end


--[[ Movement Functions ]]--

local function DragFrame_OnMouseDown(self, arg1)
	if arg1 == "LeftButton" then
		self.isMoving = true
		self.parent:StartMoving()

		if(GameTooltip:IsOwned(self)) then
			GameTooltip:Hide()
		end
	end
end

local function DragFrame_OnMouseUp(self, arg1)
	if self.isMoving then
		self.isMoving = nil
		self.parent:StopMovingOrSizing()
		self.parent:Stick()
		DragFrame_OnEnter(self)
	end
end

local function DragFrame_OnMouseWheel(self, arg1)
	local newAlpha = min(max(self.parent:GetAlpha() + (arg1 * 0.1), 0), 1)
	if newAlpha ~= self.parent:GetAlpha() then
		self.parent:SetFrameAlpha(newAlpha)
		DragFrame_OnEnter(self)
	end
end

local function DragFrame_OnClick(self, arg1)
	if arg1 == "RightButton" then
		if IsShiftKeyDown() then
			self.parent:ToggleFrame()
		elseif self.parent.ShowMenu then
			self.parent:ShowMenu()
		end
	elseif arg1 == "MiddleButton" then
		self.parent:ToggleFrame()
	end
	DragFrame_OnEnter(self)
end

--updates the drag button color of a given bar if its attached to another bar
local function DragFrame_UpdateColor(self)
	if not self.parent:IsShown() then
		if self.parent:GetAnchor() then
			self:SetTextColor(0.4, 0.4, 0.4)
		else
			self:SetTextColor(0.8, 0.8, 0.8)
		end
		self.highlight:SetTexture(0.2, 0.3, 0.4, 0.5)
	else
		if self.parent:GetAnchor() then
			self:SetTextColor(0.1, 0.5, 0.1)
		else
			self:SetTextColor(0.2, 1, 0.2)
		end
		self.highlight:SetTexture(0, 0, 0.6, 0.5)
	end
end

local function Scale_OnEnter(self)
	self:GetNormalTexture():SetVertexColor(1, 1, 1)
end

local function Scale_OnLeave(self)
	self:GetNormalTexture():SetVertexColor(1, 0.82, 0)
end

--credit goes to AnduinLothar for this code, I've only modified it to work with Bongos/Sage
local function Scale_OnUpdate(self, elapsed)
	local frame = self.parent
	local x, y = GetCursorPosition()
	local currScale = frame:GetEffectiveScale()
	x = x / currScale
	y = y / currScale

	local left, top = frame:GetLeft(), frame:GetTop()
	local wScale = (x-left)/frame:GetWidth()
	local hScale = (top-y)/frame:GetHeight()

	local scale = max(min(max(wScale, hScale), 1.2), 0.8)
	local newScale = min(max(frame:GetScale() * scale, 0.5), 1.5)
	frame:SetFrameScale(newScale, IsShiftKeyDown())
end

local function Scale_StartScaling(self)
	scaling = true
	self:GetParent():LockHighlight()
	self:SetScript("OnUpdate", Scale_OnUpdate)
end

local function Scale_StopScaling(self)
	scaling = nil
	self:GetParent():UnlockHighlight()
	self:SetScript("OnUpdate", nil)
end

--[[ Constructor ]]--

function BDragFrame_New(parent)
	local frame = CreateFrame("Button", nil, UIParent)
	frame.parent = parent
	frame.UpdateColor = DragFrame_UpdateColor

	frame:SetClampedToScreen(true)
	frame:SetFrameStrata(parent:GetFrameStrata())
	frame:SetAllPoints(parent)
	frame:SetFrameLevel(6)

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
	bg:SetVertexColor(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)
	frame:SetNormalTexture(bg)

	local highlight = frame:CreateTexture(nil, "BACKGROUND")
	highlight:SetTexture(0, 0, 0.6, 0.5)
	highlight:SetAllPoints(frame)
	frame:SetHighlightTexture(highlight)
	frame.highlight = highlight

	frame:SetTextFontObject(GameFontNormalLarge)
	frame:SetHighlightTextColor(1, 1, 1)
	frame:SetText(parent.id)

	frame:RegisterForClicks("AnyUp")
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseDown", DragFrame_OnMouseDown)
	frame:SetScript("OnMouseUp", DragFrame_OnMouseUp)
	frame:SetScript("OnMouseWheel", DragFrame_OnMouseWheel)
	frame:SetScript("OnClick", DragFrame_OnClick)
	frame:SetScript("OnEnter", DragFrame_OnEnter)
	frame:SetScript("OnLeave", DragFrame_OnLeave)
	frame:Hide()

	local scale = CreateFrame("Button", nil, frame)
	scale:SetPoint("BOTTOMRIGHT", frame)
	scale:SetHeight(16); scale:SetWidth(16)
	scale:SetFrameLevel(frame:GetFrameLevel() + 1)

	scale:SetNormalTexture("Interface\\AddOns\\Bongos2\\textures\\Rescale")
	scale:GetNormalTexture():SetVertexColor(1, 0.82, 0)

	scale:SetScript("OnEnter", Scale_OnEnter)
	scale:SetScript("OnLeave", Scale_OnLeave)
	scale:SetScript("OnMouseDown", Scale_StartScaling)
	scale:SetScript("OnMouseUp", Scale_StopScaling)
	scale.parent = frame.parent

	return frame
end