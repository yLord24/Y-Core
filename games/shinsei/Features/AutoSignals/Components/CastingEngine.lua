--//Variables
local CastingEngine = {}
CastingEngine.__index = CastingEngine

--//Source
function CastingEngine.new(context, statusView, bridgeScanner, castUI, objectives, remoteSession)
	return setmetatable({
		Context = context,
		Status = statusView,
		Bridge = bridgeScanner,
		CastUI = castUI,
		Objectives = objectives,
		Remote = remoteSession,
		State = context.State,
		BridgeState = context.Bridge,
		Session = context.RemoteSession,
		RegisterCastGame = context.RegisterCastGame,
		SkillByCode = context.SkillByCode,
		SkillNameByCode = context.SkillNameByCode,
		Chars = context.Chars,
	}, CastingEngine)
end

function CastingEngine:DesiredCastTime(signCode)
	return math.max(self.State.MinCastTime, #signCode * 0.17 - self.State.PerfectMargin)
end

function CastingEngine:CastRemote()
	local castUI = self.CastUI:GetFolder(self.BridgeState.State)

	if not castUI then
		--> Cast UI closed
		if self.Session.Started and not self.State.Busy then
			self.Session.Started = false
		end

		if self.Session.Finished then
			self.Session.Finished = false
		end

		return false
	end

	if self.Session.Finished then
		self.Status:Set("finished")
		return false
	end

	if not self.CastUI:CountdownReady(castUI) then
		self.Status:Set("countdown")
		return false
	end

	local signCode = self.CastUI:ExtractCode(castUI)

	if not signCode then
		self.Status:Set("waiting for sign")
		return false
	end

	if not self.Session.Started then
		self.Remote:Start(signCode)
	end

	local skillEntry = self.Remote:GetEntryForCode(signCode)

	if not skillEntry then
		self.Status:Set("no sign list")
		return false
	end

	local skillInfo = skillEntry.Skill
	local skillName = skillEntry.Name or skillInfo.Name or self.SkillNameByCode[skillEntry.Code]
	local castCode = signCode

	if not self.SkillByCode[castCode] then
		castCode = skillEntry.Code
	end

	local objective = self.Session.CurrentObjective or self.Objectives:DetectFromUI(castUI)
	local castTime = self:DesiredCastTime(castCode)
	local started = os.clock()

	self.State.Busy = true

	--> Start remote cast
	self.Status:Set((objective and "objective / " or "") .. castCode)
	self.Context:Log("remote-cast-started", {
		code = castCode,
		skill = skillName,
		time = castTime,
		objective = objective or "none",
	})

	self.CastUI:ClearIcons(castUI)
	self.CastUI:SetJutsuLabel(castUI, skillInfo, castCode)

	if objective then
		self.RegisterCastGame:FireServer(5, true)
	end

	self.RegisterCastGame:FireServer(2, { workspace:GetServerTimeNow(), skillName })

	for signIndex = 1, #castCode do
		if not self.State.Running or not self.State.Enabled then
			break
		end

		self.CastUI:AddSignIcon(castUI, nil, castCode:sub(signIndex, signIndex))
		self.CastUI:ShowClock(castUI, os.clock() - started)
		task.wait(self.State.IconDelay)
	end

	local remaining = castTime - (os.clock() - started)

	while remaining > 0 and self.State.Running and self.State.Enabled do
		self.CastUI:ShowClock(castUI, os.clock() - started)
		task.wait(math.min(remaining, 0.03))
		remaining = castTime - (os.clock() - started)
	end

	if self.State.Running and self.State.Enabled then
		local reportedTime = math.max(os.clock() - started, castTime)

		--> Finish remote cast
		self.RegisterCastGame:FireServer(3, { reportedTime, objective and true or nil })

		self.State.Casts = self.State.Casts + 1
		self.State.SessionPerfects = self.State.SessionPerfects + 1
		self.State.SessionPoints = self.State.SessionPoints + self.Remote:GetRewardPoints(castCode, objective)
		self.Remote:UpdateGoalUI(castUI, castCode, objective)

		if self.Remote:ShouldFinish() then
			self.Remote:Finish()
		else
			self.Objectives:MaybeRoll(castUI)

			local nextSkillEntry = self.Remote:GetNextEntry(castCode)

			if nextSkillEntry then
				self.CastUI:SetJutsuLabel(castUI, nextSkillEntry.Skill, nextSkillEntry.Code)
			end

			self.Status:Set("perfect " .. castCode)
		end
	end

	self.State.Busy = false
	task.wait(self.State.NextCastDelay)

	return true
end

function CastingEngine:CastCore()
	if not self.Bridge:Scan(false) then
		self.Status:Set("waiting for Core")
		return false
	end

	local coreState = self.BridgeState.State
	local actions = self.BridgeState.Actions

	if not coreState or not actions or not coreState.castingEnabled or not coreState.castingJutsu then
		return false
	end

	local castUI = self.CastUI:GetFolder(coreState)
	local skillInfo = coreState.castingJutsu
	local signCode = skillInfo.signCode or self.CastUI:ExtractCode(castUI)

	if not signCode or not self.SkillByCode[signCode] and not skillInfo.signKeys then
		self.Status:Set("waiting for sign")
		return false
	end

	if self.SkillByCode[signCode] then
		skillInfo = self.SkillByCode[signCode]
		coreState.castingJutsu = skillInfo
	end

	local signKeys = skillInfo.signKeys or self.Chars(signCode)
	local castTime = self:DesiredCastTime(signCode)
	local started = os.clock()
	local extra = coreState.signStateObjective ~= nil

	self.State.Busy = true

	--> Start core cast
	self.Status:Set((extra and "objective / " or "") .. signCode)
	self.Context:Log("core-cast-started", {
		code = signCode,
		time = castTime,
		skill = skillInfo.Name,
	})

	self.CastUI:ClearIcons(castUI)
	self.CastUI:SetJutsuLabel(castUI, skillInfo, signCode)

	coreState.castingClock = os.clock()
	coreState.signLifetime = 0
	coreState.signString = ""
	coreState.signLetters = nil
	coreState.inSign = tick()
	coreState.lastSignKey = nil
	coreState.signOff = nil

	self.RegisterCastGame:FireServer(2, { workspace:GetServerTimeNow(), skillInfo.Name or self.SkillNameByCode[signCode] })

	for _, signLetter in ipairs(signKeys) do
		if not self.State.Running or not self.State.Enabled or not coreState.castingEnabled then
			break
		end

		coreState.signString = coreState.signString .. signLetter
		coreState.signLetters = (coreState.signLetters or 0) + 1
		self.CastUI:AddSignIcon(castUI, coreState, signLetter)
		self.CastUI:ShowClock(castUI, os.clock() - started)
		task.wait(self.State.IconDelay)
	end

	local remaining = castTime - (os.clock() - started)

	while remaining > 0 and self.State.Running and self.State.Enabled and coreState.castingEnabled do
		self.CastUI:ShowClock(castUI, os.clock() - started)
		task.wait(math.min(remaining, 0.05))
		remaining = castTime - (os.clock() - started)
	end

	if self.State.Running and self.State.Enabled and coreState.castingEnabled then
		--> Finish core cast
		coreState.signString = signCode
		coreState.signLetters = #signCode
		coreState.inSign = tick()
		coreState.signLifetime = os.clock() - coreState.castingClock
		self.Objectives:ForceCore(coreState)

		local castSuccess, castError = pcall(function()
			actions.sucessSign()
		end)

		if not castSuccess then
			warn("[YAutoSigns] Core sucessSign failed: " .. tostring(castError))
		else
			self.State.Casts = self.State.Casts + 1
			self.Status:Set("perfect " .. signCode)
		end

		if self.BridgeState.RemoveSign then
			pcall(self.BridgeState.RemoveSign, true)
		else
			self.CastUI:ClearIcons(castUI)
		end

		if actions.randomizeSign then
			pcall(function()
				if coreState.castingList and #coreState.castingList >= 1 then
					actions.randomizeSign()
				end
			end)
		end
	end

	self.State.Busy = false
	task.wait(self.State.NextCastDelay)

	return true
end

function CastingEngine:Step()
	if not self.State.Enabled then
		self.Status:Set("disabled")
		task.wait(0.2)
		return
	end

	local didCast = false

	if not self.State.Busy then
		if self.State.Mode ~= "remote" then
			didCast = self:CastCore()
		end

		if not didCast and self.State.Mode ~= "core" then
			didCast = self:CastRemote()
		end
	end

	if not didCast then
		if not self.CastUI:GetFolder(self.BridgeState.State) then
			self.Status:Set("waiting for start")
		elseif not self.State.Busy then
			self.Status:Set("waiting for sign")
		end

		task.wait(0.08)
	end
end

return CastingEngine
