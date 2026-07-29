--//Imports
local App = Require("shared/framework/App.lua")
local Config = Require("games/shinsei/config.lua")

--//Variables
local Shinsei = {}

local FeatureList = {
	{
		Name = "AutoSigns",
		Path = "games/shinsei/Features/AutoSignals/init.lua",
	},
}

--//Source
function Shinsei.RunChecks(app)
	app.Debug:Log("checks-ok", {
		game = Config.Name,
	})
	return true
end

function Shinsei.LoadUI(app)
	app.Debug:Log("ui-skipped", {
		reason = "not implemented yet",
	})
end

function Shinsei.LoadFeatures(app)
	return app:StartModules(FeatureList)
end

function Shinsei.Start(framework)
	local app = App.new(framework, Config)
	framework.Context = app

	--> Game checks
	if not Shinsei.RunChecks(app) then
		return app
	end

	--> Load game layers
	Shinsei.LoadUI(app)
	Shinsei.LoadFeatures(app)

	app.Debug:Log("game-started", {
		name = Config.Name,
		version = Config.Version,
		features = #FeatureList,
	})

	return app
end

return Shinsei
