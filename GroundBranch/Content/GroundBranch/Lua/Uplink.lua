local uplink = {
	UseReadyRoom = true,
	UseRounds = true,
	StringTables = { "Uplink" },
	PlayerTeams = {
		Blue = {
			TeamId = 1,
			Loadout = "Blue",
		},
		Red = {
			TeamId = 2,
			Loadout = "Red",
		},
	},
	Settings = {
		RoundTime = {
			Min = 5,
			Max = 30,
			Value = 10,
		},
		DefenderSetupTime = {
			Min = 10,
			Max = 120,
			Value = 30,
		},
		CaptureTime = {
			Min = 1,
			Max = 60,
			Value = 10,
		},
		AutoSwap = {
			Min = 0,
			Max = 1,
			Value = 1,
		},
	},
	DefenderInsertionPoints = {},
	RandomDefenderInsertionPoint = nil,
	AttackerInsertionPoints = {},
	GroupedLaptops = {},
	DefendingTeam = {},
	AttackingTeam = {},
	RandomLaptop = nil,
	SpawnProtectionVolumes = {},
	ShowAutoSwapMessage = false,
}

function uplink:PreInit()
	self.SpawnProtectionVolumes = gameplaystatics.GetAllActorsOfClass('GroundBranch.GBSpawnProtectionVolume')
	
	local AllInsertionPoints = gameplaystatics.GetAllActorsOfClass('GroundBranch.GBInsertionPoint')
	local DefenderInsertionPointNames = {}

	for i, InsertionPoint in ipairs(AllInsertionPoints) do
		if actor.HasTag(InsertionPoint, "Defenders") then
			table.insert(self.DefenderInsertionPoints, InsertionPoint)
			table.insert(DefenderInsertionPointNames, gamemode.GetInsertionPointName(InsertionPoint))
		elseif actor.HasTag(InsertionPoint, "Attackers") then
			table.insert(self.AttackerInsertionPoints, InsertionPoint)
		end
	end
	
	local AllLaptops = gameplaystatics.GetAllActorsOfClass('/Game/GroundBranch/Props/Electronics/MilitaryLaptop/BP_Laptop_Usable.BP_Laptop_Usable_C')
		
	for i, DefenderInsertionPointName in ipairs(DefenderInsertionPointNames) do
		self.GroupedLaptops[DefenderInsertionPointName] = {}
		for j, Laptop in ipairs(AllLaptops) do
			if actor.HasTag(Laptop, DefenderInsertionPointName) then
				table.insert(self.GroupedLaptops[DefenderInsertionPointName], Laptop)
			end
		end
	end	
end

function uplink:PostInit()
	-- Set initial defending & attacking teams.
	self.DefendingTeam = self.PlayerTeams.Red
	self.AttackingTeam = self.PlayerTeams.Blue
end

function uplink:PlayerInsertionPointChanged(PlayerState, InsertionPoint)
	if InsertionPoint == nil then
		timer.Set("CheckReadyDown", self, self.CheckReadyDownTimer, 0.1, false);
	else
		timer.Set("CheckReadyUp", self, self.CheckReadyUpTimer, 0.25, false);
	end
end

function uplink:PlayerReadyStatusChanged(PlayerState, ReadyStatus)
	if ReadyStatus ~= "DeclaredReady" then
		timer.Set("CheckReadyDown", self, self.CheckReadyDownTimer, 0.1, false);
	elseif gamemode.GetRoundStage() == "PreRoundWait" then
		if actor.GetTeamId(PlayerState) == self.DefendingTeam.TeamId then
			if self.RandomDefenderInsertionPoint ~= nil then
				player.SetInsertionPoint(PlayerState, self.RandomDefenderInsertionPoint)
				gamemode.EnterPlayArea(PlayerState)
			end
		elseif gamemode.PrepLatecomer(PlayerState) then
			gamemode.EnterPlayArea(PlayerState)
		end
	end
end

function uplink:CheckReadyUpTimer()
	if gamemode.GetRoundStage() == "WaitingForReady" or gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(true)
		local DefendersReady = ReadyPlayerTeamCounts[self.DefendingTeam.TeamId]
		local AttackersReady = ReadyPlayerTeamCounts[self.AttackingTeam.TeamId]
		if DefendersReady > 0 and AttackersReady > 0 then
			if DefendersReady + AttackersReady >= gamemode.GetPlayerCount(true) then
				gamemode.SetRoundStage("PreRoundWait")
			else
				gamemode.SetRoundStage("ReadyCountdown")
			end
		end
	end
end

function uplink:CheckReadyDownTimer()
	if gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(true)
		local DefendersReady = ReadyPlayerTeamCounts[self.DefendingTeam.TeamId]
		local AttackersReady = ReadyPlayerTeamCounts[self.AttackingTeam.TeamId]
		if DefendersReady < 1 or AttackersReady < 1 then
			gamemode.SetRoundStage("WaitingForReady")
		end
	end
end

function uplink:OnRoundStageSet(RoundStage)
	if RoundStage == "WaitingForReady" then
		self:SetupRound()
	elseif RoundStage == "BlueDefenderSetup" or RoundStage == "RedDefenderSetup" then
		gamemode.SetRoundStageTime(self.Settings.DefenderSetupTime.Value)
	elseif RoundStage == "InProgress" then
		timer.Set("DisableSpawnProtection", self, self.DisableSpawnProtectionTimer, 5.0, false);
	elseif RoundStage == "PostRoundWait" then
		if self.Settings.AutoSwap.Value ~= 0 then
			self:SwapTeams()
		end
	end
end

function uplink:OnCharacterDied(Character, CharacterController, KillerController)
	if gamemode.GetRoundStage() == "PreRoundWait" 
	or gamemode.GetRoundStage() == "InProgress"
	or gamemode.GetRoundStage() == "BlueDefenderSetup"
	or gamemode.GetRoundStage() == "RedDefenderSetup" then
		if CharacterController ~= nil then
			player.SetLives(CharacterController, player.GetLives(CharacterController) - 1)
			timer.Set("CheckEndRound", self, self.CheckEndRoundTimer, 1.0, false);
		end
	end
end

function uplink:CheckEndRoundTimer()
	local AttackersWithLives = gamemode.GetPlayerListByLives(self.AttackingTeam.TeamId, 1, false)
	
	if #AttackersWithLives == 0 then
		local DefendersWithLives = gamemode.GetPlayerListByLives(self.DefendingTeam.TeamId, 1, false)
		if #DefendersWithLives > 0 then
			gamemode.AddGameStat("Result=Team" .. tostring(self.DefendingTeam.TeamId))
			if self.DefendingTeam == self.PlayerTeams.Blue then
				gamemode.AddGameStat("Summary=RedEliminated")
			else
				gamemode.AddGameStat("Summary=BlueEliminated")
			end
			gamemode.AddGameStat("CompleteObjectives=DefendObjective")
			gamemode.SetRoundStage("PostRoundWait")
		else
			gamemode.AddGameStat("Result=None")
			gamemode.AddGameStat("Summary=BothEliminated")
			gamemode.SetRoundStage("PostRoundWait")
		end
	end
end

function uplink:SetupRound()
	if self.ShowAutoSwapMessage == true then
		self.ShowAutoSwapMessage = false
		
		local Attackers = gamemode.GetPlayerList(self.AttackingTeam.TeamId, false)
		for i = 1, #Attackers do
			player.ShowGameMessage(Attackers[i], "SwapAttacking", "Center", 10.0)
		end
		
		local Defenders = gamemode.GetPlayerList(self.DefendingTeam.TeamId, false)
		for i = 1, #Defenders do
			player.ShowGameMessage(Defenders[i], "SwapDefending", "Center", 10.0)
		end
	end

	for i, SpawnProtectionVolume in ipairs(self.SpawnProtectionVolumes) do
		actor.SetTeamId(SpawnProtectionVolume, self.AttackingTeam.TeamId)
		actor.SetActive(SpawnProtectionVolume, true)
	end

	gamemode.ClearGameObjectives()

	gamemode.AddGameObjective(self.DefendingTeam.TeamId, "DefendObjective", 1)
	gamemode.AddGameObjective(self.AttackingTeam.TeamId, "CaptureObjective", 1)

	for i, InsertionPoint in ipairs(self.AttackerInsertionPoints) do
		actor.SetActive(InsertionPoint, true)
		actor.SetTeamId(InsertionPoint, self.AttackingTeam.TeamId)
	end

	if #self.DefenderInsertionPoints > 1 then
		local NewRandomDefenderInsertionPoint = self.RandomDefenderInsertionPoint

		while (NewRandomDefenderInsertionPoint == self.RandomDefenderInsertionPoint) do
			NewRandomDefenderInsertionPoint = self.DefenderInsertionPoints[umath.random(#self.DefenderInsertionPoints)]
		end
		
		self.RandomDefenderInsertionPoint = NewRandomDefenderInsertionPoint
	else
		self.RandomDefenderInsertionPoint = self.DefenderInsertionPoints[1]
	end
	
	for i, InsertionPoint in ipairs(self.DefenderInsertionPoints) do
		if InsertionPoint == self.RandomDefenderInsertionPoint then
			actor.SetActive(InsertionPoint, true)
			actor.SetTeamId(InsertionPoint, self.DefendingTeam.TeamId)
		else
			actor.SetActive(InsertionPoint, false)
			actor.SetTeamId(InsertionPoint, 255)
		end
	end

	local InsertionPointName = gamemode.GetInsertionPointName(self.RandomDefenderInsertionPoint)
	local PossibleLaptops = self.GroupedLaptops[InsertionPointName]
	self.RandomLaptop = PossibleLaptops[umath.random(#PossibleLaptops)]

	for Group, Laptops in pairs(self.GroupedLaptops) do
		for j, Laptop in ipairs(Laptops) do
			local bActive = (Laptop == self.RandomLaptop)
			actor.SetActive(Laptop, bActive)
		end
	end
end

function uplink:SwapTeams()
	if self.DefendingTeam == self.PlayerTeams.Blue then
		self.DefendingTeam = self.PlayerTeams.Red
		self.AttackingTeam = self.PlayerTeams.Blue
	else
		self.DefendingTeam = self.PlayerTeams.Blue
		self.AttackingTeam = self.PlayerTeams.Red
	end
	
	self.ShowAutoSwapMessage = true
end

function uplink:ShouldCheckForTeamKills()
	if gamemode.GetRoundStage() == "InProgress" 
	or gamemode.GetRoundStage() == "BlueDefenderSetup"
	or gamemode.GetRoundStage() == "RedDefenderSetup" then
		return true
	end
	return false
end

function uplink:PlayerCanEnterPlayArea(PlayerState)
	if player.GetInsertionPoint(PlayerState) ~= nil then
		return true
	end
	return false
end

function uplink:OnRoundStageTimeElapsed(RoundStage)
	if RoundStage == "PreRoundWait" then
		if self.DefendingTeam == self.PlayerTeams.Blue then
			gamemode.SetRoundStage("BlueDefenderSetup")
		else
			gamemode.SetRoundStage("RedDefenderSetup")
		end
		return true
	elseif RoundStage == "BlueDefenderSetup"
		or RoundStage == "RedDefenderSetup" then
		gamemode.SetRoundStage("InProgress")
		return true
	end
	return false
end

function uplink:TargetCaptured()
	gamemode.AddGameStat("Summary=CaptureObjective")
	gamemode.AddGameStat("CompleteObjectives=CaptureObjective")
	gamemode.AddGameStat("Result=Team" .. tostring(self.AttackingTeam.TeamId))
	gamemode.SetRoundStage("PostRoundWait")
end

function uplink:PlayerEnteredPlayArea(PlayerState)
	if actor.GetTeamId(PlayerState) == self.AttackingTeam.TeamId then
		local FreezeTime = self.Settings.DefenderSetupTime.Value + gamemode.GetRoundStageTime()
		player.FreezePlayer(PlayerState, FreezeTime)
	elseif actor.GetTeamId(PlayerState) == self.DefendingTeam.TeamId then
		local LaptopLocation = actor.GetLocation(self.RandomLaptop)
		player.ShowWorldPrompt(PlayerState, LaptopLocation, "DefendTarget", self.Settings.DefenderSetupTime.Value - 2)
	end
end

function uplink:DisableSpawnProtectionTimer()
	if gamemode.GetRoundStage() == "InProgress" then
		for i, SpawnProtectionVolume in ipairs(self.SpawnProtectionVolumes) do
			actor.SetActive(SpawnProtectionVolume, false)
		end
	end
end

function uplink:LogOut(Exiting)
	if gamemode.GetRoundStage() == "PreRoundWait" 
	or gamemode.GetRoundStage() == "InProgress"
	or gamemode.GetRoundStage() == "BlueDefenderSetup"
	or gamemode.GetRoundStage() == "RedDefenderSetup" then
		timer.Set("CheckEndRound", self, self.CheckEndRoundTimer, 1.0, false);
	end
end

return uplink