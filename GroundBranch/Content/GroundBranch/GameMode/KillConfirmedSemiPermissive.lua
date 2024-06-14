--[[
	Kill Confirmed (Semi-Permissive)
	PvE Ground Branch game mode by Bob/AT

	Notes on CollateralDamageThreshold:

		The default value is 3. It can be changed by admins.
		Remember: once is a mistake, twice is a coincidence, thrice is a habit.
]]--

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

local AdminConfiguration = {
	-- If you want to disable soft fail, change the next line to:
	--   SoftFailEnabled = false
	SoftFailEnabled = true,
	-- The max. amount of collateral damage before failing the mission
	CollateralDamageThreshold = 3
}


local Tables = require('Common.Tables')
local AvoidFatality = require('Objectives.AvoidFatality')
local NoSoftFail = require('Objectives.NoSoftFail')

-- Create a deep copy of the singleton
local super = Tables.DeepCopy(require('KillConfirmed'))

super.GameModeAuthor = "(c) Bob/AT | https://gbgmc.github.io/license"
super.Settings.RespawnCost.Value = 100000

-- Add new score types
super.PlayerScoreTypes.CollateralDamage = {
	Score = -250,
	OneOff = false,
	Description = 'Killed a non-combatant'
}
super.TeamScoreTypes.CollateralDamage = {
	Score = -250,
	OneOff = false,
	Description = 'Killed a non-combatant'
}
-- Add additional objectives
super.Objectives.AvoidFatality = AvoidFatality.new('NoCollateralDamage')
super.Objectives.NoSoftFail = NoSoftFail.new()

-- Our sub-class of the singleton
local Mode = setmetatable({Config = {}}, { __index = super })

function Mode:PreInit()
	super.PreInit(self)
	for k,v in pairs(AdminConfiguration) do self.Config[k] = v end
end

function Mode:PostInit()
	gamemode.AddGameObjective(self.PlayerTeams.BluFor.TeamId, 'NeutralizeHVTs', 1)
	gamemode.AddGameObjective(self.PlayerTeams.BluFor.TeamId, 'ConfirmEliminatedHVTs', 1)
	gamemode.AddGameObjective(self.PlayerTeams.BluFor.TeamId, 'NoCollateralDamage', 1)
	gamemode.AddGameObjective(self.PlayerTeams.BluFor.TeamId, 'ExfiltrateBluFor', 1)
end

function Mode:OnRoundStageSet(RoundStage)
	if (RoundStage == 'PostRoundWait' or RoundStage == 'TimeLimitReached') and self.Config.SoftFailEnabled then
		-- Make sure the 'SOFT FAIL' message is cleared
		gamemode.BroadcastGameMessage('Blank', 'Center', -1)
	end
	super.OnRoundStageSet(self, RoundStage)
end

function Mode:PreRoundCleanUp()
	super.PreRoundCleanUp(self)
	gamemode.SetTeamAttitude(1, 10, 'Neutral')
	gamemode.SetTeamAttitude(10, 1, 'Neutral')
	gamemode.SetTeamAttitude(10, 100, 'Friendly')
	gamemode.SetTeamAttitude(100, 10, 'Friendly')
end

function Mode:OnCharacterDied(Character, CharacterController, KillerController)
	local goodKill = true

	if gamemode.GetRoundStage() == 'PreRoundWait' or gamemode.GetRoundStage() == 'InProgress'
	then
		if CharacterController ~= nil then
			local killedTeam = actor.GetTeamId(CharacterController)
			local killerTeam = nil
			if KillerController ~= nil then
				killerTeam = actor.GetTeamId(KillerController)
			end
			if killedTeam == 10 and killerTeam == self.PlayerTeams.BluFor.TeamId then
				goodKill = false
				self.Objectives.AvoidFatality:ReportFatality()
				self.PlayerTeams.BluFor.Script:AwardPlayerScore(KillerController, 'CollateralDamage')
				self.PlayerTeams.BluFor.Script:AwardTeamScore('CollateralDamage')

				local message = gamemode.FormatString({
					FormatString = "CollateralDamageBy",
					Name = player.GetName(KillerController)
				})
				self.PlayerTeams.BluFor.Script:DisplayMessageToAllPlayers(message, 'Engine', 5.0, 'ScoreMilestone')

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
			end
			if killedTeam == killerTeam and killerTeam == self.PlayerTeams.BluFor.TeamId then
				-- Count fratricides as collateral damage
				self.Objectives.AvoidFatality:ReportFatality()
			end
		end
	end

	if goodKill then
		super.OnCharacterDied(self, Character, CharacterController, KillerController)
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
	if self.Objectives.NoSoftFail:IsOK() then
		gamemode.AddGameStat('Summary=HVTsConfirmed')
		gamemode.AddGameStat('Result=Team1')
	else
		gamemode.AddGameStat('Summary=SoftFail')
		gamemode.AddGameStat('Result=None')
	end
	gamemode.SetRoundStage('PostRoundWait')
end

return Mode
