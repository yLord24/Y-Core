--//Imports
local Context = Require("games/shinsei/Features/AutoSignals/Runtime/Context.lua")
local Objectives = Require("games/shinsei/Features/AutoSignals/Runtime/Objectives.lua")

local StatusView = Require("games/shinsei/Features/AutoSignals/UI/StatusView.lua")
local CastUI = Require("games/shinsei/Features/AutoSignals/UI/CastUI.lua")

local BridgeScanner = Require("games/shinsei/Features/AutoSignals/Components/BridgeScanner.lua")
local CastingEngine = Require("games/shinsei/Features/AutoSignals/Components/CastingEngine.lua")
local RemoteSession = Require("games/shinsei/Features/AutoSignals/Components/RemoteSession.lua")
local RewardsSync = Require("games/shinsei/Features/AutoSignals/Components/RewardsSync.lua")
local SkillSelector = Require("games/shinsei/Features/AutoSignals/Components/SkillSelector.lua")

--//Variables
local AutoSignals = {}
AutoSignals.__index = AutoSignals

--//Source
function AutoSignals.new(app)
	local featureContext = Context.new(app)
	local statusView = StatusView.new(featureContext)
	local bridgeScanner = BridgeScanner.new(featureContext)
	local castUI = CastUI.new(featureContext, statusView)
	local objectives = Objectives.new(featureContext, statusView)
	local skillSelector = SkillSelector.new(featureContext, statusView)
	local rewardsSync = RewardsSync.new(featureContext, statusView)
	local remoteSession = RemoteSession.new(featureContext, statusView, castUI, skillSelector, objectives, rewardsSync)
	local castingEngine = CastingEngine.new(featureContext, statusView, bridgeScanner, castUI, objectives, remoteSession)

	return setmetatable({
		App = app,
		Context = featureContext,
		Status = statusView,
		Bridge = bridgeScanner,
		CastUI = castUI,
		Objectives = objectives,
		Skills = skillSelector,
		Rewards = rewardsSync,
		Remote = remoteSession,
		Casting = castingEngine,
		State = featureContext.State,
		Started = false,
	}, AutoSignals)
end

function AutoSignals:Start()
	if self.Started then
		return self
	end

	self.Started = true

	--> Bind global helpers
	self.Context:BindFeature(self)

	--> Initial scan
	self.Status:Start()
	self.Bridge:Scan(true)
	self.Rewards:Refresh()

	self.State.RescanCore = function()
		return self.Bridge:Scan(true)
	end

	self.State.RefreshRewardsNow = function()
		return self.Rewards:Refresh()
	end

	self.Context.Env.YShinseiAutoSignsRefreshRewards = self.State.RefreshRewardsNow

	local visualRewardRemote = self.Context.Events:FindFirstChild("visualReward")

	if visualRewardRemote and visualRewardRemote:IsA("RemoteEvent") then
		self.App.Maid:Give(visualRewardRemote.OnClientEvent:Connect(function()
			task.delay(0.15, function()
				self.Rewards:Refresh()
			end)
		end))
	end

	--> Keep rewards updated
	task.spawn(function()
		while self.State.Running do
			self.Rewards:Refresh()
			task.wait(self.State.RewardsInterval)
		end
	end)

	--> Keep display synced
	task.spawn(function()
		while self.State.Running do
			local displayData = self.Rewards:GetDisplayData()

			if displayData then
				self.Rewards:UpdateUI(displayData)
			end

			task.wait(1)
		end
	end)

	--> Main casting loop
	task.spawn(function()
		while self.State.Running do
			self.Casting:Step()
		end
	end)

	print("[YAutoSigns] V2 ready. It now uses framework modules instead of keyboard input, so it can run while Roblox is in another tab.")
	return self
end

function AutoSignals:Stop()
	self.State.Running = false
	self.State.Busy = false
	self.Status:Destroy()
end

function AutoSignals:Destroy()
	self:Stop()
end

return AutoSignals
