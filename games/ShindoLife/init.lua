--//Imports
local App = yrequire("shared/Framework/App.lua")
local UILib = yrequire("shared/Framework/UILib.lua")
local Config = yrequire("games/ShindoLife/Metadatas/Config.lua")
local Guard = yrequire("games/ShindoLife/Utilities/Guard.lua")
local Settings = yrequire("games/ShindoLife/Utilities/Settings.lua")
local RollbackPanel = yrequire("games/ShindoLife/Features/Rollback/UI/Panel.lua")
local SessionPanel = yrequire("games/ShindoLife/Features/Session/UI/Panel.lua")

--//Variables
local ShindoLife = {}

local FeatureList = {
	{
		Name = "Rollback",
		Path = "games/ShindoLife/Features/Rollback/init.lua",
	},
	{
		Name = "Session",
		Path = "games/ShindoLife/Features/Session/init.lua",
	},
}

--//Source
local function getEnvironment()
	return (getgenv and getgenv()) or _G
end

function ShindoLife.BindGlobal(app)
	local environment = getEnvironment()
	local previousApp = environment.YCoreShindoLife

	if previousApp and previousApp ~= app and type(previousApp.Destroy) == "function" then
		pcall(function()
			previousApp:Destroy()
		end)
	end

	environment.YCoreShindoLife = app
	environment.YShindoLife = app
end

function ShindoLife.ClearGlobal()
	local environment = getEnvironment()

	environment.YCoreShindoLife = nil
	environment.YShindoLife = nil
end

function ShindoLife.RunChecks(app)
	local localPlayer = app.Services.LocalPlayer
	local guardReady, guardReason = Guard.Run(app)

	if not guardReady then
		if not Guard.ShouldSilence(app) then
			app.Debug:Log("guard-blocked", {
				reason = guardReason,
				game = Config.Name,
			})
			warn("[YShindoLife] Guard blocked startup: " .. tostring(guardReason))
		end

		return false
	end

	app.Debug:Log("checks-ok", {
		game = Config.Name,
		player = localPlayer and localPlayer.Name or "unknown",
	})

	return true
end

function ShindoLife.LoadFeatures(app)
	return app:StartModules(FeatureList)
end

function ShindoLife.LoadUI(app)
	local startSuccess, startResult = pcall(function()
		local loadedUI = UILib.LoadStandard(app.Config.UI)
		local library = loadedUI.Library
		local themeManager = loadedUI.ThemeManager
		local saveManager = loadedUI.SaveManager

		local window = library:CreateWindow({
			Title = app.Config.Name .. " " .. app.Config.Version,
			Center = true,
			AutoShow = true,
			TabPadding = 8,
			MenuFadeTime = 0.2,
		})

		local tabs = {
			Main = window:AddTab("Main"),
			["UI Settings"] = window:AddTab("UI Settings"),
		}

		local unloaded = false
		local sessionPanel = nil

		local function unloadFramework()
			if unloaded then
				return
			end

			unloaded = true
			SessionPanel.Destroy(sessionPanel)
			app.Debug:Flush()
			app:Destroy()
			library.Unloaded = true
		end

		app.UI = {
			Library = library,
			ThemeManager = themeManager,
			SaveManager = saveManager,
			Window = window,
			Tabs = tabs,
		}

		RollbackPanel.Create(app, library, tabs.Main)
		sessionPanel = SessionPanel.Create(app, library, tabs.Main)
		Settings.Create(app, library, tabs["UI Settings"], unloadFramework)
		Settings.ApplyManagers(app, themeManager, saveManager, tabs)

		app.Debug:Log("ui-started", {
			game = app.Config.Name,
			version = app.Config.Version,
		})

		UILib.SafeNotify(library, app.Config.Name .. " loaded.", 3)

		return app.UI
	end)

	if startSuccess then
		return startResult
	end

	app.Debug:Log("ui-start-error", {
		error = startResult,
	})
	warn("[YShindoLife] UI failed: " .. tostring(startResult))

	return nil
end

function ShindoLife.Start(framework)
	local app = App.new(framework, Config)
	framework.Context = app

	if Guard.ShouldExport(app) then
		ShindoLife.BindGlobal(app)
	else
		ShindoLife.ClearGlobal()
	end

	--> Game checks
	if not ShindoLife.RunChecks(app) then
		return app
	end

	--> Load game layers
	ShindoLife.LoadFeatures(app)
	ShindoLife.LoadUI(app)

	app.Debug:Log("game-started", {
		name = Config.Name,
		version = Config.Version,
		features = #FeatureList,
	})

	return app
end

return ShindoLife
