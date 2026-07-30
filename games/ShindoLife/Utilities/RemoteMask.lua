--//Variables
local RemoteMask = {}
RemoteMask.__index = RemoteMask
local unpackValues = table.unpack or unpack

local FolderNames = {
	"combat",
	"tweenservice",
	"domain",
	"DefaultChatSystemChatEvents",
	"RPGMOB",
	"STORYMISSIONS",
	"elementfolder",
	"bosses",
	"STORAGE",
	"CUTSCENES",
	"alljutsu",
	"modes",
	"activation",
	"Gripsystem",
	"shipmain",
	"beserk",
	"bunnysummon",
	"body",
	"gates",
	"ship",
}

local RemoteNames = {
	"update",
	"effect",
	"animation",
	"fire",
	"RE",
	"RemoteEvent",
	"OnNewMessage",
	"OnMessageDoneFiltering",
	"OnNewSystemMessage",
	"OnChannelJoined",
	"OnChannelLeft",
	"OnMuted",
	"OnUnmuted",
	"OnMainChannelSet",
	"ChannelNameColorUpdated",
	"SayMessageRequest",
	"SetBlockedUserIdsRequest",
	"CLIENTTALK",
	"footstep",
	"find",
	"getanswer",
}

local PathTemplates = {
	{ "animation" },
	{ "effect" },
	{ "fire" },
	{ "tweenservice", "effect" },
	{ "combat", "update" },
	{ "domain", "RE" },
	{ "DefaultChatSystemChatEvents", "$chatEvent" },
	{ "RPGMOB", "$mob", "antiexploit", "RemoteEvent" },
	{ "RPGMOB", "$mob", "Gripsystem", "RemoteEvent" },
	{ "STORYMISSIONS", "Escort", "Gripsystem", "RemoteEvent" },
	{ "STORYMISSIONS", "cartmission", "combat", "update" },
	{ "elementfolder", "genjutsu", "domainforge", "RE" },
	{ "bosses", "$boss", "Gripsystem", "RemoteEvent" },
	{ "bosses", "$boss", "combat", "update" },
	{ "STORAGE", "$storage", "Gripsystem", "RemoteEvent" },
	{ "CHOOSE", "LocalScript", "charc", "combat", "update" },
	{ "alljutsu", "modes", "$tailMode", "beserk", "getanswer" },
	{ "alljutsu", "modes", "bunnysage", "bunnysummon", "CLIENTTALK" },
	{ "CUTSCENES", "shindaievent", "TAILBEASTAPPEAR", "$sceneBeast", "Gripsystem", "RemoteEvent" },
	{ "CUTSCENES", "shindaievent", "cutscenemodels", "$storage", "Gripsystem", "RemoteEvent" },
	{ "CUTSCENES", "forgedevent", "leafvillage", "Model", "missiongiver", "CLIENTTALK" },
	{ "CUTSCENES", "jinshikievent", "cutscenething", "$cutsceneCharacter", "combat", "update" },
	{ "alljutsu", "subjutsu", "halloweenskeleton", "skeleton", "Gripsystem", "RemoteEvent" },
	{ "alljutsu", "rinnegan", "pathsofpain", "$pathOfPain", "Gripsystem", "RemoteEvent" },
	{ "alljutsu", "modes", "$sageMode", "ToadSummon", "Gripsystem", "RemoteEvent" },
	{ "alljutsu", "qspecs", "bankaiinfernoespec", "BANKAISHADOW", "Gripsystem", "RemoteEvent" },
	{ "alljutsu", "$jutsu", "activation", "gates", "$bodyPart", "footstep" },
	{ "alljutsu", "$jutsu", "activation", "$summon", "shipmain", "ship", "find" },
	{ "alljutsu", "Acharacterpowers", "$arenaPower", "$summon", "shipmain", "ship", "find" },
	{ "alljutsu", "rinnegan", "paths", "animalpath", "shipmain", "ship", "find" },
	{ "saber", "powers", "inkart", "crow", "shipmain", "ship", "find" },
	{ "alljutsu", "companions", "$companion", "$companionUnit", "Gripsystem", "RemoteEvent" },
	{ "alljutsu", "$jutsu", "pathsofpain", "$pathOfPain", "Gripsystem", "RemoteEvent" },
	{ "alljutsu", "$jutsu", "$variant", "$summon", "shipmain", "ship", "find" },
}

local ChatEvents = {
	"OnNewMessage",
	"OnMessageDoneFiltering",
	"OnNewSystemMessage",
	"OnChannelJoined",
	"OnChannelLeft",
	"OnMuted",
	"OnUnmuted",
	"OnMainChannelSet",
	"ChannelNameColorUpdated",
	"SayMessageRequest",
	"SetBlockedUserIdsRequest",
}

local MobNames = {
	"skeleton",
	"GET",
}

local BossNames = {
	"tengokuDUNES",
	"tengokuEMBER",
	"tengokuHAZE",
	"tengokuNIMBUS",
	"tengokuOBELISK",
	"Santa",
	"Gyuki",
	"Isobu",
	"Kokuo",
	"Kurama",
	"Matabi",
	"Saiken",
	"Shukaku",
	"Son Goku",
	"Chomei",
	"tentails",
	"Hawk",
	"Bunneh",
	"Snakboss",
	"Toadboss",
	"gezomadosummon",
	"tentailsx",
	"Gyukix",
	"Saikenx",
	"Kuramayangx",
	"Chomeix",
	"Kokuox",
	"Son Gokux",
	"Kuramayinx",
	"Isobux",
	"Matabix",
	"Shukakux",
	"Witch",
	"Tree Spirit",
	"Gingerbread Chad",
	"Sengoku",
	"Sand Crawler",
	"Ken Mentor",
	"Hollow1",
	"Hollow2",
	"Hollow3",
	"Hollow4",
	"Hollow5",
	"Hollow6",
	"Hollow7",
	"Hollow8",
	"Hollow9",
	"TynV2",
}

local StorageNames = {
	"tentailsx",
	"zetsu",
	"snowman",
	"Samurai Spirit Boss",
	"Raion Spirit",
	"Satori Spirit",
	"Forged Spirit",
	"Bankai Spirit",
	"Riser Spirit",
	"tentails",
	"Shindai Spirit",
	"Shindai CLONE",
	"monkeyking",
	"odinsaberu",
	"GOLEMCLONE",
	"JOGOLEMCLONE",
	"SnakClone",
	"ToadClone",
	"MUDGOLEM",
	"gezomado",
	"Sarachia Spirit",
	"ShindaiRengokuCLONE",
	"ShindaiRengokuCLONEyang",
	"PClone",
	"ShindaiRamenCLONE",
	"NarumakiToad",
	"JayramakiToad",
	"SnakeSummon",
	"SlugSummon",
}

local TailModes = {
	"tail9",
	"tail1",
	"tail2",
	"tail3",
	"tail4",
	"tail5",
	"tail6",
	"tail7",
	"tail8",
	"rabbit",
	"tail9x2",
	"tail1x",
	"tail2x",
	"tail3x",
	"tail4x",
	"tail5x",
	"tail6x",
	"tail7x",
	"tail8x",
	"tail9x",
	"tentail",
	"tentailx",
}

local SceneBeasts = {
	"Kuramayinx",
	"Shukakux",
	"Matabix",
	"Isobux",
	"Son Gokux",
	"Kokuox",
	"Gyukix",
	"Saikenx",
	"Chomeix",
}

local CutsceneCharacters = {
	"Raion",
	"Narumaki",
}

local PathOfPainNames = {
	"human",
	"asura",
	"preta",
	"animal",
	"naraka",
}

local SageModes = {
	"toadsageV2REWORK",
	"toadsageREWORK",
	"snakesageREWORK",
	"slugsageREWORK",
}

local JutsuNames = {
	"renshiki",
	"aduritewood2",
	"renshikigold",
	"renshikiruby",
	"indraakuma",
	"indraakumapurple",
	"ashurashizen",
	"ashuraruby",
	"kamakiakuma",
	"kamakiakumainf",
	"koramaekg",
	"koramaekgskin",
	"narumakiruby",
	"subzeroice",
	"senjuwood",
	"kamizuru",
	"horsemankorashi",
	"forgedrengoku",
	"forgedsengoku",
	"dangan",
	"giovannishizen",
	"snakegreen",
	"snakewhite",
	"jotaroshizen",
	"narumaki",
	"narumakiyang",
	"jayramazure",
	"jayramaki",
	"toshiroice",
	"kagoku",
	"kagokuplatinum",
	"obirengoku",
	"batman",
	"sunknight",
	"thor",
	"thorshiver",
	"godshado",
	"satorigold",
	"clay",
	"shiromane",
	"shirogane",
	"rinnegan",
	"subjutsu",
}

local BodyParts = {
	"body",
	"body2",
	"kamakin3",
	"kamakin3old",
	"GolemCombat",
}

local Summons = {
	"Kurama2",
	"Kurama",
	"Shukaku",
	"Shukaku2",
	"Matabi",
	"Matabi2",
	"Isobu",
	"Isobu2",
	"Son Goku",
	"Son Goku2",
	"Kokuo",
	"Kokuo2",
	"Saiken",
	"Saiken2",
	"Chomei",
	"Chomei2",
	"Gyuki",
	"Gyuki2",
	"Toad",
	"Toad2",
	"Bunneh",
	"Bunneh2",
	"golem",
	"lizard",
	"bee",
	"horseman2",
	"horsey",
	"snakeultimate",
	"gedomazo",
	"tentails",
	"battyman",
	"frog",
	"toad",
	"crow",
	"inuzukagiant",
}

local ArenaPowers = {
	"forgedrengokuzspec",
	"kabucobragiantsnakecspec",
	"narumakicspecarena",
	"jayramakicspec",
	"Hashirama Mode",
	"Naruto  Mode",
	"Pain Mode",
	"SNAKE Mode",
}

local CompanionNames = {
	"devacomp",
	"forgedcomp",
	"shindairencomp",
}

local CompanionUnits = {
	"deva",
	"forged",
	"shindairengoku",
}

local VariantNames = {
	"activation",
	"beesummon",
	"claysummon",
	"teddybomb",
	"lizardpuppet",
	"paths",
}

local PayloadKinds = {
	"fx",
	"tick",
	"state",
	"step",
	"ack",
	"client",
}

--//Source
local function randomFrom(list, fallback)
	if type(list) ~= "table" or #list == 0 then
		return fallback
	end

	return list[math.random(1, #list)]
end

local function shallowCopy(source)
	local target = {}

	for index, value in ipairs(source or {}) do
		target[index] = value
	end

	return target
end

local function copyTemplateList(source)
	local target = {}

	for index, template in ipairs(source or {}) do
		if type(template) == "table" then
			target[index] = shallowCopy(template)
		end
	end

	return target
end

local function copyInto(target, source)
	for key, value in pairs(source or {}) do
		target[key] = value
	end

	return target
end

local function getEnvironment()
	return (getgenv and getgenv()) or _G
end

local function getHiddenGui()
	if type(gethui) ~= "function" then
		return nil
	end

	local success, hiddenGui = pcall(gethui)
	return success and hiddenGui or nil
end

local function safeDestroy(instance)
	if instance and instance.Parent then
		pcall(function()
			instance:Destroy()
		end)
	end
end

local function waitRandom(minValue, maxValue)
	if not task or type(task.wait) ~= "function" then
		return
	end

	minValue = tonumber(minValue) or 0
	maxValue = tonumber(maxValue) or minValue

	if maxValue < minValue then
		maxValue = minValue
	end

	if maxValue <= 0 then
		return
	end

	local minMs = math.floor(minValue * 1000)
	local maxMs = math.floor(maxValue * 1000)

	if maxMs < minMs then
		maxMs = minMs
	end

	task.wait(math.random(minMs, maxMs) / 1000)
end

function RemoteMask.new(app, config)
	local framework = app and app.Framework or Framework or {}
	local loaderConfig = framework.Config or {}

	config = copyInto(copyInto({}, config or {}), loaderConfig.RemoteMask)

	return setmetatable({
		App = app,
		Config = config,
		FolderNames = shallowCopy(config.FolderNames or FolderNames),
		RemoteNames = shallowCopy(config.RemoteNames or RemoteNames),
		PathTemplates = copyTemplateList(config.PathTemplates or PathTemplates),
		ChatEvents = shallowCopy(config.ChatEvents or ChatEvents),
		MobNames = shallowCopy(config.MobNames or MobNames),
		BossNames = shallowCopy(config.BossNames or BossNames),
		StorageNames = shallowCopy(config.StorageNames or StorageNames),
		TailModes = shallowCopy(config.TailModes or TailModes),
		SceneBeasts = shallowCopy(config.SceneBeasts or SceneBeasts),
		CutsceneCharacters = shallowCopy(config.CutsceneCharacters or CutsceneCharacters),
		PathOfPainNames = shallowCopy(config.PathOfPainNames or PathOfPainNames),
		SageModes = shallowCopy(config.SageModes or SageModes),
		JutsuNames = shallowCopy(config.JutsuNames or JutsuNames),
		BodyParts = shallowCopy(config.BodyParts or BodyParts),
		Summons = shallowCopy(config.Summons or Summons),
		ArenaPowers = shallowCopy(config.ArenaPowers or ArenaPowers),
		CompanionNames = shallowCopy(config.CompanionNames or CompanionNames),
		CompanionUnits = shallowCopy(config.CompanionUnits or CompanionUnits),
		VariantNames = shallowCopy(config.VariantNames or VariantNames),
		PayloadKinds = shallowCopy(config.PayloadKinds or PayloadKinds),
	}, RemoteMask)
end

function RemoteMask:IsDevelopment()
	local framework = self.App and self.App.Framework or Framework or {}
	local loaderConfig = framework.Config or {}
	local guardMode = tostring(loaderConfig.GuardMode or ""):lower()

	if loaderConfig.ReleaseGuard == true or guardMode == "release" then
		return false
	end

	if loaderConfig.DevGuard == true or guardMode == "dev" then
		return true
	end

	if framework.Bundled == true and tostring((framework.Build or {}).Signature or framework.ReleaseSignature or "") ~= "" then
		return false
	end

	local baseUrl = tostring(framework.BaseUrl or ""):lower()

	return loaderConfig.SourceMode == true
		or loaderConfig.Dev == true
		or loaderConfig.Development == true
		or baseUrl:find("127.0.0.1", 1, true) ~= nil
		or baseUrl:find("localhost", 1, true) ~= nil
		or baseUrl:find("0.0.0.0", 1, true) ~= nil
end

function RemoteMask:IsEnabled(options)
	options = options or {}

	if self.Config.Enabled == false or options.Enabled == false then
		return false
	end

	if self:IsDevelopment() and self.Config.InDev ~= true and options.InDev ~= true then
		return false
	end

	return true
end

function RemoteMask:GetRoot()
	local services = self.App and self.App.Services or {}
	local config = self.Config
	local rootMode = tostring(config.Root or "ReplicatedStorage")

	if rootMode == "HiddenGui" then
		return getHiddenGui() or services.LocalPlayer and services.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end

	if rootMode == "PlayerGui" then
		return services.LocalPlayer and services.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end

	if rootMode == "CoreGui" then
		local success, coreGui = pcall(function()
			return game:GetService("CoreGui")
		end)

		if success then
			return coreGui
		end
	end

	return services.ReplicatedStorage or game:GetService("ReplicatedStorage")
end

function RemoteMask:ResolvePathSegment(segment)
	segment = tostring(segment or "")

	if segment == "$chatEvent" then
		return randomFrom(self.ChatEvents, "OnNewMessage")
	end

	if segment == "$mob" then
		return randomFrom(self.MobNames, "skeleton")
	end

	if segment == "$boss" then
		return randomFrom(self.BossNames, "tengokuEMBER")
	end

	if segment == "$storage" then
		return randomFrom(self.StorageNames, "Shindai Spirit")
	end

	if segment == "$tailMode" then
		return randomFrom(self.TailModes, "tail9")
	end

	if segment == "$sceneBeast" then
		return randomFrom(self.SceneBeasts, "Kuramayinx")
	end

	if segment == "$cutsceneCharacter" then
		return randomFrom(self.CutsceneCharacters, "Raion")
	end

	if segment == "$pathOfPain" then
		return randomFrom(self.PathOfPainNames, "human")
	end

	if segment == "$sageMode" then
		return randomFrom(self.SageModes, "toadsageREWORK")
	end

	if segment == "$jutsu" then
		return randomFrom(self.JutsuNames, "renshiki")
	end

	if segment == "$bodyPart" then
		return randomFrom(self.BodyParts, "body")
	end

	if segment == "$summon" then
		return randomFrom(self.Summons, "Kurama2")
	end

	if segment == "$arenaPower" then
		return randomFrom(self.ArenaPowers, "narumakicspecarena")
	end

	if segment == "$companion" then
		return randomFrom(self.CompanionNames, "devacomp")
	end

	if segment == "$companionUnit" then
		return randomFrom(self.CompanionUnits, "deva")
	end

	if segment == "$variant" then
		return randomFrom(self.VariantNames, "activation")
	end

	return segment
end

function RemoteMask:PickTemplate()
	local template = randomFrom(self.PathTemplates)

	if type(template) ~= "table" or #template == 0 then
		return nil
	end

	return template
end

function RemoteMask:CreateDecoyRemote()
	local root = self:GetRoot()

	if not root then
		return nil
	end

	local template = self:PickTemplate()

	if template then
		if #template == 1 then
			local remote = Instance.new("RemoteEvent")
			remote.Name = self:ResolvePathSegment(template[1])
			remote.Parent = root

			return remote, remote
		end

		local topFolder = Instance.new("Folder")
		topFolder.Name = self:ResolvePathSegment(template[1])
		topFolder.Parent = root

		local parent = topFolder

		for index = 2, #template - 1 do
			local folder = Instance.new("Folder")
			folder.Name = self:ResolvePathSegment(template[index])
			folder.Parent = parent
			parent = folder
		end

		local remote = Instance.new("RemoteEvent")
		remote.Name = self:ResolvePathSegment(template[#template])
		remote.Parent = parent

		return remote, topFolder
	end

	local topFolder = Instance.new("Folder")
	topFolder.Name = randomFrom(self.FolderNames, "combat")
	topFolder.Parent = root

	local parent = topFolder
	local depth = math.random(1, tonumber(self.Config.MaxDepth) or 3)

	for _ = 1, depth do
		local folder = Instance.new("Folder")
		folder.Name = randomFrom(self.FolderNames, "activation")
		folder.Parent = parent
		parent = folder
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = randomFrom(self.RemoteNames, "RemoteEvent")
	remote.Parent = parent

	return remote, topFolder
end

function RemoteMask:CreatePayload()
	local kind = randomFrom(self.PayloadKinds)
	local now = math.floor(os.clock() * 1000)

	if kind == "fx" then
		return {
			"effect",
			math.random(1, 12),
			Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)),
		}
	end

	if kind == "state" then
		return {
			"state",
			{
				ready = true,
				t = now,
				id = math.random(1000, 9999),
			},
		}
	end

	if kind == "step" then
		return {
			"step",
			math.random(1, 6),
			now % 100,
		}
	end

	if kind == "ack" then
		return {
			"ack",
			tostring(math.random(100000, 999999)),
		}
	end

	if kind == "client" then
		local environment = getEnvironment()

		return {
			"client",
			environment.YCoreFramework and "ready" or "init",
			now,
		}
	end

	return {
		"tick",
		now,
	}
end

function RemoteMask:EmitOne()
	local remote, container = self:CreateDecoyRemote()

	if not remote then
		return false
	end

	local payload = self:CreatePayload()

	pcall(function()
		remote:FireServer(unpackValues(payload))
	end)

	safeDestroy(container)
	return true
end

function RemoteMask:EmitMany(count)
	count = math.max(0, tonumber(count) or 0)

	for _ = 1, count do
		self:EmitOne()

		if self.Config.DecoyJitter == true then
			waitRandom(self.Config.DecoyJitterMin, self.Config.DecoyJitterMax)
		end
	end
end

function RemoteMask:Run(callback, options)
	options = options or {}

	if not self:IsEnabled(options) then
		return pcall(callback)
	end

	local beforeMin = tonumber(options.BeforeMin or self.Config.BeforeMin) or 1
	local beforeMax = tonumber(options.BeforeMax or self.Config.BeforeMax) or beforeMin
	local afterMin = tonumber(options.AfterMin or self.Config.AfterMin) or 1
	local afterMax = tonumber(options.AfterMax or self.Config.AfterMax) or afterMin

	if beforeMax < beforeMin then
		beforeMax = beforeMin
	end

	if afterMax < afterMin then
		afterMax = afterMin
	end

	self:EmitMany(math.random(beforeMin, beforeMax))

	waitRandom(options.JitterMin or self.Config.JitterMin, options.JitterMax or self.Config.JitterMax)

	local success, result = pcall(callback)

	self:EmitMany(math.random(afterMin, afterMax))

	return success, result
end

return RemoteMask
