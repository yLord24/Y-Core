--//Y Core Loader
-- Local dev: getgenv().YCoreLoaderConfig = { BaseUrl = "http://127.0.0.1:8124/", Game = "shinsei", SourceMode = true }

--//Variables
local globalEnvironment = (getgenv and getgenv()) or _G
local loaderConfig = globalEnvironment.YCoreLoaderConfig or globalEnvironment.YAutoSignalLoaderConfig or {}
local baseEnvironment = (getfenv and getfenv()) or _G
local baseUrl = loaderConfig.BaseUrl or "https://raw.githubusercontent.com/yLord24/Y-Core/main/"
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

local function normalizeModulePath(modulePath)
	return tostring(modulePath or ""):gsub("\\", "/"):gsub("^/+", "")
end

local function cacheBust()
	if loaderConfig.CacheBust ~= nil then
		return tostring(loaderConfig.CacheBust)
	end

	return tostring(math.floor(os.clock() * 1000))
end

local function withCacheBust(url)
	if loaderConfig.NoCacheBust == true then
		return url
	end

	local separator = string.find(url, "?", 1, true) and "&" or "?"
	return url .. separator .. "v=" .. cacheBust()
end

local function loadLua(source, chunkName)
	local loadedChunk, errorMessage = loadstring(source, chunkName)
	assert(loadedChunk, errorMessage)
	return loadedChunk
end

local function setChunkEnvironment(loadedChunk, moduleEnvironment)
	if setfenv then
		setfenv(loadedChunk, moduleEnvironment)
	end

	return loadedChunk
end

function Framework:Fetch(modulePath)
	modulePath = normalizeModulePath(modulePath)
	local moduleUrl = withCacheBust(self.BaseUrl .. modulePath)

	log("fetch " .. moduleUrl)
	return game:HttpGet(moduleUrl)
end

function Framework:FetchUrl(url)
	url = withCacheBust(tostring(url))

	log("fetch " .. url)
	return game:HttpGet(url)
end

function Framework:LoadUrl(url, chunkName)
	local moduleSource = self:FetchUrl(url)
	local loadedChunk = loadLua(moduleSource, chunkName or ("@" .. tostring(url)))

	local moduleEnvironment = setmetatable({
		Framework = self,
		yrequire = function(childModulePath, childForceReload)
			return self:yrequire(childModulePath, childForceReload)
		end,
	}, {
		__index = baseEnvironment,
	})

	moduleEnvironment.Require = moduleEnvironment.yrequire

	return setChunkEnvironment(loadedChunk, moduleEnvironment)()
end

function Framework:yrequire(modulePath, forceReload)
	modulePath = normalizeModulePath(modulePath)
	if not forceReload and self.Cache[modulePath] ~= nil then
		return self.Cache[modulePath]
	end

	local moduleSource = self:Fetch(modulePath)
	local loadedChunk = loadLua(moduleSource, "@" .. modulePath)

	local moduleEnvironment = setmetatable({
		Framework = self,
		yrequire = function(childModulePath, childForceReload)
			return self:yrequire(childModulePath, childForceReload)
		end,
	}, {
		__index = baseEnvironment,
	})

	moduleEnvironment.Require = moduleEnvironment.yrequire

	local moduleResult = setChunkEnvironment(loadedChunk, moduleEnvironment)()
	if moduleResult == nil then
		moduleResult = true
	end

	self.Cache[modulePath] = moduleResult
	return moduleResult
end

Framework.Require = Framework.yrequire

function Framework:Start()
	--> Load selected game
	local startSuccess, startResult = pcall(function()
		local gameRegistry = self:yrequire("games/index.lua", self.Config.ForceReload == true)
		local selectedGameId = self.Config.Game

		if selectedGameId == nil and type(gameRegistry.FindByPlaceId) == "function" then
			selectedGameId = gameRegistry.FindByPlaceId(game.PlaceId)
		end

		selectedGameId = tostring(selectedGameId or gameRegistry.Default or "shinsei"):lower()

		local gameInfo = nil
		if type(gameRegistry.GetGame) == "function" then
			gameInfo = gameRegistry.GetGame(selectedGameId)
		elseif type(gameRegistry.Games) == "table" then
			gameInfo = gameRegistry.Games[selectedGameId]
		end

		if type(gameInfo) ~= "table" then
			error("unknown game: " .. selectedGameId)
		end

		self.GameId = selectedGameId
		self.Game = gameInfo
		self.Name = gameInfo.Name or self.Name
		self.Version = tostring(gameInfo.Version or self.Version)

		local sourceMode = self.Config.SourceMode == true
		local gameModulePath = sourceMode and (gameInfo.Entry or ("games/" .. selectedGameId .. "/init.lua")) or (gameInfo.Loader or ("games/" .. selectedGameId .. "/loader.lua"))
		local gameModule = self:yrequire(gameModulePath, self.Config.ForceReload == true)

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
