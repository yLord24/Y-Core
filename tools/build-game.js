const fs = require("fs");
const path = require("path");

// Y Core game builder.
// Example: node tools/build-game.js --game shinsei

//--//Variables
const argumentList = process.argv.slice(2);
const rootIndex = argumentList.indexOf("--root");
const gameIndex = argumentList.indexOf("--game");
const entryIndex = argumentList.indexOf("--entry");
const outputIndex = argumentList.indexOf("--out");
const verbose = argumentList.includes("--verbose");

const projectRoot = rootIndex >= 0 ? path.resolve(argumentList[rootIndex + 1]) : path.resolve(__dirname, "..");
const selectedGameId = gameIndex >= 0 ? String(argumentList[gameIndex + 1]).toLowerCase() : "shinsei";
const registryPath = "games/index.lua";
const defaultEntryPath = `games/${selectedGameId}/init.lua`;
const selectedEntryPath = entryIndex >= 0 ? normalizeModulePath(argumentList[entryIndex + 1]) : findGameEntryPath(selectedGameId) || defaultEntryPath;
const outputPath = outputIndex >= 0 ? path.resolve(argumentList[outputIndex + 1]) : path.join(projectRoot, "builds", `${selectedGameId}.lua`);
const sourceByModulePath = new Map();

//--//Source
function log(message) {
	if (verbose) {
		console.log(`[YCore Builder] ${message}`);
	}
}

function fail(message) {
	console.error(`[YCore Builder] ${message}`);
	process.exit(1);
}

function normalizeModulePath(modulePath) {
	return String(modulePath || "")
		.replace(/\\/g, "/")
		.replace(/^\/+/, "");
}

function escapePattern(value) {
	return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function resolveModuleFile(modulePath) {
	const normalizedModulePath = normalizeModulePath(modulePath);
	const absolutePath = path.resolve(projectRoot, normalizedModulePath);
	const normalizedRoot = path.resolve(projectRoot);

	if (!absolutePath.startsWith(normalizedRoot)) {
		fail(`Invalid module path outside project: ${modulePath}`);
	}

	return absolutePath;
}

function readModule(modulePath) {
	const normalizedModulePath = normalizeModulePath(modulePath);
	const absolutePath = resolveModuleFile(normalizedModulePath);

	if (!fs.existsSync(absolutePath)) {
		fail(`Missing module: ${normalizedModulePath}`);
	}

	return fs.readFileSync(absolutePath, "utf8");
}

function findGameEntryPath(gameId) {
	const registrySource = fs.existsSync(resolveModuleFile(registryPath)) ? readModule(registryPath) : "";
	const gameBlockPattern = new RegExp(`${escapePattern(gameId)}\\s*=\\s*\\{([\\s\\S]*?)\\n\\s*\\},`, "m");
	const gameBlockMatch = registrySource.match(gameBlockPattern);

	if (!gameBlockMatch) {
		return null;
	}

	const entryMatch = gameBlockMatch[1].match(/Entry\s*=\s*["']([^"']+)["']/);
	return entryMatch ? normalizeModulePath(entryMatch[1]) : null;
}

function collectRequirePaths(source) {
	const requirePaths = [];
	const requirePattern = /Require\s*\(\s*["']([^"']+)["']/g;
	let requireMatch;

	while ((requireMatch = requirePattern.exec(source)) !== null) {
		requirePaths.push(normalizeModulePath(requireMatch[1]));
	}

	return requirePaths;
}

function walkLuaFiles(folderPath) {
	const absoluteFolderPath = path.resolve(projectRoot, folderPath);

	if (!fs.existsSync(absoluteFolderPath)) {
		return [];
	}

	const luaFiles = [];
	const directoryEntries = fs.readdirSync(absoluteFolderPath, { withFileTypes: true });

	for (const directoryEntry of directoryEntries) {
		const absoluteChildPath = path.join(absoluteFolderPath, directoryEntry.name);
		const relativeChildPath = normalizeModulePath(path.relative(projectRoot, absoluteChildPath));

		if (directoryEntry.isDirectory()) {
			luaFiles.push(...walkLuaFiles(relativeChildPath));
		} else if (directoryEntry.isFile() && path.extname(directoryEntry.name).toLowerCase() === ".lua") {
			luaFiles.push(relativeChildPath);
		}
	}

	return luaFiles.sort();
}

function collectModule(modulePath) {
	const normalizedModulePath = normalizeModulePath(modulePath);

	if (sourceByModulePath.has(normalizedModulePath)) {
		return;
	}

	log(`collect ${normalizedModulePath}`);

	const source = readModule(normalizedModulePath);
	const requirePaths = collectRequirePaths(source);

	sourceByModulePath.set(normalizedModulePath, source);

	for (const requiredModulePath of requirePaths) {
		collectModule(requiredModulePath);
	}
}

function collectSharedModules() {
	for (const sharedModulePath of walkLuaFiles("shared")) {
		collectModule(sharedModulePath);
	}
}

function collectGameModules(gameId) {
	const gameRootPath = `games/${gameId}`;
	const gameModulePaths = [
		`${gameRootPath}/config.lua`,
		`${gameRootPath}/init.lua`,
		...walkLuaFiles(`${gameRootPath}/Features`),
		...walkLuaFiles(`${gameRootPath}/Metadata`),
		...walkLuaFiles(`${gameRootPath}/Utilities`),
	];

	for (const gameModulePath of gameModulePaths) {
		if (fs.existsSync(resolveModuleFile(gameModulePath))) {
			collectModule(gameModulePath);
		}
	}
}

function createLuaString(source) {
	let equals = "";

	while (source.includes(`]${equals}]`)) {
		equals += "=";
	}

	return `[${equals}[${source}]${equals}]`;
}

function createLuaTableEntry(modulePath, source) {
	return `\t[${JSON.stringify(modulePath)}] = ${createLuaString(source)},`;
}

function createBundleSource() {
	const sortedModulePaths = Array.from(sourceByModulePath.keys()).sort();
	const bundledModules = sortedModulePaths.map((modulePath) => createLuaTableEntry(modulePath, sourceByModulePath.get(modulePath))).join("\n");
	const buildTime = new Date().toISOString();

	return `--//Y Core Bundle
-- Generated by tools/build-game.js
-- Game: ${selectedGameId}
-- BuiltAt: ${buildTime}

--//Variables
local globalEnvironment = (getgenv and getgenv()) or _G
local externalLoaderConfig = globalEnvironment.YCoreLoaderConfig or {}
local loaderConfig = {}
local baseEnvironment = (getfenv and getfenv()) or _G
local bundledSources = {
${bundledModules}
}

for configKey, configValue in pairs(externalLoaderConfig) do
\tloaderConfig[configKey] = configValue
end

loaderConfig.Game = "${selectedGameId}"
loaderConfig.Bundled = true

local Framework = {
\tName = "Y Core",
\tVersion = "0.1.0",
\tBaseUrl = "bundle://",
\tCache = {},
\tConfig = loaderConfig,
\tStartedAt = os.clock(),
\tBundled = true,
\tBuild = {
\t\tGame = "${selectedGameId}",
\t\tEntry = ${JSON.stringify(selectedEntryPath)},
\t\tBuiltAt = "${buildTime}",
\t\tModules = ${sortedModulePaths.length},
\t},
}

globalEnvironment.YCoreFramework = Framework

--//Source
local function log(message)
\tif loaderConfig.Verbose then
\t\tprint("[Y Core] " .. tostring(message))
\tend
end

local function fail(message)
\twarn("[Y Core] bundle start failed: " .. tostring(message))
\treturn nil
end

local function normalizeModulePath(modulePath)
\treturn tostring(modulePath):gsub("\\\\", "/"):gsub("^/+", "")
end

local function loadLua(source, chunkName)
\tlocal loadedChunk, errorMessage = loadstring(source, chunkName)
\tassert(loadedChunk, errorMessage)
\treturn loadedChunk
end

function Framework:Fetch(modulePath)
\tmodulePath = normalizeModulePath(modulePath)

\tlocal moduleSource = bundledSources[modulePath]
\tif moduleSource == nil then
\t\terror("missing bundled module: " .. tostring(modulePath))
\tend

\tlog("bundle fetch " .. modulePath)
\treturn moduleSource
end

function Framework:Require(modulePath, forceReload)
\tmodulePath = normalizeModulePath(modulePath)
\tif not forceReload and self.Cache[modulePath] ~= nil then
\t\treturn self.Cache[modulePath]
\tend

\tlocal moduleSource = self:Fetch(modulePath)
\tlocal loadedChunk = loadLua(moduleSource, "@" .. modulePath)

\tlocal moduleEnvironment = setmetatable({
\t\tFramework = self,
\t\tRequire = function(childModulePath, childForceReload)
\t\t\treturn self:Require(childModulePath, childForceReload)
\t\tend,
\t}, {
\t\t__index = baseEnvironment,
\t})

\tif setfenv then
\t\tsetfenv(loadedChunk, moduleEnvironment)
\tend

\tlocal moduleResult = loadedChunk()
\tif moduleResult == nil then
\t\tmoduleResult = true
\tend

\tself.Cache[modulePath] = moduleResult
\treturn moduleResult
end

function Framework:Start()
\t--> Load selected game
\tlocal startSuccess, startResult = pcall(function()
\t\tlocal gameRegistry = self:Require("${registryPath}", self.Config.ForceReload == true)
\t\tlocal selectedGameInfo = gameRegistry.Games and gameRegistry.Games["${selectedGameId}"]

\t\tif type(selectedGameInfo) ~= "table" then
\t\t\terror("unknown bundled game: ${selectedGameId}")
\t\tend

\t\tself.GameId = "${selectedGameId}"
\t\tself.Game = selectedGameInfo
\t\tself.Name = selectedGameInfo.Name or self.Name
\t\tself.Version = tostring(selectedGameInfo.Version or self.Version)

\t\tlocal gameModule = self:Require(selectedGameInfo.Entry or "${selectedEntryPath}", self.Config.ForceReload == true)
\t\tif type(gameModule) == "table" and type(gameModule.Start) == "function" then
\t\t\treturn gameModule.Start(self)
\t\tend

\t\treturn gameModule
\tend)

\tif not startSuccess then
\t\treturn fail(startResult)
\tend

\tlog("started " .. tostring(self.Name) .. " " .. tostring(self.Version))
\treturn startResult
end

return Framework:Start()
`;
}

function writeOutput(bundleSource) {
	fs.mkdirSync(path.dirname(outputPath), { recursive: true });
	fs.writeFileSync(outputPath, bundleSource, "utf8");
}

function printSummary() {
	console.log(`[YCore Builder] Game: ${selectedGameId}`);
	console.log(`[YCore Builder] Entry: ${selectedEntryPath}`);
	console.log(`[YCore Builder] Modules: ${sourceByModulePath.size}`);
	console.log(`[YCore Builder] Output: ${outputPath}`);
}

//--> Build
collectModule(registryPath);
collectSharedModules();
collectGameModules(selectedGameId);
collectModule(selectedEntryPath);
writeOutput(createBundleSource());
printSummary();
