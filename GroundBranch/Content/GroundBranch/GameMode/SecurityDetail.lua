--[[
	Security Detail
	PvE Ground Branch game mode by Bob/AT

	Parts of the code are based on 'BreakOut' by Jakub 'eelSkillz' Baranowski.
	We are not using OOP-style inheritance from BreakOut since the game modes are to distinct.

	See docs/mission-editing.md.
--]]

--[[
Copyright © 2022 "Bob/AT" <https://github.com/Bob-AT>
Copyright © 2021 Jakub Baranowski <https://github.com/JakBaranowski>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

local AvoidFatality = require('Objectives.AvoidFatality')
local Logger = require('Common.Logger')
local NoSoftFail = require('Objectives.NoSoftFail')
local ObjectiveExfiltrate = require('Objectives.Exfiltrate')
local SpawnsCommon = require('Spawns.Common')
local SpawnsGroups = require('Spawns.Groups')
local Tables = require('Common.Tables')
local Teams = require('Players.Teams')

local log = Logger.new('SecDet')
log:SetLogLevel('DEBUG')

--#region Properties

local Mode = {
	UseReadyRoom = true,
	UseRounds = true,
	StringTables = {'SecurityDetail'},
	GameModeAuthor = "'(c) Bob/A <https://gbgmc.github.io/>\n[Solo/Co-Op] Protect the principal.",
	GameModeType = "PVE",
	Config = {
		-- placeholder
		SoftFailEnabled = true,
		-- placeholder
		CollateralDamageThreshold = 3,
		-- Whether we automatically select the VIP
		AutoSelectVip = true
	},
	Settings = {
		Scenario = {
			Min = 0,
			Max = 2,
			Value = 0,
			AdvancedSetting = false,
		},
		AvailableForces = {
			Min = 0,
			Max = 2,
			Value = 1,
			AdvancedSetting = false
		},
		OpForPreset = {
			Min = 0,
			Max = 4,
			Value = 2,
			AdvancedSetting = false,
		},
		Difficulty = {
			Min = 0,
			Max = 4,
			Value = 2,
			AdvancedSetting = false,
		},
		VIP = {
			Min = 0,
			Max = 1,
			Value = 1,
			AdvancedSetting = true,
		},
		RoundTime = {
			Min = 5,
			Max = 60,
			Value = 60,
			AdvancedSetting = false,
		}
	},
	PlayerScoreTypes = {
		KillStandard = {
			Score = 100,
			OneOff = false,
			Description = 'Eliminated threat'
		},
		KillHvt = {
			Score = 250,
			OneOff = false,
			Description = 'Eliminated HVT'
		},
		ConfirmHvt = {
			Score = 750,
			OneOff = false,
			Description = 'Confirmed HVT elimination'
		},
		Survived = {
			Score = 200,
			OneOff = false,
			Description = 'Made it out alive'
		},
		TeamKill = {
			Score = -250,
			OneOff = false,
			Description = 'Killed a teammate'
		},
		Accident = {
			Score = -50,
			OneOff = false,
			Description = 'Killed oneself'
		}
	},
	TeamScoreTypes = {
		KillHvt = {
			Score = 250,
			OneOff = false,
			Description = 'Eliminated HVT'
		},
		ConfirmHvt = {
			Score = 750,
			OneOff = false,
			Description = 'Confirmed HVT elimination'
		},
		Respawn = {
			Score = -1,
			OneOff = false,
			Description = 'Respawned'
		}
	},
	PlayerTeams = {
		BluFor = {
			TeamId = 1,
			--Loadout = 'NoTeamCamouflage',
			Loadout = 'NoTeam',
			Script = nil
		},
	},
	AiTeams = {
		OpFor = {
			Tag = 'OpFor',
			CalculatedAiCount = 0,
			Spawns = nil
		},
	},
	Objectives = {
		ProtectVIP = nil,
		Exfiltrate = nil,
	},
	Timers = {
		-- Delays
		CheckBluForCount = {
			Name = 'CheckBluForCount',
			TimeStep = 1.0,
		},
		CheckReadyUp = {
			Name = 'CheckReadyUp',
			TimeStep = 0.25,
		},
		CheckReadyDown = {
			Name = 'CheckReadyDown',
			TimeStep = 0.1,
		},
		SpawnOpFor = {
			Name = 'SpawnOpFor',
			TimeStep = 0.5,
		},
	},
	InsertionPoints = {
		All = {},
		VipTravelScenario = {},
		VipExfilScenario = {},
		AnyVipScenario = {},
		NonVip = {}
	},
	NumberOfLocations = 0,
	SelectedLocationNumber = 0,
	ExfilTagToExfils = {},
	ActiveVipInsertionPoint = nil,
	VipPlayerName = false,
	-- Whether we have non-combatants in the AO
	IsSemiPermissive = false,
	-- Ref. to logger
	Logger = log,
	-- Fallback locations
	FallbackInsertionPoint = nil,
}

--#endregion

--#region Helpers
local function ArrayItemsWithPrefix(array, prefix)
	local len = #prefix
	local result = {}
	for _, item in ipairs(array) do
		if string.sub(tostring(item), 1, len) == prefix then
			table.insert(result, item)
		end
	end
	return result
end

local function DecorateUserData(userdata)
	local mt = getmetatable(userdata) or {}
	mt.__tostring = function(obj)
		return actor.GetName(obj)
	end
end
--#endregion

--#region Preparation

function Mode:PreInit()
	log:Debug('PreInit')

	if self.IsSemiPermissive then
		self.Objectives.AvoidFatality = AvoidFatality.new('NoCollateralDamage')
	else
		self.Objectives.AvoidFatality = AvoidFatality.new(nil)
	end
	self.Objectives.NoSoftFail = NoSoftFail.new()

	self.PlayerTeams.BluFor.Script = Teams:Create(
		1,
		false,
		self.PlayerScoreTypes,
		self.TeamScoreTypes
	)
	-- Gathers all OpFor spawn points by groups
	self.AiTeams.OpFor.Spawns = SpawnsGroups:Create()
	-- Gathers all extraction points placed in the mission
	self.Objectives.Exfiltrate = ObjectiveExfiltrate:Create(
		self,
		self.OnExfiltrated,
		self.PlayerTeams.BluFor.Script,
		5.0,
		1.0
	)
	self.Objectives.ProtectVIP = AvoidFatality.new('ProtectVIP')

	for _, ip in ipairs(gameplaystatics.GetAllActorsOfClass('GroundBranch.GBInsertionPoint')) do
		DecorateUserData(ip)

		if not actor.HasTag(ip, 'Asset') then
			table.insert(self.InsertionPoints.All, ip)

			if actor.HasTag(ip, 'VIP-Exfil') then
				table.insert(self.InsertionPoints.VipExfilScenario, ip)
			elseif actor.HasTag(ip, 'VIP-Travel') then
				table.insert(self.InsertionPoints.VipTravelScenario, ip)
			else
				table.insert(self.InsertionPoints.NonVip, ip)
			end
		else
			-- Disable Asset point (used by `Asset extraction` game mode)
			actor.SetActive(ip, false)
		end
	end


	local tostring_comp = function(a, b)
		return tostring(a) < tostring(b)
	end

	table.sort(self.InsertionPoints.VipExfilScenario, tostring_comp)
	for _, ip in ipairs(self.InsertionPoints.VipExfilScenario) do
		table.insert(self.InsertionPoints.AnyVipScenario, ip)
	end

	table.sort(self.InsertionPoints.VipTravelScenario, tostring_comp)
	for _, ip in ipairs(self.InsertionPoints.VipTravelScenario) do
		table.insert(self.InsertionPoints.AnyVipScenario, ip)
	end

	self.NumberOfLocations = #self.InsertionPoints.AnyVipScenario
	self.SelectedLocationNumber = 0

	self.ExfilTagToExfils = {}

	for idx, ip in ipairs(self.Objectives.Exfiltrate.Points.All) do
		local tags = ArrayItemsWithPrefix(actor.GetTags(ip), 'Exfil-')
		for _, tag in ipairs(tags) do
			if not self.ExfilTagToExfils[tag] then
				self.ExfilTagToExfils[tag] = {}
			end
			local item = {Index = idx, Actor = ip}
			table.insert(self.ExfilTagToExfils[tag], item)
		end
	end

	log:Debug('ExfilTags', self.ExfilTagToExfils)

	self.ExfilRecords = {}
	for idx, ep in ipairs(self.Objectives.Exfiltrate.Points.All) do
		DecorateUserData(ep)
		local record = { Index = idx, Actor = ep, Name=actor.GetName(ep) , TagSet = {}}
		for _, tag in ipairs(ArrayItemsWithPrefix(actor.GetTags(ep), 'Exfil-')) do
			record.TagSet[tag] = true
		end
		table.insert(self.ExfilRecords, record)
	end
end

function Mode:PostInit()
	gamemode.AddGameObjective(self.PlayerTeams.BluFor.TeamId, 'ProtectVIP', 1)
	if self.IsSemiPermissive then
		gamemode.AddGameObjective(self.PlayerTeams.BluFor.TeamId, 'NoCollateralDamage', 1)
	end
	gamemode.AddGameObjective(self.PlayerTeams.BluFor.TeamId, 'ExfiltrateBluFor', 1)

	local laptops = gameplaystatics.GetAllActorsOfClass('/Game/GroundBranch/Props/Electronics/MilitaryLaptop/BP_Laptop_Usable.BP_Laptop_Usable_C')
	for _, laptop in ipairs(laptops) do
		actor.SetActive(laptop, false)
	end
end

function Mode:OnProcessCommand(command, param)
	print('OnProcessCommand("' .. command .. '", "' .. param .. '")')

	if not (command == 'reloadmissionscript' or command == 'mode') then
		return
	end
	param = tostring(param)
	local message = {}
	local use_main = false
	local duration = 6

	if param == 'help' then
		use_main = true
		duration = 60
		table.insert(message, '==== admin ' .. command .. ' loc=NUMBER ====')
		table.insert(message, 'Select a location. 0=Random, Maximum=' .. self.NumberOfLocations)
		table.insert(message, '')
		table.insert(message, '==== admin ' .. command .. ' rand [obj|exfil] ====')
		table.insert(message, 'Randomize objectives|exfil')
		table.insert(message, '')
		table.insert(message, '==== admin ' .. command .. ' clear ====')
		table.insert(message, 'Clears the screen')
		table.insert(message, '')
		table.insert(message, '==== NOTE ====')
		table.insert(message, 'NOTE: In single player use `DebugGameCommand` instead of `admin`')
	elseif param == 'rand' or param == 'rand obj' then
		table.insert(message, 'Randomizing objectives')
		self:RandomizeObjectives()
	elseif param == 'rand' or param == 'rand exfil' then
		table.insert(message, 'Randomizing exfil')
		self:RandomizeExfil()
	elseif param == 'clear' then
		duration = 0.001
	elseif string.match(param,'^loc') then
		local m = tonumber(string.match(param, 'loc=(%d+)')) or 0
		if m > 0 and m <= self.NumberOfLocations then
			table.insert(message,'Admin selected location ' .. tostring(m) .. '.')
			self.SelectedLocationNumber = tonumber(m)
		else
			table.insert(message,'Admin selected invalid location. Using random one.')
			self.SelectedLocationNumber = 0
		end
		self:RandomizeObjectives()
	else
		table.insert(message, 'Invalid parameter: ' .. param)
		table.insert(message,'Use admin ' .. command .. ' help')
	end

	gamemode.BroadcastGameMessage(table.concat(message, '\n'), 'Engine', -duration)
	gamemode.BroadcastGameMessage(table.concat(message, '\n'), 'Upper', -duration)
end

function Mode:Validate(ensure)
	for _, ip in ipairs(self.InsertionPoints.AnyVipScenario) do
		local points = {}
		for _, record in ipairs(self:GetPossibleExfilPoints(ip)) do
			table.insert(points, record.Name)
		end
		ensure('VIP ' .. tostring(ip) .. ' has escape route', #points > 0, points)
	end
end

function Mode:GetPossibleExfilPoints(InsertionPoint)
	local tags = ArrayItemsWithPrefix(actor.GetTags(InsertionPoint), 'Exfil-')
	local points = {}

	for _, exfilRecord in ipairs(self.ExfilRecords) do
		for _, tag in ipairs(tags) do
			if exfilRecord.TagSet[tag] then
				table.insert(points, exfilRecord)
				break
			end
		end
	end

	return points
end

--#endregion

--#region Common

function Mode:EnsureVipPlayerPresent(isLate)
	log:Debug("EnsureVipPlayerPresent", self.VipPlayerName)
	if self.VipPlayerName then
		return
	end
	if not self.Config.AutoSelectVip then
		return
	end
	self.VipPlayerName = "Pending..."

	local vipPlayer = self:GetRandomVipPlayer()
	local message = 'PickedRandom'
	if isLate then
		message = 'PickedRandomLate'
	end
	log:Debug("Message", message)
	gamemode.BroadcastGameMessage(message, 'Engine', 11.5)
	self.VipPlayerName = player.GetName(vipPlayer)
	player.SetInsertionPoint(vipPlayer, self.ActiveVipInsertionPoint)
end

function Mode:GetRandomVipPlayer()
	local allPlayers = gamemode.GetPlayerList(self.PlayerTeams.BluFor.TeamId, true)
	local playersInReadyRoom = {}
	local playersWithoutInsertionPoint = {}

	for _, aPlayer in ipairs(allPlayers) do
		local status = player.GetReadyStatus(aPlayer)
		if status == 'WaitingToReadyUp' then
			table.insert(playersInReadyRoom, aPlayer)
			table.insert(playersWithoutInsertionPoint, aPlayer)
		elseif status == 'DeclaredReady' then
			table.insert(playersInReadyRoom, aPlayer)
		end
	end

	local vipPlayer
	if #playersWithoutInsertionPoint > 0 then
		vipPlayer = Tables.RandomElement(playersWithoutInsertionPoint)
	elseif #playersInReadyRoom > 0 then
		vipPlayer = Tables.RandomElement(playersInReadyRoom)
	else
		return
	end
	return vipPlayer
end

function Mode:OnRoundStageSet(RoundStage)
	log:Debug('Started round stage', RoundStage)

	timer.ClearAll()
	if RoundStage == 'PostRoundWait' or RoundStage == 'TimeLimitReached' then
		self.VipPlayerName = false
	elseif RoundStage == 'WaitingForReady' then
		self:PreRoundCleanUp()
		self:RandomizeObjectives()
	elseif RoundStage == 'PreRoundWait' then
		self:EnsureVipPlayerPresent(true)
		gamemode.SetDefaultRoundStageTime('InProgress', self.Settings.RoundTime.Value)

		self:SetUpOpForStandardSpawns()
		self:SpawnOpFor()

		local message = "NoVipMoveToExfil"
		if self.VipPlayerName then
			message = gamemode.FormatString({
				FormatString = "ProtectVIP",
				Name = self.VipPlayerName
			})
		end

		log:Debug("Message", message)
		gamemode.BroadcastGameMessage(message, 'Upper', 11.5)
	elseif RoundStage == 'InProgress' then
		self.Objectives.Exfiltrate:SelectedPointSetActive(true)
		self.PlayerTeams.BluFor.Script:RoundStart(
			10000,
			false,
			false,
			true,
			false
		)
		-- check if anybody survived the PreRoundWait
		timer.Set(
				self.Timers.CheckBluForCount.Name,
				self,
				self.CheckBluForCountTimer,
				self.Timers.CheckBluForCount.TimeStep,
				false
		)
	end
end

function Mode:OnRoundStageTimeElapsed(RoundStage)
	if RoundStage == 'ReadyCountdown' then
		self:EnsureVipPlayerPresent()
	end
	return false
end

function Mode:OnCharacterDied(Character, CharacterController, KillerController)
	if
		gamemode.GetRoundStage() == 'PreRoundWait' or
		gamemode.GetRoundStage() == 'InProgress'
	then
		if CharacterController ~= nil then
			local killedTeam = actor.GetTeamId(CharacterController)
			local killerTeam
			if KillerController ~= nil then
				killerTeam = actor.GetTeamId(KillerController)
			end
			if actor.HasTag(CharacterController, self.AiTeams.OpFor.Tag) then
				if killedTeam == 10 and killerTeam == self.PlayerTeams.BluFor.TeamId then
					self.Objectives.AvoidFatality:ReportFatality()
					self.PlayerTeams.BluFor.Script:AwardPlayerScore(KillerController, 'CollateralDamage')
					self.PlayerTeams.BluFor.Script:AwardTeamScore('CollateralDamage')

					local message = gamemode.FormatString({
						FormatString = "CollateralDamageBy",
						Name = player.GetName(KillerController)
					})
					self.PlayerTeams.BluFor.Script:DisplayMessageToAllPlayers(message, 'Engine', 5.0, 'Always')

					if self.Objectives.AvoidFatality:GetFatalityCount() >= self.Config.CollateralDamageThreshold then
						self.Objectives.NoSoftFail:Fail()
						if self.Config.SoftFailEnabled then
							-- Fail soft
							self.PlayerTeams.BluFor.Script:DisplayMessageToAlivePlayers('SoftFail', 'Upper', 10.0, 'Always')
						else
							-- Fail hard
							self:UpdateCompletedObjectives()
							gamemode.AddGameStat('Summary=SoftFail')
							gamemode.AddGameStat('Result=None')
							gamemode.SetRoundStage('PostRoundWait')
						end
					end
				elseif killerTeam == self.PlayerTeams.BluFor.TeamId then
					self.PlayerTeams.BluFor.Script:AwardPlayerScore(KillerController, 'KillStandard')
				end
			else
				local ps = player.GetPlayerState ( CharacterController )
				local playerName = player.GetName(ps)
				log:Debug("Player dead", playerName)

				if CharacterController == KillerController then
					self.PlayerTeams.BluFor.Script:AwardPlayerScore(CharacterController, 'Accident')
				elseif killerTeam == killedTeam then
					self.PlayerTeams.BluFor.Script:AwardPlayerScore(KillerController, 'TeamKill')
				end

				self.PlayerTeams.BluFor.Script:PlayerDied(CharacterController, Character)

				if playerName == self.VipPlayerName then
					if killerTeam then
						log:Info('VIP killed', self.VipPlayerName)
						self.Objectives.ProtectVIP:ReportFatality()
					elseif gamemode.GetRoundStage() == 'InProgress' and (not self.PlayerTeams.BluFor.Script:IsWipedOut()) then
						log:Info("Doing nothing", killerTeam)
						-- do nothing
					end
				end

				if self.PlayerTeams.BluFor.Script:IsWipedOut() then
					self:CheckBluForCountTimer()
				else
					timer.Set(
							self.Timers.CheckBluForCount.Name,
							self,
							self.CheckBluForCountTimer,
							self.Timers.CheckBluForCount.TimeStep,
							false
					)
				end
			end
		end
	end
end

--#endregion

--#region Player Status

function Mode:PlayerInsertionPointChanged(PlayerState, ip)
	if gamemode.GetRoundStage() == 'PreRoundWait' then
		return
	end

	log:Debug("PlayerInsertionPointChanged", gamemode.GetRoundStage())

	local playerName = player.GetName(PlayerState)
	if playerName == self.VipPlayerName then
		self.VipPlayerName = false
	end

	if ip == nil then
		-- Player unchecked insertion point.
		timer.Set(
			self.Timers.CheckReadyDown.Name,
			self,
			self.CheckReadyDownTimer,
			self.Timers.CheckReadyDown.TimeStep,
			false
		)
	else
		-- Player checked insertion point.
		if self:IsVipInsertionPoint(ip) then
			log:Info('VIP insertion point selected', playerName)
			self.VipPlayerName = playerName
		end

		if false then
			gamemode.SetRoundStage('ReadyCountdown')
		else
			timer.Set(
					self.Timers.CheckReadyUp.Name,
					self,
					self.CheckReadyUpTimer,
					self.Timers.CheckReadyUp.TimeStep,
					false
			)
		end
	end
end

function Mode:IsVipInsertionPoint(ip)
	return actor.HasTag(ip, 'VIP-Travel') or actor.HasTag(ip, 'VIP-Exfil')
end

function Mode:PlayerReadyStatusChanged(PlayerState, ReadyStatus)
	log:Debug('PlayerReadyStatusChanged', ReadyStatus)

	if ReadyStatus ~= 'DeclaredReady' then
		-- Player declared ready.
		timer.Set(
				self.Timers.CheckReadyDown.Name,
				self,
				self.CheckReadyDownTimer,
				self.Timers.CheckReadyDown.TimeStep,
				false
		)
	elseif gamemode.GetRoundStage() == 'PreRoundWait' then
		self:EnsureVipPlayerPresent(true)

		local playerName = player.GetName(PlayerState)
		log:Debug("Prep Latecomer", playerName)

		local insertionPoint = self.FallbackInsertionPoint

		-- Don't use fallback for late-coming VIP
		if playerName == self.VipPlayerName then
			insertionPoint = self.ActiveVipInsertionPoint
		end

		player.SetInsertionPoint(PlayerState, insertionPoint)
		if gamemode.PrepLatecomer(PlayerState) then
			-- Assign InsertionPoint again in case `PrepLatecomer`
			-- modified it.
			player.SetInsertionPoint(PlayerState, insertionPoint)

			gamemode.EnterPlayArea(PlayerState)
		end
	end
end

function Mode:CheckReadyUpTimer()
	if
		gamemode.GetRoundStage() == 'WaitingForReady' or
		gamemode.GetRoundStage() == 'ReadyCountdown'
	then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(true)
		local BluForReady = ReadyPlayerTeamCounts[self.PlayerTeams.BluFor.TeamId]
		if BluForReady >= gamemode.GetPlayerCount(true) then
			self:EnsureVipPlayerPresent()
			gamemode.SetRoundStage('PreRoundWait')
		elseif BluForReady > 0 then
			gamemode.SetRoundStage('ReadyCountdown')
		end
	end
end

function Mode:CheckReadyDownTimer()
	if gamemode.GetRoundStage() == 'ReadyCountdown' then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(true)
		if ReadyPlayerTeamCounts[self.PlayerTeams.BluFor.TeamId] < 1 then
			gamemode.SetRoundStage('WaitingForReady')
		end
	end
end

function Mode:ShouldCheckForTeamKills()
	return (gamemode.GetRoundStage() == 'InProgress')
end

function Mode:PlayerCanEnterPlayArea(PlayerState)
	if
		gamemode.GetRoundStage() == 'InProgress' or
		player.GetInsertionPoint(PlayerState) ~= nil
	then
		return true
	end
	return false
end

function Mode:LogOut(Exiting)
	print('Player left the game ')
	print(Exiting)
	if
		gamemode.GetRoundStage() == 'PreRoundWait' or
		gamemode.GetRoundStage() == 'InProgress'
	then
		if player.GetName(Exiting) == self.VipPlayerName then
			gamemode.BroadcastGameMessage('VIP left. Move to Exfil.', 'Upper', 15)
		end

		timer.Set(
			self.Timers.CheckBluForCount.Name,
			self,
			self.CheckBluForCountTimer,
			self.Timers.CheckBluForCount.TimeStep,
			false
		)
	end
end

--#endregion

--#region Spawns

function Mode:SetUpOpForStandardSpawns()
	--print('Setting up AI spawns by groups')
	local maxAiCount = math.min(
			self.AiTeams.OpFor.Spawns:GetTotalSpawnPointsCount(),
			ai.GetMaxCount()
	)
	self.AiTeams.OpFor.CalculatedAiCount = SpawnsCommon.GetAiCountWithDeviationPercent(
			5,
			maxAiCount,
			gamemode.GetPlayerCount(true),
			5,
			self.Settings.OpForPreset.Value,
			5,
			0.1
	)
	local missingAiCount = self.AiTeams.OpFor.CalculatedAiCount
	--print('Adding random group spawns')
	while missingAiCount > 0 do
		if self.AiTeams.OpFor.Spawns:GetRemainingGroupsCount() <= 0 then
			break
		end
		local aiCountPerGroup = SpawnsCommon.GetAiCountWithDeviationNumber(
				2,
				10,
				gamemode.GetPlayerCount(true),
				0.5,
				self.Settings.OpForPreset.Value,
				1,
				1
		)
		if aiCountPerGroup > missingAiCount	then
			--print('Remaining AI count is not enough to fill group')
			break
		end
		self.AiTeams.OpFor.Spawns:AddSpawnsFromRandomGroup(aiCountPerGroup)
		missingAiCount = self.AiTeams.OpFor.CalculatedAiCount -
				self.AiTeams.OpFor.Spawns:GetSelectedSpawnPointsCount()
	end
	--print('Adding random spawns from reserve')
	self.AiTeams.OpFor.Spawns:AddRandomSpawnsFromReserve()
end

function Mode:SpawnOpFor()
	timer.Set(
		self.Timers.SpawnOpFor.Name,
		self,
		self.SpawnStandardOpForTimer,
		self.Timers.SpawnOpFor.TimeStep,
		false
	)
end

function Mode:SpawnStandardOpForTimer()
	self.AiTeams.OpFor.Spawns:Spawn(3.5, self.AiTeams.OpFor.CalculatedAiCount, self.AiTeams.OpFor.Tag)
end

--#endregion

--#region Objective: Extraction

function Mode:OnGameTriggerBeginOverlap(GameTrigger, Player)
	--print('OnGameTriggerBeginOverlap')
	if self.Objectives.Exfiltrate:CheckTriggerAndPlayer(GameTrigger, Player) then
		self.Objectives.Exfiltrate:PlayerEnteredExfiltration(true)
	end
end

function Mode:OnGameTriggerEndOverlap(GameTrigger, Player)
	--print('OnGameTriggerEndOverlap')
	if self.Objectives.Exfiltrate:CheckTriggerAndPlayer(GameTrigger, Player) then
		self.Objectives.Exfiltrate:PlayerLeftExfiltration()
	end
end

function Mode:OnExfiltrated()
	if gamemode.GetRoundStage() ~= 'InProgress' then
		return
	end
	-- Award surviving players
	local alivePlayers = self.PlayerTeams.BluFor.Script:GetAlivePlayers()
	for _, alivePlayer in ipairs(alivePlayers) do
		self.PlayerTeams.BluFor.Script:AwardPlayerScore(alivePlayer, 'Survived')
	end
	-- Prepare summary
	self:UpdateCompletedObjectives()
	gamemode.AddGameStat('Result=Team1')
	gamemode.AddGameStat('Summary=VIPSurvived')
	gamemode.SetRoundStage('PostRoundWait')
end

--#endregion

--#region Fail Condition

function Mode:CheckBluForCountTimer()
	if gamemode.GetRoundStage() ~= 'InProgress' then
		return
	end

	if not self.Objectives.ProtectVIP:IsOK() then
		self:UpdateCompletedObjectives()
		gamemode.AddGameStat('Result=None')
		gamemode.AddGameStat('Summary=VipEliminated')
		gamemode.SetRoundStage('PostRoundWait')
	elseif self.PlayerTeams.BluFor.Script:IsWipedOut() then
		self:UpdateCompletedObjectives()
		gamemode.AddGameStat('Result=None')
		gamemode.AddGameStat('Summary=BluForEliminated')
		gamemode.SetRoundStage('PostRoundWait')
	end
end

--#endregion

--#region Helpers

function Mode:PreRoundCleanUp()
	ai.CleanUp(self.AiTeams.OpFor.Tag)

	gamemode.SetTeamAttitude(1, 10, 'Neutral')
	gamemode.SetTeamAttitude(10, 1, 'Neutral')
	gamemode.SetTeamAttitude(10, 100, 'Friendly')
	gamemode.SetTeamAttitude(100, 10, 'Friendly')

	for _, objective in pairs(self.Objectives) do
		objective:Reset()
	end
end

function Mode:OnMissionSettingsChanged(ChangedSettingsTable)
	for k, v in pairs(ChangedSettingsTable) do
		if v ~= nil then
			self:OnMissionSettingChanged(k, v)
		end
	end
end

function Mode:OnMissionSettingChanged(Setting, NewValue)
	-- print("OnMissionSettingChanged " .. Setting .. " -> " .. NewValue)
	if Setting == 'Scenario' then
		if self.Settings.Scenario.LastValue ~= NewValue then
			self:RandomizeObjectives()
		end
		self.Settings.Scenario.LastValue = NewValue
	elseif Setting == 'AvailableForces' then
		self:ActivateInsertionPoints()
	elseif Setting == 'VIP' then
		self.Config.AutoSelectVip = (self.Settings.VIP == 1)
	end
end

function Mode:GetPlayerTeamScript()
	return self.PlayerTeams.BluFor.Script
end

function Mode:RandomizeObjectives()
	log:Debug('RandomizeObjectives')

	local eligibleVipPoints = {}
	if self.SelectedLocationNumber ~= 0 then
		local ip = self.InsertionPoints.AnyVipScenario[self.SelectedLocationNumber]
		self.SelectedLocationNumber = 0 -- reset it for next round

		eligibleVipPoints = { ip }
		log:Debug('Selected insertion', ip)
	elseif self.Settings.Scenario.Value == 0 then
		eligibleVipPoints = self.InsertionPoints.AnyVipScenario
	elseif self.Settings.Scenario.Value == 1 then
		eligibleVipPoints = self.InsertionPoints.VipTravelScenario
	else -- 2
		eligibleVipPoints = self.InsertionPoints.VipExfilScenario
	end

	-- Pick a random VIP InsertionPoint
	self.ActiveVipInsertionPoint = Tables.RandomElement(eligibleVipPoints)
	self:RandomizeExfil()
	self:ActivateInsertionPoints()
end

function Mode:RandomizeExfil()
	local tags = actor.GetTags(self.ActiveVipInsertionPoint)

	-- Find possible exfil points
	local exfilTags = ArrayItemsWithPrefix(tags, 'Exfil-')
	-- Select one
	local exfilTag = Tables.RandomElement(exfilTags)

	-- Activate exfil
	local eligibleExfils = self.ExfilTagToExfils[exfilTag]
	
	local exfilActorAndIndex = Tables.RandomElement(eligibleExfils)
	log:Debug('Selected exfil', exfilActorAndIndex)
	self.Objectives.Exfiltrate:SelectPoint(true, exfilActorAndIndex.Index)
end

function Mode:ParseAvailableForces()
	local qrfEnabled = true
	local psdEnabled = true

	if self.Settings.AvailableForces.Value == 1 then
		qrfEnabled = false
	elseif self.Settings.AvailableForces.Value == 2 then
		psdEnabled = false
	end

	return qrfEnabled, psdEnabled
end

function Mode:ActivateInsertionPoints()
	local function isRestricted(ip)
		return actor.HasTag(ip, 'Restricted')
	end
	local function isHidden(ip)
		return actor.HasTag(ip, 'Hidden')
	end

	local qrfEnabled, psdEnabled = self:ParseAvailableForces()

	log:Debug('PSD', psdEnabled)
	log:Debug('QRF', qrfEnabled)

	-- Disable all InsertionPoint
	for _, ip in ipairs(self.InsertionPoints.All) do
		actor.SetActive(ip, false)
	end
	actor.SetActive(self.ActiveVipInsertionPoint, true)

	local selectedVipInsertionTags = actor.GetTags(self.ActiveVipInsertionPoint)
	local ipTags = ArrayItemsWithPrefix(selectedVipInsertionTags, 'IP-')

	local possibleFallbackPoints = {}
	local havePSDFallback = false

	-- Enable all linked InsertionPoints
	for _, insertionPoint in ipairs(self.InsertionPoints.NonVip) do
		--local isLinkedIP = false

		-- PSD insertion points
		for _, tag in ipairs(ipTags) do
			if actor.HasTag(insertionPoint, tag) then
				actor.SetActive(insertionPoint, psdEnabled)

				if psdEnabled and not isRestricted(insertionPoint)  then
					havePSDFallback = true
					table.insert(possibleFallbackPoints, 1, insertionPoint)
				end
			end
		end

		if not isHidden(insertionPoint) and not isRestricted(insertionPoint) then
			-- Enable QRF points
			if qrfEnabled then
				actor.SetActive(insertionPoint, true)
			end

			-- Even if we don't have qrfEnabled, we still might need
			-- an InsertionPoint in case all other active InsertionPoints
			-- are 'Restricted'
			table.insert(possibleFallbackPoints, insertionPoint)
		end
	end

	if #possibleFallbackPoints > 0 then
		if havePSDFallback then
			self.FallbackInsertionPoint = possibleFallbackPoints[1]
		else
			self.FallbackInsertionPoint = Tables.RandomElement(possibleFallbackPoints)
		end
		actor.SetActive(self.FallbackInsertionPoint, true)
		log:Debug('Select fallback', self.FallbackInsertionPoint)
	else
		log:Error('No fallback points found')
	end
end

function Mode:UpdateCompletedObjectives()
	local completedObjectives = {}

	for _, objective in pairs(self.Objectives) do
		for _, completed in ipairs(objective:GetCompletedObjectives()) do
			table.insert(completedObjectives, completed)
		end
	end

	if #completedObjectives > 0 then
		gamemode.AddGameStat(
				'CompleteObjectives=' .. table.concat(completedObjectives, ',')
		)
	end
end

--#endregion

function Mode:OnRandomiseObjectives()
	self:RandomizeObjectives()
end

function Mode:CanRandomiseObjectives()
	return true
end

return Mode
