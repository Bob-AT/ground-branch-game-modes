local inteltarget = {
	CurrentTime = 0,
}

function inteltarget:ServerUseTimer(User, DeltaTime)
	self.CurrentTime = self.CurrentTime + DeltaTime
	local SearchTime = gamemode.script.Settings.SearchTime.Value
	self.CurrentTime = math.max(self.CurrentTime, 0)
	self.CurrentTime = math.min(self.CurrentTime, SearchTime)

	local Result = {}
	Result.Message = "IntelSearch"
	Result.Equip = false
	Result.Percentage = self.CurrentTime / SearchTime
	if Result.Percentage == 1.0 then
		if actor.HasTag(self.Object, gamemode.script.LaptopTag) then
			Result.Message = "IntelFound"
			Result.Equip = true
		else
			Result.Message = "IntelNotFound"
		end
	end
	return Result
end

function inteltarget:OnReset()
	self.CurrentTime = 0
end

function inteltarget:CarriedLaptopDestroyed()
	if actor.HasTag(self.Object, gamemode.script.LaptopTag) then
		if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "InProgress" then
			gamemode.BroadcastGameMessage("LaptopDestroyed", "Center", 10.0)
		end
	end
end

return inteltarget