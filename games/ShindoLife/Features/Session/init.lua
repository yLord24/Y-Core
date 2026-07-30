--//Imports
local Guard = yrequire("games/ShindoLife/Utilities/Guard.lua")
local State = yrequire("games/ShindoLife/Features/Session/Runtime/State.lua")
local ServerBrowser = yrequire("games/ShindoLife/Features/Session/Components/ServerBrowser.lua")
local TeleportClient = yrequire("games/ShindoLife/Features/Session/Components/TeleportClient.lua")

--//Variables
local Session = {}
Session.__index = Session

--//Source
local function getEnvironment()
	return (getgenv and getgenv()) or _G
end

function Session.new(app)
	local sessionConfig = app.Config.Session or {}
	local sessionState = State.new(app, sessionConfig)
	local serverBrowser = ServerBrowser.new(app, sessionConfig, sessionState)
	local teleportClient = TeleportClient.new(app, sessionConfig, sessionState, serverBrowser)

	return setmetatable({
		App = app,
		Config = sessionConfig,
		Services = app.Services,
		State = sessionState,
		Browser = serverBrowser,
		Teleport = teleportClient,
	}, Session)
end

function Session:Rejoin()
	return self.Teleport:Rejoin()
end

function Session:ServerHop()
	return self.Teleport:ServerHop()
end

function Session:Start()
	if not Guard.ShouldExport(self.App) then
		return self
	end

	local environment = getEnvironment()

	environment.YShindoLifeRejoin = function()
		return self:Rejoin()
	end

	environment.YShindoLifeServerHop = function()
		return self:ServerHop()
	end

	return self
end

function Session:Stop()
	local environment = getEnvironment()

	if environment.YShindoLifeRejoin then
		environment.YShindoLifeRejoin = nil
	end

	if environment.YShindoLifeServerHop then
		environment.YShindoLifeServerHop = nil
	end
end

return Session
