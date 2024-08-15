local ADDON, ns = ...
local Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceEvent-3.0","AceHook-3.0","AceComm-3.0")

local L = {}
setmetatable(L, {
	__index = function(self, key) return key end
})

ns.Addon = Addon
ns.L = L
ns.Version = C_AddOns.GetAddOnMetadata(ADDON, "Version")
ns.Prefix = "FakeKeystones"

_G[ADDON] = ns

local defaults = {
	["mapId"] = 376,
	["mythicLevel"] = 20,
	["affixId1"] = 9,
	["affixId2"] = 11,
	["affixId3"] = 4,
	["affixId4"] = 120,
	["angryKeystone"] = true,
	["challengesFrame"] = false,
	["weeklyLevel"] = 20,
	["dungeons"] = {},
	["currentExpansion"] = true,
	["keystoneItemID"] = 180653,
}

function Addon:OnInitialize()
	self.db = FakeKeystones_DB or {}
	FakeKeystones_DB = self.db

	for key in pairs(self.db) do
		if defaults[key] == nil then
			self.db[key] = nil
		end
	end

	for key, value in pairs(defaults) do
		if self.db[key] == nil then
			if type(value) == "table" then
				self.db[key] = {}
				for k in pairs(value) do
					self.db[key][k] = value[k]
				end
			else
				self.db[key] = value
			end
		end
	end
end

function Addon:Print(...)
	_G.DEFAULT_CHAT_FRAME:AddMessage("|cFF70B8FF"..ADDON..":|r " .. format(...))
end

function Addon:Error(...)
	_G.UIErrorsFrame:AddMessage("|cFF70B8FF"..format(...).."|r ")
end
