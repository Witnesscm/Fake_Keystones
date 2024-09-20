local ADDON, ns = ...
local Addon = ns.Addon
local L = ns.L
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local Option = Addon:NewModule("Option", "AceEvent-3.0","AceConsole-3.0")

local ipairs = ipairs

local OPTION_MORE_DUNGENOS = 999
local OPTION_THIS_SEASON = OPTION_MORE_DUNGENOS + 1

ns.MapIDs = {}
ns.OldMapIDs = {}
ns.MapList = {}
ns.OldMapList = {}
ns.AffixList = {}

ns.KeystoneItemIDs = {
	[138019] = EXPANSION_NAME6,
	[158923] = EXPANSION_NAME7,
	[180653] = EXPANSION_NAME8,
	[168195] = L["Time Trial Keystone"],
	[187786] = L["Timeworn Keystone"],
}

function Option:Get(key)
	return Addon.db[key]
end

function Option:Set(key, value)
	Addon.db[key] = value
end

function Option:ShowConfig()
	AceConfigDialog:SetDefaultSize(ADDON, 600, 420)
	AceConfigDialog:Open(ADDON)
end

ns.Options = {
	type = "group",
	name = "Fake Keystones",
	get = function(info) return Option:Get(info[#info]) end,
	set = function(info, value) Option:Set(info[#info], value) end,
	args = {
		space = {
			order = 0,
			type = "description",
			name = " ",
			width = "full",
		}
	}
}

function Option:OnEnable()
	RequestRaidInfo()

	AceConfigRegistry:RegisterOptionsTable(ADDON, ns.Options)
	self:RegisterChatCommand("fks", "ShowConfig")
	self:RegisterChatCommand("fakekeystones", "ShowConfig")
	self:RegisterEvent("UPDATE_INSTANCE_INFO")
end

function Option:UPDATE_INSTANCE_INFO(event)
	ns.MapIDs = C_ChallengeMode.GetMapTable()
	sort(ns.MapIDs)

	local currentMap = {}
	for _, id in ipairs(ns.MapIDs) do
		currentMap[id] = true
	end

	for id = 1, 999 do
		local name = C_ChallengeMode.GetMapUIInfo(id)
		if name then
			if currentMap[id] then
				ns.MapList[id] = name
			else
				ns.OldMapList[id] = name
				tinsert(ns.OldMapIDs, id)
			end
		end
	end

	ns.MapList[OPTION_MORE_DUNGENOS] = "< "..L["More Dungeons"]
	ns.OldMapList[OPTION_THIS_SEASON] = "> "..ARENA_THIS_SEASON

	for i = 1, 255 do
		local name = C_ChallengeMode.GetAffixInfo(i)
		if name then
			ns.AffixList[i] = name
		end
	end

	ns.AffixList[0] = NONE

	self:BuildOptions()
	self:UnregisterEvent(event)
end

function Option:BuildOptions()
	ns.Options.args["keystone"] = {
		order = 1,
		name = L["Mythic Keystone"],
		type = "group",
		args = {
			angryKeystone = {
				name = L["Fake AngryKeystones"],
				desc = L["It will replace AngryKeystones and send keystone info to your party automatically."],
				order = 1,
				type = "toggle",
				width = "double"
			},
			description = {
				name = "",
				order = 2,
				type = "description"
			},
			keystoneItemID = {
				name = L["Keystone Type"],
				order = 3,
				type = "select",
				values = ns.KeystoneItemIDs,
				width = "double"
			},
			mapId = {
				name = DUNGEONS,
				order = 4,
				type = "select",
				values = function()
					return Addon.db["currentExpansion"] and ns.MapList or ns.OldMapList
				end,
				set = function(_, val)
					if val == OPTION_THIS_SEASON then
						Addon.db["currentExpansion"] = true
						Addon.db["mapId"] = ns.MapIDs[1]
					elseif val == OPTION_MORE_DUNGENOS then
						Addon.db["currentExpansion"] = false
						Addon.db["mapId"] = ns.OldMapIDs[1]
					else
						Addon.db["mapId"] = val
					end
				end,
				width = "double"
			},
			mythicLevel = {
				name = L["Level"],
				order = 5,
				type = "range",
				min = 2,
				max = (2^31-1),
				softMin = 2,
				softMax = 35,
				step = 1,
				width = "double"
			},
			print = {
				name = L["Print"],
				desc = L["Print keystone link and send keystone info."],
				order = 20,
				type = "execute",
				func = function()
					Addon:PrintKeystone()
					Addon:SendKeystoneMsg()
					Addon:SendLibORKeystoneMsg(ns.CONST_COMM_CHANNEL["PARTY"])
					Addon:SendLibORKeystoneMsg(ns.CONST_COMM_CHANNEL["GUILD"])
				end
			},
			reset = {
				name = RESET,
				desc = L["Reset to current affixes"],
				order = 21,
				type = "execute",
				func = function()
					Addon:LoadCurrentAffixes()
				end
			}
		}
	}

	for i = 1, ns.NUM_AFFIXES do
		ns.Options.args["keystone"].args["affixId"..i] = {
			name = L["Affix"].." "..i,
			order = 5 + i,
			type = "select",
			values = ns.AffixList
		}
	end

	if ns.NUM_AFFIXES % 2 ~= 0 then
		ns.Options.args["keystone"].args.space = {
			name = "",
			order = 6 + ns.NUM_AFFIXES,
			type = "description",
		}
	end
end