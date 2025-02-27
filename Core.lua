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