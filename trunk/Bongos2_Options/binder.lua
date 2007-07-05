--[[
	Bongos Bindings
--]]

local L = BONGOS_LOCALS
L.Bindings = "Bindings"
L.BindingsHelp = "Hover over a button, then press a key to set its binding.  To clear a button's current keybinding, press %s."

local DEFAULT_BINDINGS = 0
local ACCOUNT_BINDINGS = 1
local CHARACTER_BINDINGS = 2

local function Panel_AddPerCharButton(panel)
	local perChar = panel:AddCheckButton(CHARACTER_SPECIFIC_KEYBINDINGS)

	perChar:SetScript("OnShow", function(self)
		KeyBound:Activate()

		self.current = GetCurrentBindingSet()
		self:SetChecked(GetCurrentBindingSet() == CHARACTER_BINDINGS)
		self.desc:SetText(format(L.BindingsHelp, GetBindingText("ESCAPE","KEY_")))
	end)

	perChar:SetScript("OnHide", function(self)
		KeyBound:Deactivate()

		if InCombatLockdown() then
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		else
			SaveBindings(self.current)
		end
	end)

	perChar:SetScript("OnEvent", function(self, event)
		SaveBindings(self.current)
		self:UnregisterEvent(event)
	end)

	perChar:SetScript("OnClick", function(self)
		self.current = (self:GetChecked() and CHARACTER_BINDINGS) or ACCOUNT_BINDINGS
		LoadBindings(self.current)
	end)

	return perChar
end

function BongosOptions:AddBinderPanel()
	local panel = self:AddPanel(L.Bindings)

	local perChar = Panel_AddPerCharButton(panel)

	local desc = panel:CreateFontString()
	desc:SetPoint("TOPLEFT", perChar, "BOTTOMLEFT", 6, -2)
	desc:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, 6)

	desc:SetFontObject("GameFontHighlight")
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")

	perChar.desc = desc

	panel.height = panel.height + 64

	return panel
end

BongosOptions:AddBinderPanel()