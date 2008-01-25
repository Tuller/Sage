--[[
	Bongos.lua
		Driver for bongos bars
--]]

Bongos = DongleStub('Dongle-1.0'):New('Bongos')
Bongos.dbName = 'Bongos2DB'
local CURRENT_VERSION = GetAddOnMetadata('Bongos2', 'Version')
local L = BONGOS_LOCALS


--[[ Startup ]]--

function Bongos:Initialize()
	local defaults = {
		profile = {
			sticky = true,
			showTooltips = true,
			showHotkeys = true,
			showMacros = true,
			rangeColoring = true,
			showEmpty = false,
			showMinimap = true,
			highlightBuffs = true,
			rangeColor = {r = 1, g = 0.5, b = 0.5},
			bars = {}
		}
	}
	self.db = self:InitializeDB(self.dbName, defaults)
	self.profile = self.db.profile
end

function Bongos:Enable()
	if BongosVersion then
		local cMajor, cMinor = CURRENT_VERSION:match('(%d+)%.(%d+)')
		local major, minor = BongosVersion:match('(%d+)%.(%d+)')

		--compatibility break
		if major ~= cMajor then
			self.db:ResetDB()
			self.profile = self.db.profile
			self:Print(L.UpdatedIncompatible)
		--settings change
		elseif minor ~= cMinor then
			self:UpdateSettings()
		end
	--handle upgrading from <= 1.5 to 1.6+ because I'm a moron sometimes
	else
		self:UpdateSettings()
	end

	if BongosVersion ~= CURRENT_VERSION then
		self:UpdateVersion()
	end

	self:RegisterSlashCommands()
	self:LoadModules()

	self:RegisterMessage('DONGLE_PROFILE_CREATED')
	self:RegisterMessage('DONGLE_PROFILE_CHANGED')
	self:RegisterMessage('DONGLE_PROFILE_DELETED')
	self:RegisterMessage('DONGLE_PROFILE_COPIED')
	self:RegisterMessage('DONGLE_PROFILE_RESET')
	self:RegisterEvent('ADDON_LOADED', 'LoadOptions')
end

function Bongos:UpdateSettings()
	--convert keybindings
	if BongosActionBar then
		BongosActionBar:ConvertBindings()
	end

	--run the spacing change (1.5 -> 1.7)
	for profile,sets in pairs(self.db.sv.profiles) do
		if sets.bars then
			--run the spacing converter
			for barID,barSets in pairs(sets.bars) do
				barSets.spacing = (barSets.spacing or barSets.space)
				barSets.space = nil
			end

			--update the bag frame settings (1.9)
			local bagSets = sets.bars.bags
			if bagSets then
				bagSets.vertical = bagSets.rows and true or nil
				bagSets.showKeyring = true
				bagSets.rows = nil
			end
		end

		sets.selfCastKey = nil
		sets.quickMoveKey = nil
		sets.lockButtons = nil
		sets.mapx = nil
		sets.mapy = nil
	end

	--enable lock actionbar (1.8/2.2)
	LOCK_ACTIONBAR = '1'
end

function Bongos:UpdateVersion()
	BongosVersion = CURRENT_VERSION
	self:Print(format(L.Updated, BongosVersion))
end

function Bongos:LoadModules()
	for name, module in self:IterateModules() do
		assert(module.Load, format('Bongos Module %s: Missing Load function', name))
		module:Load()
	end
	Bongos:UpdateMinimapButton()
	BBar:ForAll('Reanchor')
end

function Bongos:UnloadModules()
	for name, module in self:IterateModules() do
		assert(module.Unload, format('Bongos Module %s: Missing Unload function', name))
		module:Unload()
	end
end

function Bongos:LoadOptions(event, addon)
	if(addon == 'Bongos2_Options') then
		for name, module in self:IterateModules() do
			if(module.LoadOptions) then
				module:LoadOptions()
			end
		end
		BongosOptions:ShowPanel(L.General)
		self:UnregisterEvent(event)
	end
end


--[[ Profile Functions ]]--

function Bongos:SaveProfile(profile)
	local currentProfile = self.db:GetCurrentProfile()
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.copying = true
		self.db:SetProfile(profile)
		self.db:CopyProfile(currentProfile)
		self.copying = nil
	end
end

function Bongos:SetProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.db:SetProfile(profile)
	end
end

function Bongos:DeleteProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self.db:DeleteProfile(profile)
	else
		self:Print(L.CantDeleteCurrentProfile)
	end
end

function Bongos:CopyProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.copying = true
		self.db:ResetProfile()
		self.db:CopyProfile(profile)
		self.copying = nil
	end
end

function Bongos:ResetProfile()
	self:UnloadModules()
	self.db:ResetProfile()
end

function Bongos:ListProfiles()
	self:Print(L.AvailableProfiles)
	for _,k in ipairs(self.db:GetProfiles()) do
		DEFAULT_CHAT_FRAME:AddMessage(" - " .. k)
	end
end

function Bongos:MatchProfile(name)
	local profileList = self.db:GetProfiles()

	local name = name:lower()
	local nameRealm = format('%s - %s', name, GetRealmName():lower())
	local match

	for i, k in ipairs(profileList) do
		local key = k:lower()
		if key == name then
			return k
		elseif key == nameRealm then
			match = k
		end
	end
	return match
end


--[[ Messages ]]--

function Bongos:DONGLE_PROFILE_CREATED(event, db, parent, sv_name, profile_key)
	if(sv_name == self.dbName) then
		self.profile = self.db.profile
		db.version = CURRENT_VERSION
		self:Print(format(L.ProfileCreated , profile_key))
	end
end

function Bongos:DONGLE_PROFILE_CHANGED(event, db, parent, sv_name, profile_key)
	if(sv_name == self.dbName) then
		self.profile = self.db.profile
		if not self.copying then
			self:LoadModules()
			self:Print(format(L.ProfileLoaded, profile_key))
		end
	end
end

function Bongos:DONGLE_PROFILE_DELETED(event, db, parent, sv_name, profile_key)
	if(sv_name == self.dbName) then
		self:Print(format(L.ProfileDeleted, profile_key))
	end
end

function Bongos:DONGLE_PROFILE_COPIED(event, db, parent, sv_name, profile_key, intoProfile_key)
	if(sv_name == self.dbName) then
		self.profile = self.db.profile
		self:LoadModules()
		self:Print(format(L.ProfileCopied, profile_key, intoProfile_key))
	end
end

function Bongos:DONGLE_PROFILE_RESET(event, db, parent, sv_name, profile_key)
	if(sv_name == self.dbName) then
		if not self.copying then
			self.profile = self.db.profile
			self:LoadModules()
			self:Print(format(L.ProfileReset, profile_key))
		end
	end
end


--[[ Config Functions ]]--

function Bongos:SetLock(enable)
	self.profile.locked = enable or false
	if enable then
		BBar:ForAll('Lock')
	else
		BBar:ForAll('Unlock')
	end
end

function Bongos:IsLocked()
	return self.profile.locked
end

function Bongos:SetSticky(enable)
	self.profile.sticky = enable or false
	BBar:ForAll('Reanchor')
end

function Bongos:IsSticky()
	return self.profile.sticky
end


--[[ Settings Access ]]--

function Bongos:SetBarSets(id, sets)
	local id = tonumber(id) or id
	self.profile.bars[id] = sets

	return self.profile.bars[id]
end

function Bongos:GetBarSets(id)
	return self.profile.bars[tonumber(id) or id]
end


--[[ Slash Commands ]]--

function Bongos:RegisterSlashCommands()
	local cmdStr = '|cFF33FF99%s|r: %s'

	local slash = self:InitializeSlashCommand('Bongos Commands', 'BONGOS', 'bongos', 'bgs', 'bob')
	slash:RegisterSlashHandler(format(cmdStr, '/bob', L.ShowOptionsDesc), '^$', 'ShowMenu')
	slash:RegisterSlashHandler(format(cmdStr, 'config', L.LockBarsDesc), '^config$', 'ToggleLockedBars')
	slash:RegisterSlashHandler(format(cmdStr, 'lock', L.LockBarsDesc), '^lock$', 'ToggleLockedBars')
	slash:RegisterSlashHandler(format(cmdStr, 'sticky', L.StickyBarsDesc), '^sticky$', 'ToggleStickyBars')

	slash:RegisterSlashHandler(format(cmdStr, 'scale <barList> <scale>', L.SetScaleDesc), '^scale (.+) ([%d%.]+)', 'SetBarScale')
	slash:RegisterSlashHandler(format(cmdStr, 'setalpha <barList> <opacity>', L.SetAlphaDesc), '^setalpha (.+) ([%d%.]+)', 'SetBarAlpha')

	slash:RegisterSlashHandler(format(cmdStr, 'show <barList>', L.ShowBarsDesc), '^show (.+)', 'ShowBars')
	slash:RegisterSlashHandler(format(cmdStr, 'hide <barList>', L.HideBarsDesc), '^hide (.+)', 'HideBars')
	slash:RegisterSlashHandler(format(cmdStr, 'toggle <barList>', L.ToggleBarsDesc), '^toggle (.+)', 'ToggleBars')

	slash:RegisterSlashHandler(format(cmdStr, 'save <profle>', L.SaveDesc), 'save (%w+)', 'SaveProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'set <profle>', L.SetDesc), 'set (%w+)', 'SetProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'copy <profile>', L.CopyDesc), 'copy (%w+)', 'CopyProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'delete <profile>', L.DeleteDesc), '^delete (%w+)', 'DeleteProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'reset', L.ResetDesc), '^reset$', 'ResetProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'list', L.ListDesc), '^list$', 'ListProfiles')
	slash:RegisterSlashHandler(format(cmdStr, 'version', L.PrintVersionDesc), '^version$', 'PrintVersion')

	self.slash = slash
end

function Bongos:ShowMenu()
	local enabled = select(4, GetAddOnInfo('Bongos2_Options'))
	if enabled then
		if BongosOptions then
			BongosOptions:Toggle()
		else
			LoadAddOn('Bongos2_Options')
		end
	else
		self.slash:PrintUsage()
	end
end

function Bongos:ToggleLockedBars()
	self:SetLock(not self.profile.locked)
end

function Bongos:ToggleStickyBars()
	self:SetSticky(not self.profile.sticky)
end

function Bongos:SetBarScale(args, scale)
	local scale = tonumber(scale)

	if scale and scale > 0 and scale <= 10 then
		for _,barList in pairs({strsplit(' ', args)}) do
			BBar:ForBar(barList, 'SetFrameScale', scale)
		end
	end
end

function Bongos:SetBarAlpha(args, alpha)
	local alpha = tonumber(alpha)

	if alpha and alpha >= 0 and alpha <= 1 then
		for _,barList in pairs({strsplit(' ', args)}) do
			BBar:ForBar(barList, 'SetFrameAlpha', alpha)
		end
	end
end

function Bongos:PrintVersion()
	self:Print(BongosVersion)
end

function Bongos:ShowBars(args)
	for _, barList in pairs({strsplit(' ', args)}) do
		BBar:ForBar(barList, 'ShowFrame')
	end
end

function Bongos:HideBars(args)
	for _, barList in pairs({strsplit(' ', args)}) do
		BBar:ForBar(barList, 'HideFrame')
	end
end

function Bongos:ToggleBars(args)
	for _, barList in pairs({strsplit(' ', args)}) do
		BBar:ForBar(barList, 'ToggleFrame')
	end
end

function Bongos:CleanUp()
	local bars = self.profile.bars
	for id in pairs(self.profile.bars) do
		if not BBar:Get(id) then
			bars[id] = nil
		end
	end
end


--minimap functions
function Bongos:SetShowMinimap(enable)
	self.profile.showMinimap = enable or false
	self:UpdateMinimapButton()
end

function Bongos:ShowingMinimap()
	return self.profile.showMinimap
end

function Bongos:UpdateMinimapButton()
	if self:ShowingMinimap() then
		BongosMinimapButton:UpdatePosition()
		BongosMinimapButton:Show()
	else
		BongosMinimapButton:Hide()
	end
end

function Bongos:SetMinimapButtonPosition(angle)
	self.profile.minimapPos = angle
end

function Bongos:GetMinimapButtonPosition(angle)
	return self.profile.minimapPos
end

--utility function: create a widget class
function Bongos:CreateWidgetClass(type)
	local class = CreateFrame(type)
	local mt = {__index = class}

	function class:New(o)
		if o then
			local type, cType = o:GetFrameType(), self:GetFrameType()
			assert(type == cType, format("'%s' expected, got '%s'", cType, type))
		end
		return setmetatable(o or CreateFrame(type), mt)
	end

	return class
end