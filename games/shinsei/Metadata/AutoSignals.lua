--//Variables
local Constants = {}

Constants.PointsModes = {
	Unlimted = {},
	["100Points"] = { Points = 100 },
	["500Points"] = { Points = 500 },
	["1000Points"] = { Points = 1000 },
}

Constants.NumberSuffixes = {
	{ 1000000000000, "t" },
	{ 1000000000, "b" },
	{ 1000000, "m" },
	{ 1000, "k" },
}

Constants.RewardOrder = {
	"Ryo",
	"AppearanceSpin",
	"ClanSpin",
	"Playtime",
	"RewardPlaytime",
	"Points",
}

Constants.RewardText = {
	Ryo = { ENG = "Ryo", PT = "Ryo", rewardInstance = "4RyoReward" },
	AppearanceSpin = { ENG = "Appearance Spin", PT = "Spin de Aparencia", rewardInstance = "5SpinVisualReward" },
	ClanSpin = { ENG = "Clan Spin", PT = "Spin de Cla", rewardInstance = "6SpinClanReward" },
	Playtime = { ENG = "Playtime: ", PT = "Tempo de Jogo: ", rewardInstance = "7TotalTime" },
	RewardPlaytime = { ENG = "Next Reward: ", PT = "Proxima Recompensa: ", rewardInstance = "8NextReward" },
	Points = { ENG = "Points: ", PT = "Pontos: ", rewardInstance = "9TotalPoints" },
}

Constants.RewardKeepVisible = {
	["1Title"] = true,
	["2Desc"] = true,
	UIListLayout = true,
	mobileProperties = true,
	badges = true,
}

Constants.ActionNames = {
	Standing = { ENG = "Standing", PT = "Parado" },
	Walking = { ENG = "Walking", PT = "Andando" },
	Jumping = { ENG = "Jumping", PT = "Pulando" },
	Sprinting = { ENG = "Sprinting", PT = "Correndo" },
	Falling = { ENG = "Falling", PT = "Caindo" },
	Dash = { ENG = "Dashing", PT = "Impulsionando" },
}

Constants.ActionColors = {
	Standing = Color3.fromRGB(255, 255, 255),
	Walking = Color3.fromRGB(0, 170, 255),
	Jumping = Color3.fromRGB(255, 224, 70),
	Sprinting = Color3.fromRGB(85, 255, 127),
	Falling = Color3.fromRGB(255, 140, 60),
	Dash = Color3.fromRGB(190, 120, 255),
}

Constants.ObjectivePool = { "Walking", "Sprinting", "Dash", "Jumping", "Falling" }

Constants.CategoryColors = {
	Fire = Color3.fromRGB(255, 157, 46),
	Wind = Color3.fromRGB(0, 255, 255),
	Earth = Color3.fromRGB(113, 62, 36),
	Water = Color3.fromRGB(0, 85, 255),
	Lightning = Color3.fromRGB(255, 255, 127),
	Genjutsu = Color3.fromRGB(110, 7, 255),
}

--//Source
return Constants
