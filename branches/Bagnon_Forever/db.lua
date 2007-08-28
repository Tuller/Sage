--[[
	Database.lua
		BagnonForever"s implementation of BagnonDB
--]]

if not BagnonDB then
	BagnonDB = (Bagnon and Bagnon:NewModule("Bagnon-DB")) or (Combuctor and Combuctor:NewModule("Combuctor-DB"))
	BagnonDB.addon = "Bagnon_Forever"
else
	error(format("Already using %s to view cached data", BagnonDB.addon or "<Unknown Addon>"))
	return
end

--constants
local L = BAGNON_FOREVER_LOCALS
local CURRENT_VERSION = GetAddOnMetadata("Bagnon_Forever", "Version")
local NUM_EQUIPMENT_SLOTS = 19

--locals
local tonumber = tonumber
local format = string.format
local strsplit = string.split
local strjoin = string.join

local BagnonUtil = BagnonUtil
local currentPlayer = UnitName("player") --the name of the current player that"s logged on
local currentRealm = GetRealmName() --what currentRealm we"re on
local playerList --a sorted list of players

--[[ Local Functions ]]--

local function ToIndex(bag, slot)
	if tonumber(bag) then
		return (bag < 0 and bag*100 - slot) or bag*100 + slot
	end
	return bag .. slot
end

local function ToBagIndex(bag)
	return (tonumber(bag) and bag*100) or bag
end

--returns the full item link only for items that have enchants/suffixes, otherwise returns the item's ID
local function ToShortLink(link)
	if link then
		local a,b,c,d,e,f,g = link:match("(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):%-?%d+")
		if(b == c and c == d and d == e and e == f and f == g) then
			return a
		end
		return format("item:%s:%s:%s:%s:%s:%s:%s:0", a, b, c, d, e, f, g)
	end
end

local function GetBagSize(bag)
	if bag == KEYRING_CONTAINER then
		return GetKeyRingSize()
	end
	if bag == "e" then
		return NUM_EQUIPMENT_SLOTS
	end
	return GetContainerNumSlots(bag)
end


--[[ Startup Functions ]]--

function BagnonDB:Initialize()
	if not(BagnonForeverDB and BagnonForeverDB.version) then
		BagnonForeverDB = {version = CURRENT_VERSION}
	else
		local cMajor, cMinor = CURRENT_VERSION:match("(%d+)%.(%d+)")
		local major, minor = BagnonForeverDB.version:match("(%d+)%.(%d+)")

		if major ~= cMajor then
			self:Print(L.UpdatedIncompatible)
			BagnonForeverDB = {version = cVersion}
		elseif minor ~= cMinor then
			self:UpdateSettings()
		end

		if BagnonForeverDB.version ~= CURRENT_VERSION then
			self:UpdateVersion()
		end
	end

	self.db = BagnonForeverDB
	local realm = GetRealmName()
	if not self.db[realm] then
		self.db[realm] = {}
	end
	self.rdb = self.db[realm]

	local player = UnitName("player")
	if not self.rdb[player] then
		self.rdb[player] = {}
	end
	self.pdb = self.rdb[player]
end

function BagnonDB:UpdateSettings()
end

function BagnonDB:UpdateVersion()
	BagnonForeverDB.version = CURRENT_VERSION
	self:Print(format(L.Updated, BagnonForeverDB.version))
end

function BagnonDB:Enable()
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")

	self:SaveMoney()
	self:SaveBagAll(0)
	self:SaveBagAll(-2)
	self:SaveEquipment()
end


--[[  Events ]]--

function BagnonDB:PLAYER_MONEY()
	self:SaveMoney()
end

function BagnonDB:BAG_UPDATE(event, bag)
	if not(BagnonUtil:IsCachedBag(bag)) or BagnonUtil:AtBank() then
		self:OnBagUpdate(bag)
	end
end

function BagnonDB:PLAYERBANKSLOTS_CHANGED()
	self:OnBagUpdate(-1)
end

function BagnonDB:BANKFRAME_OPENED()
	self:SaveBagAll(-1)
	for bag = 5, 11 do
		self:SaveBagAll(bag)
	end
end

function BagnonDB:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == "player" then
		self:SaveEquipment()
	end
end


--[[
	Access  Functions
		Bagnon requires all of these functions to be present when attempting to view cached data
--]]

--[[
	BagnonDB:GetPlayers()
		returns:
			iterator of all players on this realm with data
		usage:
			for playerName, data in BagnonDB:GetPlayers()
--]]
function BagnonDB:GetPlayerList()
	if(not playerList) then
		playerList = {}

		for player in self:GetPlayers() do
			table.insert(playerList, player)
		end

		--sort by currentPlayer first, then alphabetically
		table.sort(playerList, function(a, b)
			if(a == currentPlayer) then
				return true
			end
			if(b == currentPlayer) then
				return false
			end
			return a < b
		end)
	end
	return playerList
end

function BagnonDB:GetPlayers()
	return pairs(self.rdb)
end


--[[
	BagnonDB:GetMoney(player)
		args:
			player (string)
				the name of the player we"re looking at.  This is specific to the current realm we"re on

		returns:
			(number) How much money, in copper, the given player has
--]]
function BagnonDB:GetMoney(player)
	local playerData = self.rdb[player]
	if playerData then
		return playerData.g or 0
	end
	return 0
end


--[[
	BagnonDB:GetBagData(bag, player)
		args:
			player (string)
				the name of the player we"re looking at.  This is specific to the current realm we"re on
			bag (number)
				the number of the bag we"re looking at.

		returns:
			size (number)
				How many items the bag can hold (number)
			hyperlink (string)
				The hyperlink of the bag
			count (number)
				How many items are in the bag.  This is used by ammo and soul shard bags
--]]
function BagnonDB:GetBagData(bag, player)
	local playerDB = self.rdb[player]
	if playerDB then
		local bagInfo = playerDB[ToBagIndex(bag)]
		if bagInfo then
			local size, link, count = strsplit(",", bagInfo)
			local _, hyperLink, quality, texture
			if(link) then
				_,hyperLink,_,_,_,_,_,_,_, texture = GetItemInfo(link)
			end
			return tonumber(size), hyperLink, tonumber(count) or 1, texture
		end
	end
end

--[[
	BagnonDB:GetItemData(bag, slot, player)
		args:
			player (string)
				the name of the player we"re looking at.  This is specific to the current realm we"re on
			bag (number)
				the number of the bag we"re looking at.
			itemSlot (number)
				the specific item slot we"re looking at

		returns:
			hyperLink (string)
				The hyperLink of the item
			count (number)
				How many of there are of the specific item
			texture (string)
				The filepath of the item"s texture
			quality (number)
				The numeric representaiton of the item's quality: from 0 (poor) to 7 (artifcat)
--]]
function BagnonDB:GetItemData(bag, slot, player)
	local playerDB = self.rdb[player]
	if playerDB then
		local itemInfo = playerDB[ToIndex(bag, slot)]
		if itemInfo then
			local link, count = strsplit(",", itemInfo)
			if(link) then
				local _,hyperLink, quality,_,_,_,_,_,_, texture = GetItemInfo(link)
				return hyperLink, tonumber(count) or 1, texture, tonumber(quality)
			end
		end
	end
end

--[[
	Returns how many of the specific item id the given player has in the given bag
--]]
function BagnonDB:GetItemCount(itemLink, bag, player)
	local total = 0
	local itemLink = select(2, GetItemInfo(ToShortLink(itemLink)))
	local size = (self:GetBagData(bag, player)) or 0
	for slot = 1, size do
		local link, count = self:GetItemData(bag, slot, player)
		if link == itemLink then
			total = total + (count or 1)
		end
	end

	return total
end

--[[
	Storage Functions
		How we store the data (duh)
--]]


--[[  Storage Functions ]]--

function BagnonDB:SaveMoney()
	self.pdb.g = GetMoney()
end

--saves all the player"s equipment data information
function BagnonDB:SaveEquipment()
	for slot = 0, NUM_EQUIPMENT_SLOTS do
		local link = GetInventoryItemLink("player", slot)
		local index = ToIndex("e", slot)

		if link then
			local link = ToShortLink(link)
			local count =  GetInventoryItemCount("player", slot)
			count = count > 1 and count or nil

			if(link and count) then
				self.pdb[index] = format("%s,%d", link, count)
			else
				self.pdb[index] = link
			end
		else
			self.pdb[index] = nil
		end
	end
end

--saves data about a specific item the current player has
function BagnonDB:SaveItem(bag, slot)
	local texture, count = GetContainerItemInfo(bag, slot)

	local index = ToIndex(bag, slot)

	if texture then
		local link = ToShortLink(GetContainerItemLink(bag, slot))
		count = count > 1 and count or nil

		if(link and count) then
			self.pdb[index] = format("%s,%d", link, count)
		else
			self.pdb[index] = link
		end
	else
		self.pdb[index] = nil
	end
end

--saves all information about the given bag, EXCEPT the bag"s contents
function BagnonDB:SaveBag(bag)
	local data = self.pdb
	local size = GetBagSize(bag)
	local index = ToBagIndex(bag)

	if size > 0 then
		local link
		if(bag > 0) then
			link = ToShortLink(GetInventoryItemLink("player", BagnonUtil:GetInvSlot(bag)))
		end
		local count =  GetInventoryItemCount("player", slot)
		count = count > 1 and count or nil

		if(size and link and count) then
			self.pdb[index] = format("%s,%s,%d", size, link, count)
		elseif(size and link) then
			self.pdb[index] = format("%s,%s", size, link)
		else
			self.pdb[index] = size
		end
	else
		self.pdb[index] = nil
	end
end

--saves both relevant information about the given bag, and all information about items in the given bag
function BagnonDB:SaveBagAll(bag)
	self:SaveBag(bag)
	for slot = 1, GetBagSize(bag) do
		self:SaveItem(bag, slot)
	end
end

function BagnonDB:OnBagUpdate(bag)
	if BagnonUtil:AtBank() then
		for i = 1, 11 do
			self:SaveBag(i)
		end
	else
		for i = 1, 4 do
			self:SaveBag(i)
		end
	end

	for slot = 1, GetBagSize(bag) do
		self:SaveItem(bag, slot)
	end
end


--[[ Removal Functions ]]--

--removes all saved data about the given player
function BagnonDB:RemovePlayer(player, realm)
	local realm = realm or currentRealm
	local rdb = self.db[realm]
	if rdb then
		rdb[player] = nil
	end

	if realm == currentRealm and playerList then
		for i,character in pairs(playerList) do
			if(character == player) then
				table.remove(playerList, i)
				break
			end
		end
	end
end