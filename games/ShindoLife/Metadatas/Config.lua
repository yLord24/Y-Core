--//Variables
local Config = {
	Name = "Y Hub - Shindo Life",
	Version = "0.1.0",

	Debug = {
		Enabled = false,
		Console = false,
		Prefix = "[YShindoLife]",
		Folder = "YCore/ShindoLife",
		File = "YCore/ShindoLife/Framework.log",
		FlushInterval = 1,
		MaxLines = 600,
	},

	UI = {
		Repository = "https://raw.githubusercontent.com/yLord24/YLib/refs/heads/main/",
		CacheFolder = "YCore/UILibCache",
		SaveFolder = "YHubV3/ShindoLife",
		MenuKeybind = "End",
	},

	Guard = {
		Enabled = true,
		ExportGlobals = "dev",
		AllowedPlaceIds = { 4616652839 },

		RemoteBuild = {
			Enabled = true,
			RequirePublished = false,
			AllowDevelopment = true,
			Url = "https://raw.githubusercontent.com/yLord24/Y-Core-Builds/main/ShindoLife.luau",
			Signature = "YCORE_SHINDOLIFE_RELEASE_GUARD_V1",
			MinLength = 256,
		},

		Release = {
			RequireBundle = true,
			Game = "shindolife",
			BundleName = "ShindoLife.luau",
			Signature = "YCORE_SHINDOLIFE_RELEASE_GUARD_V1",
		},
	},

	RemoteMask = {
		Enabled = true,
		InDev = false,
		Root = "ReplicatedStorage",
		BeforeMin = 22,
		BeforeMax = 42,
		AfterMin = 18,
		AfterMax = 34,
		MaxDepth = 3,
		DecoyJitter = true,
		DecoyJitterMin = 0.003,
		DecoyJitterMax = 0.012,
		JitterMin = 0.02,
		JitterMax = 0.07,
	},

	Rollback = {
		Enabled = false,
		Cooldown = 0,
		RemoteName = "startevent",
		ValueName = "beardcolor",
		OnValue = "0,0,",
		OnValueByte = 255,
		OffValue = "0,0,0",
	},

	Session = {
		ServerHopPages = 5,
		ServerHopDelay = 0.15,
	},
}

--//Source
return Config
