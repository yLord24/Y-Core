--//Variables
local UILib = {}

local DEFAULT_REPOSITORY = "https://raw.githubusercontent.com/yLord24/YLib/refs/heads/main/"
local DEFAULT_CACHE_FOLDER = "Y Hub/UILibCache"

--//Source
local function getEnvironment()
	return (getgenv and getgenv()) or _G
end

local function ensureSlash(text)
	text = tostring(text or "")

	if text:sub(-1) ~= "/" then
		text = text .. "/"
	end

	return text
end

local function ensureFolder(folderPath)
	if typeof(makefolder) ~= "function" then
		return
	end

	local currentPath = ""

	for folderName in tostring(folderPath or ""):gmatch("[^/\\]+") do
		currentPath = currentPath == "" and folderName or (currentPath .. "/" .. folderName)
		pcall(makefolder, currentPath)
	end
end

local function readCachedSource(cacheFolder, fileName)
	if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
		return nil
	end

	local filePath = tostring(cacheFolder or DEFAULT_CACHE_FOLDER) .. "/" .. tostring(fileName)
	local success, source = pcall(function()
		return isfile(filePath) and readfile(filePath) or nil
	end)

	if success and typeof(source) == "string" and #source > 64 then
		return source
	end

	return nil
end

local function writeCachedSource(cacheFolder, fileName, source)
	if typeof(writefile) ~= "function" or typeof(source) ~= "string" or #source <= 64 then
		return
	end

	cacheFolder = tostring(cacheFolder or DEFAULT_CACHE_FOLDER)
	ensureFolder(cacheFolder)
	pcall(writefile, cacheFolder .. "/" .. tostring(fileName), source)
end

function UILib.LoadAsset(globalName, fileName, config)
	local environment = getEnvironment()
	local cachedGlobal = environment[globalName]

	if cachedGlobal and not (globalName == "Library" and cachedGlobal.Unloaded == true) then
		return cachedGlobal
	end

	config = config or {}

	local repository = ensureSlash(config.Repository or DEFAULT_REPOSITORY)
	local cacheFolder = config.CacheFolder or DEFAULT_CACHE_FOLDER
	local source = readCachedSource(cacheFolder, fileName)

	if not source then
		source = game:HttpGet(repository .. tostring(fileName))
		writeCachedSource(cacheFolder, fileName, source)
	end

	local loadedChunk, loadError = loadstring(source, "@" .. tostring(fileName))
	assert(loadedChunk, loadError)

	local result = loadedChunk()
	environment[globalName] = result

	return result
end

function UILib.LoadStandard(config)
	return {
		Library = UILib.LoadAsset("Library", "Library.lua", config),
		ThemeManager = UILib.LoadAsset("ThemeManager", "ThemeManager.lua", config),
		SaveManager = UILib.LoadAsset("SaveManager", "SaveManager.lua", config),
	}
end

function UILib.SafeNotify(library, message, duration)
	if library and typeof(library.Notify) == "function" then
		pcall(function()
			library:Notify(tostring(message), duration or 3)
		end)
	end
end

return UILib
