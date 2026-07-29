--//Variables
local Config = {
	Name = "Y Auto Signal",
	Version = "0.1.0",

	Debug = {
		Enabled = false,
		Console = false,
		Prefix = "[YAutoSigns]",
		Folder = "YCore/Shinsei",
		File = "YCore/Shinsei/AutoSigns.log",
		FlushInterval = 1,
		MaxLines = 1200,
	},

	AutoSigns = {
		Enabled = true,
		AutoObjectives = true,
		RefreshRewards = true,
		ShowStatus = true,
		Debug = false,

		-- The client marks perfect at #keys * 0.17. We finish just under it.
		PerfectMargin = 0.018,
		MinCastTime = 0.38,
		IconDelay = 0.018,
		NextCastDelay = 0.035,
		BridgeRescanDelay = 1,
		RewardsInterval = 2,
		Mode = "auto", -- auto, core, remote
	},
}

--//Source
return Config
