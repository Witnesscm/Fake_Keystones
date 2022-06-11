local ADDON, ns = ...
local Addon = ns.Addon
local L = ns.L
local Challenges = Addon:NewModule("Challenges", "AceEvent-3.0","AceHook-3.0")
local Option = Addon:GetModule("Option")

local challenges_options = {
	order = 2,
	name = L["Challenges Frame"],
	type = "group",
	args = {
		challengesFrame = {
			name = L["Modify Challenges Frame"],
			order = 1,
			type = "toggle",
			set = function(_, val)
				Addon.db["challengesFrame"] = val
				if Challenges.ChallengesUILoaded then
					ChallengesFrame_Update(ChallengesFrame)
				end
			end,
			width = "double",
		},
		description1 = {
			name = "",
			order = 2,
			type = "description",
		},
		weeklyLevel = {
			name = L["Best M+ Level"],
			order = 3,
			type = "range",
			min = 2,
			max = 35,
			step = 1,
			width = "double",
			set = function(info, value)
				Option:Set(info[#info], value)
				Challenges:ChallengesFrame_Update()
			end,
		},
		description2 = {
			name = "\n"..L["Dungeons :"],
			order = 4,
			type = "description",
		}
	}
}

function Challenges:Get(key)
	return Addon.db["dungeons"][key]
end

function Challenges:Set(key, value)
	Addon.db["dungeons"][key] = value
end

function Challenges:BuildOptions()
	local order = 10

	for _, id in ipairs(ns.MapIDs) do
		local map = tostring(id)
		Addon.db["dungeons"][map] = Addon.db["dungeons"][map] or 20

		challenges_options.args[map] = {
			name = ns.MapList[id],
			order = order,
			type = "range",
			min = 2,
			max = 35,
			step = 1,
			get = function(info) return Challenges:Get(info[#info]) end,
			set = function(info, value)
				Challenges:Set(info[#info], value)
				Challenges:ChallengesFrame_Update()
			end,
		}

		order = order + 1

		local score = map.."score"
		Addon.db["dungeons"][score] = Addon.db["dungeons"][score] or 300

		challenges_options.args[score] = {
			name = L["Score"],
			order = order,
			type = "range",
			min = 0,
			max = 500,
			step = 1,
			get = function(info) return Challenges:Get(info[#info]) end,
			set = function(info, value)
				Challenges:Set(info[#info], value)
				Challenges:ChallengesFrame_Update()
			end,
		}

		order = order + 1
	end

	ns.Options.args["challenges"] = challenges_options
end

function Challenges:OnEnable()
	self:RegisterEvent("ADDON_LOADED")
	self:SecureHook(Option, "BuildOptions")
end

function Challenges:ADDON_LOADED(event, addon)
	if addon == "Blizzard_ChallengesUI" then
		self.ChallengesUILoaded = true
		self:SecureHook("ChallengesFrame_Update", "ChallengesFrame_Update")
		self:UnregisterEvent(event)
	end
end

local function updateCurrentText(self)
	if self.setting or not Addon.db["challengesFrame"] then return end

	local locale = _G.AngryKeystones.Modules.Locale
	local keystoneString = locale and locale:Get("currentKeystoneText")
	local mapName = C_ChallengeMode.GetMapUIInfo(Addon.db["mapId"])
	local keystoneName = mapName and string.format("%s (%d)", mapName, Addon.db["mythicLevel"])

	if keystoneName and keystoneString then
		self.setting = true
		self:SetText(string.format(keystoneString, keystoneName))
		self.setting = nil
	end
end

local function showObject(self)
	if not Addon.db["challengesFrame"] then return end
	self:Show()
end

local function updateGuildName(self)
	if self.setting or not Addon.db["challengesFrame"] then return end

	local name = UnitName("player")
	local _, classFilename = UnitClass("player")
	local classColorStr = RAID_CLASS_COLORS[classFilename].colorStr

	self.setting = true
	self:SetText(format(CHALLENGE_MODE_GUILD_BEST_LINE_YOU, classColorStr, name))
	self.setting = nil
end

local function updateGuildLevel(self)
	if self.setting or not Addon.db["challengesFrame"] then return end

	local level = Addon.db["weeklyLevel"]

	self.setting = true
	self:SetText(level)
	self.setting = nil
end

local guildBest

function Challenges:ChallengesFrame_Update()
	if not self.ChallengesUILoaded then return end

	if not Addon.db["challengesFrame"] then
		if guildBest then
			for i = 1, #guildBest.entries do
				guildBest.entries[i]:Show()
			end
		end
		return
	end

	local sortedMaps = {}
	for i = 1, #ns.MapIDs do
		local id = ns.MapIDs[i]
		local map = tostring(id)
		local level = Addon.db["dungeons"][map]
		local score = Addon.db["dungeons"][map.."score"]

		tinsert(sortedMaps, { id = id, level = level, dungeonScore = score})
	end

	table.sort(sortedMaps, 
	function(a, b)
		return a.dungeonScore > b.dungeonScore
	end)

	local totalScore = 0

	for i = 1, #sortedMaps do
		local frame = ChallengesFrame.DungeonIcons[i]
		frame:SetUp(sortedMaps[i], i == 1)

		local score = sortedMaps[i].dungeonScore
		totalScore = totalScore + score

		local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(score)
		frame.HighestLevel:SetTextColor(color.r, color.g, color.b)
	end

	local _, _, _, _, backgroundTexture = C_ChallengeMode.GetMapUIInfo(sortedMaps[1].id)
	if (backgroundTexture ~= 0) then
		ChallengesFrame.Background:SetTexture(backgroundTexture)
	end

	ChallengesFrame.WeeklyInfo:SetUp(true, sortedMaps[1])

	local activeChest = ChallengesFrame.WeeklyInfo.Child.WeeklyChest
	activeChest.Icon:SetAtlas("mythicplus-greatvault-complete", TextureKitConstants.UseAtlasSize)
	activeChest.Highlight:SetAtlas("mythicplus-greatvault-complete", TextureKitConstants.UseAtlasSize)
	activeChest.RunStatus:SetText(MYTHIC_PLUS_COMPLETE_MYTHIC_DUNGEONS)
	activeChest.AnimTexture:Hide()
	activeChest:Show()

	local color = C_ChallengeMode.GetDungeonScoreRarityColor(totalScore)
	if(color) then
		ChallengesFrame.WeeklyInfo.Child.DungeonScoreInfo.Score:SetVertexColor(color.r, color.g, color.b)
	end
	ChallengesFrame.WeeklyInfo.Child.DungeonScoreInfo.Score:SetText(totalScore)
	ChallengesFrame.WeeklyInfo.Child.DungeonScoreInfo:SetShown(true)

	ChallengesFrame.WeeklyInfo.Child.ThisWeekLabel:Show()
	ChallengesFrame.WeeklyInfo.Child.Description:Hide()

	if IsAddOnLoaded("AngryKeystones") then
		local mod = _G.AngryKeystones.Modules.Schedule
		mod.KeystoneText:Show()
		updateCurrentText(mod.KeystoneText)

		if not self.AngryKeystonesHooked then
			hooksecurefunc(mod.KeystoneText, "Hide", showObject)
			hooksecurefunc(mod.KeystoneText, "SetText", updateCurrentText)
			self.AngryKeystonesHooked = true
		end
	end

	if guildBest then
		for i = 1, #guildBest.entries do
			local entry = guildBest.entries[i]
			if i == 1 then
				entry:Show()
				entry.CharacterName:SetText("")
				entry.Level:SetText("")
			else
				entry:Hide()
			end
		end

		guildBest:Show()
	else
		for _, child in pairs {ChallengesFrame:GetChildren()} do
			if child.entries and child.entries[1] and child.entries[1].CharacterName then
				for i = 1, #child.entries do
					local entry = child.entries[i]
					if i == 1 then
						hooksecurefunc(entry.CharacterName, "SetText", updateGuildName)
						hooksecurefunc(entry.Level, "SetText", updateGuildLevel)
						entry:Show()
						entry.CharacterName:SetText("")
						entry.Level:SetText("")
					else
						entry:Hide()
					end
				end

				guildBest = child
				break
			end
		end
	end
end