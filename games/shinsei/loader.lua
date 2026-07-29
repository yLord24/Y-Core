--//Shinsei Compatibility Loader
-- Local: getgenv().YAutoSignalLoaderConfig = { BaseUrl = "http://127.0.0.1:8124/games/shinsei/" }

--//Variables
local globalEnvironment = (getgenv and getgenv()) or _G
local loaderConfig = globalEnvironment.YAutoSignalLoaderConfig or {}
local baseUrl = loaderConfig.BaseUrl or "http://127.0.0.1:8124/games/shinsei/"

--//Source
local function cacheBust()
	if loaderConfig.CacheBust ~= nil then
		return tostring(loaderConfig.CacheBust)
	end
	return tostring(math.floor(os.clock() * 1000))
end

if baseUrl:sub(-1) ~= "/" then
	baseUrl = baseUrl .. "/"
end

local rootBaseUrl = loaderConfig.RootBaseUrl or baseUrl:gsub("games/shinsei/?$", "")
if rootBaseUrl:sub(-1) ~= "/" then
	rootBaseUrl = rootBaseUrl .. "/"
end

globalEnvironment.YCoreLoaderConfig = {
	BaseUrl = rootBaseUrl,
	Game = "shinsei",
	Verbose = loaderConfig.Verbose,
	ForceReload = loaderConfig.ForceReload,
	CacheBust = loaderConfig.CacheBust,
}

return loadstring(game:HttpGet(rootBaseUrl .. "loader.lua?v=" .. cacheBust()), "@YCoreLoader")()
