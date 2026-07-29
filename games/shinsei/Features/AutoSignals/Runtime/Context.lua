--//Imports
local Constants = Require("games/shinsei/Metadata/AutoSignals.lua")
local SkillIndex = Require("games/shinsei/Utilities/SkillIndex.lua")

--//Variables
local Context = {}
Context.__index = Context

--//Source
local function copyInto(target, source)
	for key, value in pairs(source or {}) do
		target[key] = value
	end

	return target
end

function Context.new(app)
	local serviceRegistry = app.Services
	local replicatedStorage = serviceRegistry.ReplicatedStorage
	local eventsFolder = replicatedStorage:WaitForChild("Events")
	local modulesFolder = replicatedStorage:WaitForChild("Modules")
	local skillsData = require(modulesFolder:WaitForChild("Skills"))
	local rewardsInfo = require(modulesFolder:WaitForChild("RewardsInfo"))
	local globalEnvironment = (getgenv and getgenv()) or _G

	local state = copyInto({
		Running = true,
		Busy = false,
		Casts = 0,
		SessionPoints = 0,
		SessionPerfects = 0,
		SessionMisses = 0,
		SessionStartClock = 0,
		CurrentRemoteIndex = 1,
		LastStatus = "waiting",
		LastRewardData = nil,
		LastRewardClock = 0,
		Framework = app.Framework,
		FrameworkVersion = app.Framework and app.Framework.Version,
	}, app.Config.AutoSigns)

	local skillIndex = SkillIndex.Build(skillsData)

	return setmetatable({
		App = app,
		Framework = app.Framework,
		Config = app.Config,
		Env = globalEnvironment,
		Services = serviceRegistry,
		LocalPlayer = serviceRegistry.LocalPlayer,
		Events = eventsFolder,
		RegisterCastGame = eventsFolder:WaitForChild("registerCastGame"),
		GetRewards = eventsFolder:WaitForChild("getRewards"),
		Skills = skillsData,
		RewardsInfo = rewardsInfo,
		Constants = Constants,
		SkillByCode = skillIndex.ByCode,
		SkillNameByCode = skillIndex.NameByCode,
		Chars = skillIndex.Chars,
		State = state,
		Bridge = {
			LastScan = 0,
			Actions = nil,
			State = nil,
			RemoveSign = nil,
			ActiveSign = nil,
		},
		RemoteSession = {
			Started = false,
			Finished = false,
			CastingList = nil,
			PointsMode = nil,
			TrainingCategories = nil,
			CurrentObjective = nil,
			RandomObjectiveCast = 0,
			LastCode = nil,
		},
	}, Context)
end

function Context:BindFeature(feature)
	local previousState = self.Env.YShinseiAutoSigns

	if previousState and type(previousState.Stop) == "function" then
		pcall(previousState.Stop)
	end

	self.State.Stop = function()
		feature:Stop()
	end

	self.Env.YShinseiAutoSigns = self.State
	self.Env.YShinseiAutoSignsStop = self.State.Stop
end

function Context:Log(message, data)
	if self.State.Debug then
		print("[YAutoSigns]", message, data or "")
	end

	if self.App and self.App.Debug then
		self.App.Debug:Log(message, data)
	end
end

return Context
