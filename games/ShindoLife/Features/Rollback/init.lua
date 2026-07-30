--//Imports
local Guard = yrequire("games/ShindoLife/Utilities/Guard.lua")
local State = yrequire("games/ShindoLife/Features/Rollback/Runtime/State.lua")
local RemoteClient = yrequire("games/ShindoLife/Features/Rollback/Components/RemoteClient.lua")

--//Variables
local Rollback = {}
Rollback.__index = Rollback

--//Source
local function getEnvironment()
	return (getgenv and getgenv()) or _G
end

function Rollback.new(app)
	local rollbackConfig = app.Config.Rollback or {}
	local rollbackState = State.new(app, rollbackConfig)
	local remoteClient = RemoteClient.new(app, rollbackConfig, rollbackState)

	return setmetatable({
		App = app,
		Config = rollbackConfig,
		Services = app.Services,
		State = rollbackState,
		Remote = remoteClient,
	}, Rollback)
end

function Rollback:IsEnabled()
	return self.State.Enabled == true
end

function Rollback:Send(enabled)
	return self.Remote:Fire(enabled == true)
end

function Rollback:SetEnabled(enabled)
	self.State.Enabled = enabled == true
	self.Config.Enabled = self.State.Enabled

	return self:Send(self.State.Enabled)
end

function Rollback:Trigger()
	return self:SetEnabled(true)
end

function Rollback:Start()
	if not Guard.ShouldExport(self.App) then
		return self
	end

	local environment = getEnvironment()

	environment.YShindoLifeRollback = function(enabled)
		if enabled == nil then
			return self:Trigger()
		end

		return self:SetEnabled(enabled == true)
	end

	return self
end

function Rollback:Stop()
	local environment = getEnvironment()

	if environment.YShindoLifeRollback then
		environment.YShindoLifeRollback = nil
	end
end

return Rollback
