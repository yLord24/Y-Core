--//Y Core Loader
-- Local: getgenv().YCoreLoaderConfig = { BaseUrl = "http://127.0.0.1:8124/", Game = "shinsei" }

--//Variables
local globalEnvironment = (getgenv and getgenv()) or _G
local loaderConfig = globalEnvironment.YCoreLoaderConfig or globalEnvironment.YAutoSignalLoaderConfig or {}
local baseEnvironment = (getfenv and getfenv()) or _G
local baseUrl = loaderConfig.BaseUrl or "http://127.0.0.1:8124/"
local verbose = loaderConfig.Verbose == true

if baseUrl:sub(-1) ~= "/" then
	baseUrl = baseUrl .. "/"
end

local Framework = {
	Name = "Y Core",
	Version = "0.1.0",
	BaseUrl = baseUrl,
	Cache = {},
	Config = loaderConfig,
	StartedAt = os.clock(),
}

globalEnvironment.YCoreFramework = Framework

--//Source
local function log(message)
	if verbose then
		print("[Y Core] " .. tostring(message))
	end
end

local function fail(message)
	warn("[Y Core] framework start failed: " .. tostring(message))
	return nil
end

local function cacheBust()
	if loaderConfig.CacheBust ~= nil then
		return tostring(loaderConfig.CacheBust)
	end

	return tostring(math.floor(os.clock() * 1000))
end

local function loadLua(source, chunkName)
	local loadedChunk, errorMessage = loadstring(source, chunkName)
	assert(loadedChunk, errorMessage)
	return loadedChunk
end

function Framework:Fetch(modulePath)
	modulePath = tostring(modulePath):gsub("^/", "")
	local moduleUrl = self.BaseUrl .. modulePath .. "?v=" .. cacheBust()
	log("fetch " .. moduleUrl)
	return game:HttpGet(moduleUrl)
end

function Framework:Require(modulePath, forceReload)
	modulePath = tostring(modulePath):gsub("^/", "")
	if not forceReload and self.Cache[modulePath] ~= nil then
		return self.Cache[modulePath]
	end

	local moduleSource = self:Fetch(modulePath)
	local loadedChunk = loadLua(moduleSource, "@" .. modulePath)

	local moduleEnv = setmetatable({
		Framework = self,
		Require = function(childModulePath, childForceReload)
			return self:Require(childModulePath, childForceReload)
		end,
	}, {
		__index = baseEnvironment,
	})

	if setfenv then
		setfenv(loadedChunk, moduleEnv)
	end

	local moduleResult = loadedChunk()
	if moduleResult == nil then
		moduleResult = true
	end

	self.Cache[modulePath] = moduleResult
	return moduleResult
end

function Framework:Start()
	--> Load selected game
	local startSuccess, startResult = pcall(function()
		local gameRegistry = self:Require("games/index.lua", self.Config.ForceReload == true)
		local selectedGameId = tostring(self.Config.Game or gameRegistry.Default or "shinsei"):lower()
		local gameInfo = gameRegistry.Games and gameRegistry.Games[selectedGameId]

		if type(gameInfo) ~= "table" then
			error("unknown game: " .. selectedGameId)
		end

		self.GameId = selectedGameId
		self.Game = gameInfo
		self.Name = gameInfo.Name or self.Name
		self.Version = tostring(gameInfo.Version or self.Version)

		local gameModule = self:Require(gameInfo.Entry or ("games/" .. selectedGameId .. "/init.lua"), self.Config.ForceReload == true)
		if type(gameModule) == "table" and type(gameModule.Start) == "function" then
			return gameModule.Start(self)
		end

		return gameModule
	end)

	if not startSuccess then
		return fail(startResult)
	end

	log("started " .. tostring(self.Name) .. " " .. tostring(self.Version))
	return startResult
end

return Framework:Start()
