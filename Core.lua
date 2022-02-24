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
		message = string.format("%d:%d", keystoneMapID, keystoneLevel)
	end

	return message
end

function Addon:SendKeystoneMsg()
	if not self.db["angryKeystone"] then return end

	self:SendCommMessage(AK_Prefix, format(AK_Schedule, self:GetKeystoneMsg()), "PARTY")
	self:SendCommMessage(ns.Prefix, self:GetKeystoneMsg(true), "PARTY")
end

function Addon:LoadCurrentAffixes()
	local affixes = C_MythicPlus.GetCurrentAffixes()
	if not affixes then return end

	for index = 1, 4 do
		self.db["affixId"..index] = affixes[index] and affixes[index].id
	end
end

function Addon:PrintKeystone()
	local mapId, level, affixId1, affixId2, affixId3, affixId4, keystoneItemID = self.db["mapId"], self.db["mythicLevel"], self.db["affixId1"], self.db["affixId2"], self.db["affixId3"], self.db["affixId4"], self.db["keystoneItemID"]
	local mapName = C_ChallengeMode.GetMapUIInfo(mapId)
	local keystone = mapName and string.format(CHALLENGE_MODE_KEYSTONE_HYPERLINK, mapName, level)
	if not keystone then return end

	_G.DEFAULT_CHAT_FRAME:AddMessage(L["Keystone Link: "]..string.format("|cffa335ee|Hkeystone:%d:%d:%d:%d:%d:%d:%d|h[%s]|h|r", keystoneItemID, mapId, level, affixId1, affixId2, affixId3, affixId4, keystone))
end

function Addon:OnEnable()
	self:LoadCurrentAffixes()
	self:RegisterComm(ns.Prefix)

	if IsAddOnLoaded("AngryKeystones") then 
		local mod = _G.AngryKeystones.Modules.Schedule
		if mod then
			self:RawHook(mod, "SendCurrentKeystone", function()
				if self.db["angryKeystone"] then
					self:SendKeystoneMsg()
				else
					self.hooks[mod].SendCurrentKeystone(mod)
				end
			end, true)
		end
	else
		self:RegisterComm(AK_Prefix)
		self:RegisterEvent("GROUP_ROSTER_UPDATE", "SendKeystoneMsg")
		self:RegisterEvent("CHALLENGE_MODE_START", "SendKeystoneMsg")
		self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "SendKeystoneMsg")
	end
end

function Addon:OnCommReceived(_, message, ...)
	if string.match(message, "quest") then
		self:SendKeystoneMsg()
	end
end