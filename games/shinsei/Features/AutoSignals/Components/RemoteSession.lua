--//Variables
local RemoteSession = {}
RemoteSession.__index = RemoteSession

--//Source
function RemoteSession.new(context, statusView, castUI, skillSelector, objectives, rewardsSync)
	return setmetatable({
		Context = context,
		Status = statusView,
		CastUI = castUI,
		Skills = skillSelector,
		Objectives = objectives,
		Rewards = rewardsSync,
		State = context.State,
		Session = context.RemoteSession,
		RegisterCastGame = context.RegisterCastGame,
		RewardsInfo = context.RewardsInfo,
		PointModes = context.Constants.PointsModes,
		SkillByCode = context.SkillByCode,
		SkillNameByCode = context.SkillNameByCode,
	}, RemoteSession)
end

function RemoteSession:Start(currentSignCode)
	local selectedSkills = self.Skills:InferSelected()

	if currentSignCode and self.SkillByCode[currentSignCode] then
		local alreadySelected = false

		for _, selectedEntry in ipairs(selectedSkills) do
			if selectedEntry.Code == currentSignCode then
				alreadySelected = true
				break
			end
		end

		if not alreadySelected then
			table.insert(selectedSkills, 1, {
				Code = currentSignCode,
				Skill = self.SkillByCode[currentSignCode],
				Name = self.SkillByCode[currentSignCode].Name or self.SkillNameByCode[currentSignCode],
				Category = self.Skills:GetCategory(self.SkillByCode[currentSignCode]),
			})
		end
	end

	self.Session.Started = true
	self.Session.Finished = false
	self.Session.CastingList = selectedSkills
	self.Session.PointsMode = self.Skills:InferPointsMode()
	self.Session.TrainingCategories = self.Skills:GetTrainingCategories(selectedSkills)
	self.Session.CurrentObjective = nil
	self.Session.RandomObjectiveCast = 0
	self.Session.LastCode = nil

	self.State.SessionPoints = 0
	self.State.SessionPerfects = 0
	self.State.SessionMisses = 0
	self.State.SessionStartClock = os.clock()
	self.State.CurrentRemoteIndex = 1

	--> Start original points session
	self.RegisterCastGame:FireServer(1, {
		pointsMode = self.Session.PointsMode,
		trainingCategories = self.Session.TrainingCategories,
		castingList = (function()
			local selectedSkillNames = {}

			for _, selectedEntry in ipairs(selectedSkills) do
				selectedSkillNames[#selectedSkillNames + 1] = selectedEntry.Name
			end

			return selectedSkillNames
		end)(),
	})

	self.Context:Log("remote-session-started", {
		pointsMode = self.Session.PointsMode,
		selected = #selectedSkills,
	})
end

function RemoteSession:GetEntryForCode(signCode)
	if not self.Session.CastingList or #self.Session.CastingList <= 0 then
		return nil
	end

	if signCode then
		for _, skillEntry in ipairs(self.Session.CastingList) do
			if skillEntry.Code == signCode then
				return skillEntry
			end
		end
	end

	self.State.CurrentRemoteIndex = self.State.CurrentRemoteIndex + 1

	if self.State.CurrentRemoteIndex > #self.Session.CastingList then
		self.State.CurrentRemoteIndex = 1
	end

	return self.Session.CastingList[self.State.CurrentRemoteIndex]
end

function RemoteSession:GetNextEntry(currentSignCode)
	if not self.Session.CastingList or #self.Session.CastingList <= 0 then
		return self:GetEntryForCode(currentSignCode)
	end

	local currentIndex = 0

	for index, skillEntry in ipairs(self.Session.CastingList) do
		if skillEntry.Code == currentSignCode then
			currentIndex = index
			break
		end
	end

	local nextIndex = currentIndex + 1

	if nextIndex > #self.Session.CastingList then
		nextIndex = 1
	end

	self.State.CurrentRemoteIndex = nextIndex
	return self.Session.CastingList[nextIndex]
end

function RemoteSession:GetRewardPoints(signCode, objective)
	local keyCount = #signCode
	local points

	if keyCount >= 8 then
		points = self.RewardsInfo.EightKeys
	elseif keyCount >= 6 then
		points = self.RewardsInfo.SixKeys
	else
		points = self.RewardsInfo.LessKeys
	end

	points = points + self.RewardsInfo.PerfectCasting

	if objective then
		points = points * self.RewardsInfo.ObjectiveExtra
	end

	return points
end

function RemoteSession:UpdateGoalUI(castUI, signCode, objective)
	local goalInfo = self.Status:GetGoalInfo(castUI)

	if not goalInfo then
		return
	end

	local language = self.Status:GetLanguage()
	local elapsed = math.max(os.clock() - self.State.SessionStartClock, 0)
	local streakLabel = goalInfo:FindFirstChild("4Streak")
	local timeLabel = goalInfo:FindFirstChild("5Time")

	if streakLabel and streakLabel:IsA("TextLabel") then
		streakLabel.RichText = true

		if language == "PT" then
			streakLabel.Text = "PONTOS TOTAIS: <font color=\"rgb(255, 224, 70)\">" .. self.State.SessionPoints .. "</font>"
		else
			streakLabel.Text = "CASTING POINTS: <font color=\"rgb(255, 224, 70)\">" .. self.State.SessionPoints .. "</font>"
		end
	end

	if timeLabel and timeLabel:IsA("TextLabel") then
		if language == "PT" then
			timeLabel.Text = "TEMPO: " .. string.format("%.2f", elapsed)
		else
			timeLabel.Text = "LIFETIME: " .. string.format("%.2f", elapsed)
		end
	end

	local castingTimeFrame = castUI:FindFirstChild("castingTime")
	local titleLabel = castingTimeFrame and castingTimeFrame:FindFirstChild("Title")
	local extraPointsLabel = castingTimeFrame and castingTimeFrame:FindFirstChild("ExtraPoints")

	if titleLabel and titleLabel:IsA("TextLabel") then
		titleLabel.Parent.Visible = true
		titleLabel.Text = language == "PT" and "PERFEITO" or "PERFECT"

		for _, child in ipairs(titleLabel:GetChildren()) do
			if child:IsA("UIGradient") then
				child.Enabled = child.Name == "PERFECT"
			end
		end

		task.delay(0.45, function()
			if titleLabel.Parent then
				titleLabel.Parent.Visible = false
			end
		end)
	end

	if extraPointsLabel and extraPointsLabel:IsA("TextLabel") then
		extraPointsLabel.Visible = objective ~= nil
	end
end

function RemoteSession:ShouldFinish()
	local mode = self.Session.PointsMode
	local config = self.PointModes[mode]

	return config and config.Points and self.State.SessionPoints >= config.Points
end

function RemoteSession:Finish()
	if self.Session.Finished then
		return
	end

	self.Session.Finished = true
	self.Session.Started = false
	self.RegisterCastGame:FireServer(4)
	self.Status:Set("finished")

	task.delay(0.35, function()
		self.Rewards:Refresh()
	end)
end

return RemoteSession
