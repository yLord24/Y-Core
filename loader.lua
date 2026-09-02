--//Y Hub Loader
-- Local dev: getgenv().YHubLoaderConfig = { BaseUrl = "http://127.0.0.1:8124/", Game = "shinsei", SourceMode = true, ForceReload = true }

--//Variables
local globalEnvironment = (getgenv and getgenv()) or _G
local loaderConfig = globalEnvironment.YHubLoaderConfig
	or globalEnvironment.YCoreLoaderConfig
	or globalEnvironment.YAutoSignalLoaderConfig
	or {}
local baseEnvironment = (getfenv and getfenv()) or _G
local baseUrl = loaderConfig.BaseUrl or "https://raw.githubusercontent.com/yLord24/Y-Core/main/"
local verbose = loaderConfig.Verbose == true
local automaticCacheBust = tostring(math.floor(os.clock() * 1000000))

local function identity(callback)
	return callback
end

globalEnvironment["LPH_NO_VIRTUALIZE"] = globalEnvironment["LPH_NO_VIRTUALIZE"] or identity
globalEnvironment["LPH_JIT"] = globalEnvironment["LPH_JIT"] or identity
globalEnvironment["LPH_JIT_MAX"] = globalEnvironment["LPH_JIT_MAX"] or identity
globalEnvironment["LPH_NO_UPVALUES"] = globalEnvironment["LPH_NO_UPVALUES"] or identity
baseEnvironment["LPH_NO_VIRTUALIZE"] = baseEnvironment["LPH_NO_VIRTUALIZE"] or globalEnvironment["LPH_NO_VIRTUALIZE"]
baseEnvironment["LPH_JIT"] = baseEnvironment["LPH_JIT"] or globalEnvironment["LPH_JIT"]
baseEnvironment["LPH_JIT_MAX"] = baseEnvironment["LPH_JIT_MAX"] or globalEnvironment["LPH_JIT_MAX"]
baseEnvironment["LPH_NO_UPVALUES"] = baseEnvironment["LPH_NO_UPVALUES"] or globalEnvironment["LPH_NO_UPVALUES"]

if baseUrl:sub(-1) ~= "/" then
	baseUrl = baseUrl .. "/"
end

local Framework = {
	Name = "Y Hub",
	Version = "0.1.0",
	BaseUrl = baseUrl,
	Cache = {},
	Config = loaderConfig,
	StartedAt = os.clock(),
}

globalEnvironment.YHubFramework = Framework
globalEnvironment.YCoreFramework = Framework

--//Source
local function log(message)
	if verbose then
		print("[Y Hub] " .. tostring(message))
	end
end

local function fail(message)
	if Framework.Release ~= true
		or loaderConfig.ReleaseDiagnostics == true
		or loaderConfig.BridgeReleaseDiagnostics == true
		or verbose
	then
		warn("[Y Hub] framework start failed: " .. tostring(message))
	end

	return nil
end

local function normalizeModulePath(modulePath)
	return tostring(modulePath or ""):gsub("\\", "/"):gsub("^/+", "")
end

local function cacheBust()
	if loaderConfig.CacheBust ~= nil then
		return tostring(loaderConfig.CacheBust)
	end

	return automaticCacheBust
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

local function loadBootstrapModule(modulePath)
	local moduleSource = Framework:Fetch(modulePath)
	local loadedChunk = loadLua(moduleSource, "@" .. modulePath)
	local moduleEnvironment = setmetatable({
		Framework = Framework,
		yrequire = function(childModulePath, childForceReload)
			return Framework:yrequire(childModulePath, childForceReload)
		end,
	}, {
		__index = baseEnvironment,
	})

	moduleEnvironment.Require = moduleEnvironment.yrequire
	return setChunkEnvironment(loadedChunk, moduleEnvironment)()
end

do
	local assertSuccess, assertModule = pcall(function()
		return loadBootstrapModule("shared/Framework/Assert.lua")
	end)

	if assertSuccess and type(assertModule) == "table" and type(assertModule.Attach) == "function" then
		assertModule.Attach(Framework)
	else
		warn("[Y Hub] Assert bootstrap failed: " .. tostring(assertModule))
	end
end

if type(Framework.ReportError) ~= "function" then
	function Framework:ReportError(stage, errorObject)
		return tostring(errorObject)
	end
end
if type(Framework.StartErrorWatcher) ~= "function" then
	function Framework:StartErrorWatcher()
		return false
	end
end

local function runWithErrorReport(framework, stage, details, callback)
	if framework and type(framework.RunWithErrorReport) == "function" then
		return framework:RunWithErrorReport(stage, details, callback)
	end

	local success, result = xpcall(callback, function(errorObject)
		return framework:ReportError(stage, errorObject, details)
	end)

	if not success then
		error(result, 0)
	end

	return result
end

function Framework:LoadUrl(url, chunkName)
	local resolvedChunkName = chunkName or ("@" .. tostring(url))
	local moduleSource = runWithErrorReport(self, "fetch-url", {
		url = url,
		chunk = resolvedChunkName,
	}, function()
		return self:FetchUrl(url)
	end)
	local loadedChunk = runWithErrorReport(self, "compile-url", {
		url = url,
		chunk = resolvedChunkName,
	}, function()
		return loadLua(moduleSource, resolvedChunkName)
	end)

	local moduleEnvironment = setmetatable({
		Framework = self,
		yrequire = function(childModulePath, childForceReload)
			return self:yrequire(childModulePath, childForceReload)
		end,
	}, {
		__index = baseEnvironment,
	})

	moduleEnvironment.Require = moduleEnvironment.yrequire

	return runWithErrorReport(self, "execute-url", {
		url = url,
		chunk = resolvedChunkName,
	}, function()
		return setChunkEnvironment(loadedChunk, moduleEnvironment)()
	end)
end

function Framework:yrequire(modulePath, forceReload)
	modulePath = normalizeModulePath(modulePath)
	if not forceReload and self.Cache[modulePath] ~= nil then
		return self.Cache[modulePath]
	end

	local moduleSource = runWithErrorReport(self, "fetch-module", {
		module = modulePath,
	}, function()
		return self:Fetch(modulePath)
	end)
	local loadedChunk = runWithErrorReport(self, "compile-module", {
		module = modulePath,
	}, function()
		return loadLua(moduleSource, "@" .. modulePath)
	end)

	local moduleEnvironment = setmetatable({
		Framework = self,
		yrequire = function(childModulePath, childForceReload)
			return self:yrequire(childModulePath, childForceReload)
		end,
	}, {
		__index = baseEnvironment,
	})

	moduleEnvironment.Require = moduleEnvironment.yrequire

	local moduleResult = runWithErrorReport(self, "execute-module", {
		module = modulePath,
	}, function()
		return setChunkEnvironment(loadedChunk, moduleEnvironment)()
	end)
	if moduleResult == nil then
		moduleResult = true
	end

	self.Cache[modulePath] = moduleResult
	return moduleResult
end

Framework.Require = Framework.yrequire

local function releaseDiagnosticsEnabled()
	return loaderConfig.ReleaseDiagnostics == true
		or loaderConfig.BridgeReleaseDiagnostics == true
		or loaderConfig.Verbose == true
end

if Framework.Release ~= true or releaseDiagnosticsEnabled() then
	Framework:StartErrorWatcher()
end

function Framework:Start()
	--> Load selected game
	local startSuccess, startResult = xpcall(function()
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
		local gameModule

		if sourceMode then
			local gameModulePath = gameInfo.Entry or ("games/" .. selectedGameId .. "/init.lua")
			gameModule = self:yrequire(gameModulePath, self.Config.ForceReload == true)
		else
			local bundleUrl = gameInfo.BundleUrl or gameInfo.BuildUrl or gameInfo.LoaderUrl

			if bundleUrl then
				gameModule = self:LoadUrl(bundleUrl, "@" .. selectedGameId .. ".bundle")
			elseif gameInfo.Loader then
				gameModule = self:yrequire(gameInfo.Loader, self.Config.ForceReload == true)
			else
				error("missing bundle url for game: " .. selectedGameId)
			end
		end

		if type(gameModule) == "table" and type(gameModule.Start) == "function" then
			return gameModule.Start(self)
		end

		return gameModule
	end, function(errorObject)
		return self:ReportError("framework-start", errorObject, {
			game = self.GameId or self.Config.Game or "auto",
		})
	end)

	if not startSuccess then
		return fail(startResult)
	end

	log("started " .. tostring(self.Name) .. " " .. tostring(self.Version))
	return startResult
end

return Framework:Start()
