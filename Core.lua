local _, ns = ...
local Addon = ns.Addon
local L = ns.L

local AK_Prefix = "AngryKeystones"
local AK_Schedule = "Schedule|%s"

function Addon:GetKeystoneMsg(current)
	local keystoneMapID = self.db["mapId"]
	local keystoneLevel = self.db["mythicLevel"]

	if current and type(current) == "boolean" then
		keystoneMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
		keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
	end

	if current and type(current) == "number" then
		keystoneMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
		keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
		if keystoneLevel then keystoneLevel = keystoneLevel + current end
	end

	local message = "0"
	if keystoneLevel and keystoneMapID then
		message = format("%d:%d", keystoneMapID, keystoneLevel)
	end

	return message
end

function Addon:SendKeystoneMsg()
	if not self.db["angryKeystone"] or not IsInGroup(LE_PARTY_CATEGORY_HOME) then return end

	self:SendCommMessage(AK_Prefix, format(AK_Schedule, self:GetKeystoneMsg()), "PARTY")
	self:SendCommMessage(ns.Prefix, self:GetKeystoneMsg(true), "PARTY")
end

function Addon:LoadCurrentAffixes()
	local affixes = C_MythicPlus.GetCurrentAffixes()
	if not affixes then return end

	for i = 1, ns.NUM_AFFIXES do
		self.db["affixId"..i] = affixes[i] and affixes[i].id or 0
	end
end

function Addon:PrintKeystone()
	local mapId, level, keystoneItemID = self.db["mapId"], self.db["mythicLevel"], self.db["keystoneItemID"]
	local mapName = C_ChallengeMode.GetMapUIInfo(mapId)
	local keystone = mapName and format(CHALLENGE_MODE_KEYSTONE_HYPERLINK, mapName, level)
	if not keystone then return end

	local affixIds = ""
	for i = 1, 5 do -- Server verification
		affixIds = affixIds..":"..(self.db["affixId"..i] or 0)
	end

	_G.DEFAULT_CHAT_FRAME:AddMessage(L["Keystone Link: "]..CreateSimpleTextureMarkup(C_Item.GetItemIconByID(keystoneItemID), 16, 16)..format("|cffa335ee|Hkeystone:%d:%d:%d%s|h[%s]|h|r", keystoneItemID, mapId, level, affixIds, keystone))
end

function Addon:OnEnable()
	self:LoadCurrentAffixes()
	self:RegisterComm(ns.Prefix)

	-- AngryKeystones
	local AngryKeystones = _G.AngryKeystones
	if AngryKeystones then
		local module = AngryKeystones.Modules and AngryKeystones.Modules.Schedule
		if module and module.SendCurrentKeystone then
			self:RawHook(module, "SendCurrentKeystone", function()
				if self.db["angryKeystone"] then
					self:SendKeystoneMsg()
				else
					self.hooks[module]["SendCurrentKeystone"](module)
				end
			end)
		end
	else
		self:RegisterComm(AK_Prefix)
		self:RegisterEvent("GROUP_ROSTER_UPDATE", "SendKeystoneMsg")
		self:RegisterEvent("CHALLENGE_MODE_START", "SendKeystoneMsg")
		self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "SendKeystoneMsg")
	end

	-- LibOpenRaid
	local LibOR = LibStub("LibOpenRaid-1.0", true)
	if LibOR then
		self.classID = select(3, UnitClass("player"))
		self.LibOR = LibOR
		self:HookLibOpenRaid(LibOR)
	end

	local LKS = LibStub("LibKeystone", true)
	if LKS then
		self:HookLibKeystone(LKS)
	end
end

function Addon:OnCommReceived(_, message, ...)
	if strmatch(message, "quest") then
		self:SendKeystoneMsg()
	end
end

function Addon:GetLibORKeystoneMsg()
	local level = self.db["mythicLevel"] or 0
	local mapID = self.db["mapId"] or 0
	local classID = self.classID
	local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
	local rating = ratingSummary and ratingSummary.currentSeasonScore or 0

	return format("K,%d,0,%d,%d,%d,%d", level, mapID, classID, rating, mapID)
end

ns.CONST_COMM_CHANNEL = {
	["PARTY"] = "0x1",
	["RAID"] = "0x2",
	["GUILD"] = "0x4",
}

function Addon:SendLibORKeystoneMsg(flags)
	local SendCommData = self.LibOR and self.LibOR.commHandler and self.LibOR.commHandler.SendCommData
	if SendCommData then
		SendCommData(self:GetLibORKeystoneMsg(), flags)
	end
end

function Addon:HookLibOpenRaid(lib)
	local KeystoneManager = lib.KeystoneInfoManager
	if not KeystoneManager then return end

	if KeystoneManager.SendPlayerKeystoneInfoToParty then
		self:RawHook(KeystoneManager, "SendPlayerKeystoneInfoToParty", function()
			if self.db["angryKeystone"] then
				self:SendLibORKeystoneMsg(ns.CONST_COMM_CHANNEL["PARTY"])
			else
				self.hooks[KeystoneManager]["SendPlayerKeystoneInfoToParty"](KeystoneManager)
			end
		end)
	end

	if KeystoneManager.SendPlayerKeystoneInfoToGuild then
		self:RawHook(KeystoneManager, "SendPlayerKeystoneInfoToGuild", function()
			if self.db["angryKeystone"] then
				self:SendLibORKeystoneMsg(ns.CONST_COMM_CHANNEL["GUILD"])
			else
				self.hooks[KeystoneManager]["SendPlayerKeystoneInfoToGuild"](KeystoneManager)
			end
		end)
	end
end

function Addon:HookLibKeystone(lib)
	local callbackMap = lib.callbackMap

	local throttleTime = 3
	local throttleTable = {
		GUILD = 0,
		PARTY = 0,
	}
	local timerTable = {}
	local functionTable

	local function GetInfo()
		local keyLevel = C_MythicPlus.GetOwnedKeystoneLevel()
		if type(keyLevel) ~= "number" then
			keyLevel = 0
		end
		local keyChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
		if type(keyChallengeMapID) ~= "number" then
			keyChallengeMapID = 0
		end
		local playerRatingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
		local playerRating = 0
		if type(playerRatingSummary) == "table" and type(playerRatingSummary.currentSeasonScore) == "number" then
			playerRating = playerRatingSummary.currentSeasonScore
		end
		if self.db["angryKeystone"] then
			keyLevel, keyChallengeMapID = self.db["mythicLevel"] or 0, self.db["mapId"] or 0
		end
		return keyLevel, keyChallengeMapID, playerRating
	end

	do
		local IsInGroup, IsInGuild = IsInGroup, IsInGuild
		local function SendToParty()
			if timerTable.PARTY then
				timerTable.PARTY:Cancel()
				timerTable.PARTY = nil
			end
			if IsInGroup() then
				local keyLevel, keyChallengeMapID, playerRating = GetInfo()
				local result = C_ChatInfo.SendAddonMessage("LibKS", format("%d,%d,%d", keyLevel, keyChallengeMapID, playerRating), "PARTY")
				if result == 9 then
					timerTable.PARTY = C_Timer.NewTimer(throttleTime, SendToParty)
				end
			end
		end
		local function SendToGuild()
			if timerTable.GUILD then
				timerTable.GUILD:Cancel()
				timerTable.GUILD = nil
			end
			if IsInGuild() then
				local keyLevel, keyChallengeMapID, playerRating = GetInfo()
				if keyLevel ~= 0 and lib.isGuildHidden then
					keyLevel, keyChallengeMapID = -1, -1
				end
				local result = C_ChatInfo.SendAddonMessage("LibKS", format("%d,%d,%d", keyLevel, keyChallengeMapID, playerRating), "GUILD")
				if result == 9 then
					timerTable.GUILD = C_Timer.NewTimer(throttleTime, SendToGuild)
				end
			end
		end
		functionTable = {
			PARTY = SendToParty,
			GUILD = SendToGuild,
		}
	end

	local currentLevel, currentMap = nil, nil
	local function DidKeystoneChange()
		local keyLevel, keyChallengeMapID = GetInfo()
		if keyLevel ~= currentLevel or keyChallengeMapID ~= currentMap then
			currentLevel, currentMap = keyLevel, keyChallengeMapID
			local t = GetTime()
			if t - throttleTable.PARTY > throttleTime then
				throttleTable.PARTY = t
				functionTable.PARTY()
			elseif not timerTable.PARTY then
				timerTable.PARTY = C_Timer.NewTimer(throttleTime, functionTable.PARTY)
			end
		end
	end

	local frame = lib.frame
	if frame then
		frame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
			if event == "CHAT_MSG_ADDON" then
				if prefix == "LibKS" and throttleTable[channel] then
					if msg == "R" then
						local t = GetTime()
						if t - throttleTable[channel] > throttleTime then
							throttleTable[channel] = t
							functionTable[channel]()
						elseif not timerTable[channel] then
							timerTable[channel] = C_Timer.NewTimer(throttleTime, functionTable[channel])
						end
						return
					end

					local keyLevelStr, keyChallengeMapIDStr, playerRatingStr = strmatch(msg, "^(%d+),(%d+),(%d+)$")
					if keyLevelStr and keyChallengeMapIDStr and playerRatingStr then
						local keyLevel = tonumber(keyLevelStr)
						local keyChallengeMapID = tonumber(keyChallengeMapIDStr)
						local playerRating = tonumber(playerRatingStr)
						if keyLevel and keyChallengeMapID and playerRating then
							for _, func in next, callbackMap do
								func(keyLevel, keyChallengeMapID, playerRating, Ambiguate(sender, "none"), channel)
							end
						end
					end
				end
			elseif event == "CHALLENGE_MODE_COMPLETED" then
				currentLevel, currentMap = GetInfo()
				self:RegisterEvent("ITEM_CHANGED")
				self:RegisterEvent("ITEM_PUSH")
				self:RegisterEvent("PLAYER_LEAVING_WORLD")
			elseif event == "PLAYER_LEAVING_WORLD" then
				self:UnregisterEvent("ITEM_CHANGED")
				self:UnregisterEvent("ITEM_PUSH")
				self:UnregisterEvent(event)
			elseif event == "ITEM_CHANGED" or (event == "ITEM_PUSH" and msg == 4352494) then
				C_Timer.NewTimer(1, DidKeystoneChange)
			end
		end)
	end
end