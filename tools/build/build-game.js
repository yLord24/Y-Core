const fs = require("fs");
const path = require("path");

// Y Hub game builder.
// Example: node tools/build/build-game.js --game shinsei --release

//--//Variables
const argumentList = process.argv.slice(2);
const verbose = argumentList.includes("--verbose");
const fullBuild = argumentList.includes("--full");
const releaseBuildArgument = argumentList.includes("--release");
const stringModuleBuild = argumentList.includes("--string-modules");

const projectRoot = path.resolve(readArgumentValue("--root", path.resolve(__dirname, "../..")));
const selectedGameId = String(readArgumentValue("--game", "shinsei")).toLowerCase();
const selectedEntryPath = normalizeModulePath(readArgumentValue("--entry", findGameEntryPath(selectedGameId) || `games/${selectedGameId}/init.lua`));
const selectedGameRootPath = normalizeModulePath(path.dirname(selectedEntryPath));
const selectedManifestPath = normalizeModulePath(findGameFieldValue(selectedGameId, "Manifest") || ("games/" + selectedGameId + "/Metadatas/Manifest.lua"));
const publicBaseUrl = normalizeBaseUrl(readArgumentValue("--public-base-url", "https://raw.githubusercontent.com/yLord24/Y-Core/main/"));
const selectedBundleName = readArgumentValue("--bundle-name", findGameBundleName(selectedGameId) || `${selectedGameId}.luau`);
const outputPath = path.resolve(readArgumentValue("--out", path.join(projectRoot, "builds", releaseBuildArgument ? selectedBundleName : `${selectedGameId}.lua`)));
const releaseSignature = readArgumentValue("--release-signature", selectedGameId === "shindolife" ? "YHUB_SHINDOLIFE_RELEASE_GUARD_V1" : "");
const releaseBuild = releaseBuildArgument || path.extname(outputPath).toLowerCase() === ".luau";
const nativeModuleBuild = !stringModuleBuild && (
	argumentList.includes("--native-modules")
	|| releaseBuild
	|| findLuaBooleanField(selectedManifestPath, "LuarmorNativeModules")
);
const requestedExternalPrefixList = readArgumentValues("--external-prefix").map(normalizeModulePrefix);
const externalPrefixList = fullBuild || releaseBuild ? [] : (requestedExternalPrefixList.length > 0 ? requestedExternalPrefixList : ["shared/"]);

const sourceByModulePath = new Map();
const externalModulePathSet = new Set();
const ignoredGameFileSet = new Set([
	`${selectedGameRootPath}/loader.lua`,
	`${selectedGameRootPath}/test.lua`,
]);
const ignoredGameDirectorySet = new Set([
	`${selectedGameRootPath}/Experiments`,
	`${selectedGameRootPath}/Tests`,
]);

//--//Source
function readArgumentValue(argumentName, fallbackValue) {
	const argumentIndex = argumentList.indexOf(argumentName);

	if (argumentIndex < 0 || argumentIndex + 1 >= argumentList.length) {
		return fallbackValue;
	}

	return argumentList[argumentIndex + 1];
}

function readArgumentValues(argumentName) {
	const argumentValues = [];

	for (let argumentIndex = 0; argumentIndex < argumentList.length; argumentIndex += 1) {
		if (argumentList[argumentIndex] === argumentName && argumentIndex + 1 < argumentList.length) {
			argumentValues.push(argumentList[argumentIndex + 1]);
			argumentIndex += 1;
		}
	}

	return argumentValues;
}

function log(message) {
	if (verbose) {
		console.log(`[Y Hub Builder] ${message}`);
	}
}

function fail(message) {
	console.error(`[Y Hub Builder] ${message}`);
	process.exit(1);
}

function normalizeModulePath(modulePath) {
	return String(modulePath || "")
		.replace(/\\/g, "/")
		.replace(/^\/+/, "");
}

function normalizeModulePrefix(modulePrefix) {
	const normalizedModulePrefix = normalizeModulePath(modulePrefix);
	return normalizedModulePrefix.endsWith("/") ? normalizedModulePrefix : `${normalizedModulePrefix}/`;
}

function normalizeBaseUrl(baseUrl) {
	const normalizedBaseUrl = String(baseUrl || "");
	return normalizedBaseUrl.endsWith("/") ? normalizedBaseUrl : `${normalizedBaseUrl}/`;
}

function escapePattern(value) {
	return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function resolveModuleFile(modulePath) {
	const normalizedModulePath = normalizeModulePath(modulePath);
	const absolutePath = path.resolve(projectRoot, normalizedModulePath);
	const relativePath = path.relative(projectRoot, absolutePath);

	if (relativePath.startsWith("..") || path.isAbsolute(relativePath)) {
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

function findGameBlock(gameId) {
	const registryPath = "games/index.lua";
	const registryAbsolutePath = path.resolve(projectRoot, registryPath);

	if (!fs.existsSync(registryAbsolutePath)) {
		return null;
	}

	const registrySource = fs.readFileSync(registryAbsolutePath, "utf8");
	const gameBlockPattern = new RegExp(`${escapePattern(gameId)}\\s*=\\s*\\{([\\s\\S]*?)\\n\\s*\\},`, "m");
	const gameBlockMatch = registrySource.match(gameBlockPattern);

	if (!gameBlockMatch) {
		return null;
	}

	return gameBlockMatch[1];
}

function findGameFieldValue(gameId, fieldName) {
	const gameBlock = findGameBlock(gameId);

	if (!gameBlock) {
		return null;
	}

	const fieldPattern = new RegExp(`${escapePattern(fieldName)}\\s*=\\s*["']([^"']+)["']`);
	const fieldMatch = gameBlock.match(fieldPattern);

	return fieldMatch ? fieldMatch[1] : null;
}

function findGameEntryPath(gameId) {
	const entryValue = findGameFieldValue(gameId, "Entry");
	return entryValue ? normalizeModulePath(entryValue) : null;
}

function findGameBundleName(gameId) {
	const bundleUrl = findGameFieldValue(gameId, "BundleUrl")
		|| findGameFieldValue(gameId, "BuildUrl")
		|| findGameFieldValue(gameId, "LoaderUrl");

	if (!bundleUrl) {
		return null;
	}

	try {
		const parsedUrl = new URL(bundleUrl);
		return path.basename(parsedUrl.pathname);
	} catch {
		return path.basename(bundleUrl.replace(/\\/g, "/"));
	}
}

function findLuaBooleanField(modulePath, fieldName) {
	const absolutePath = resolveModuleFile(modulePath);

	if (!fs.existsSync(absolutePath)) {
		return false;
	}

	const moduleSource = fs.readFileSync(absolutePath, "utf8");
	const fieldPattern = new RegExp(escapePattern(fieldName) + "\\s*=\\s*(true|false)\\b", "i");
	const fieldMatch = moduleSource.match(fieldPattern);

	return fieldMatch ? fieldMatch[1].toLowerCase() === "true" : false;
}

function collectRequirePaths(source) {
	const requirePaths = [];
	const requirePattern = /(?:yrequire|Require)\s*\(\s*["']([^"']+)["']/g;
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
			if (ignoredGameDirectorySet.has(relativeChildPath)) {
				log(`ignore directory ${relativeChildPath}`);
				continue;
			}
			luaFiles.push(...walkLuaFiles(relativeChildPath));
		} else if (directoryEntry.isFile() && path.extname(directoryEntry.name).toLowerCase() === ".lua") {
			luaFiles.push(relativeChildPath);
		}
	}

	return luaFiles.sort();
}

function shouldExternalize(modulePath) {
	const normalizedModulePath = normalizeModulePath(modulePath);
	return externalPrefixList.some((externalPrefix) => normalizedModulePath.startsWith(externalPrefix));
}

function validateExternalModule(modulePath) {
	const normalizedModulePath = normalizeModulePath(modulePath);

	if (externalModulePathSet.has(normalizedModulePath)) {
		return;
	}

	if (!fs.existsSync(resolveModuleFile(normalizedModulePath))) {
		fail(`Missing external module: ${normalizedModulePath}`);
	}

	log(`external ${normalizedModulePath}`);
	externalModulePathSet.add(normalizedModulePath);
}

function collectModule(modulePath) {
	const normalizedModulePath = normalizeModulePath(modulePath);

	if (sourceByModulePath.has(normalizedModulePath)) {
		return;
	}

	if (shouldExternalize(normalizedModulePath)) {
		validateExternalModule(normalizedModulePath);
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

function collectGameModules() {
	const gameModulePaths = walkLuaFiles(selectedGameRootPath).filter((gameModulePath) => {
		return !ignoredGameFileSet.has(gameModulePath);
	});

	for (const gameModulePath of gameModulePaths) {
		collectModule(gameModulePath);
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
	if (nativeModuleBuild) {
		return `\t[${JSON.stringify(modulePath)}] = function()\n${source}\n\tend,`;
	}

	return `\t[${JSON.stringify(modulePath)}] = ${createLuaString(source)},`;
}

function createBundleSource() {
	const sortedModulePaths = Array.from(sourceByModulePath.keys()).sort();
	const sortedExternalModulePaths = Array.from(externalModulePathSet.keys()).sort();
	const bundledModules = sortedModulePaths.map((modulePath) => createLuaTableEntry(modulePath, sourceByModulePath.get(modulePath))).join("\n");
	const externalPrefixes = externalPrefixList.map((modulePrefix) => `\t${JSON.stringify(modulePrefix)},`).join("\n");
	const buildTime = new Date().toISOString();

	return `--//Y Hub Game Bundle
-- Generated by tools/build/build-game.js
-- Game: ${selectedGameId}
-- BuiltAt: ${buildTime}
-- BundleName: ${selectedBundleName}
-- Signature: ${releaseSignature}
-- NativeModules: ${nativeModuleBuild}

--//Variables
local globalEnvironment = (getgenv and getgenv()) or _G
local baseEnvironment = (getfenv and getfenv()) or _G

local parentFramework = Framework or globalEnvironment.YHubFramework or globalEnvironment.YCoreFramework
local externalLoaderConfig = globalEnvironment.YHubLoaderConfig or globalEnvironment.YCoreLoaderConfig or {}
local loaderConfig = {}
local bundledModules = {
${bundledModules}
}
local externalPrefixes = {
${externalPrefixes}
}

if type(parentFramework) == "table" and type(parentFramework.Config) == "table" then
\tfor configKey, configValue in pairs(parentFramework.Config) do
\t\tloaderConfig[configKey] = configValue
\tend
end

for configKey, configValue in pairs(externalLoaderConfig) do
\tloaderConfig[configKey] = configValue
end

loaderConfig.Game = "${selectedGameId}"
loaderConfig.Bundled = true

local Framework = parentFramework or {
\tName = "Y Hub",
\tVersion = "0.1.0",
\tBaseUrl = loaderConfig.BaseUrl or "${publicBaseUrl}",
\tCache = {},
\tConfig = loaderConfig,
\tStartedAt = os.clock(),
}

Framework.Name = Framework.Name or "Y Hub"
Framework.Version = tostring(Framework.Version or "0.1.0")
Framework.BaseUrl = Framework.BaseUrl or loaderConfig.BaseUrl or "${publicBaseUrl}"
Framework.Cache = Framework.Cache or {}
Framework.Config = loaderConfig
Framework.Bundled = true
Framework.NativeModules = ${nativeModuleBuild}
Framework.ReleaseSignature = ${JSON.stringify(releaseSignature)}
Framework.GameId = "${selectedGameId}"
Framework.Build = {
\tGame = "${selectedGameId}",
\tEntry = ${JSON.stringify(selectedEntryPath)},
\tBundleName = ${JSON.stringify(selectedBundleName)},
\tSignature = ${JSON.stringify(releaseSignature)},
\tBuiltAt = "${buildTime}",
\tModules = ${sortedModulePaths.length},
\tNativeModules = ${nativeModuleBuild},
\tExternalModules = ${sortedExternalModulePaths.length},
}

for bundledModulePath in pairs(bundledModules) do
\tFramework.Cache[bundledModulePath] = nil
end

if Framework.BaseUrl:sub(-1) ~= "/" then
\tFramework.BaseUrl = Framework.BaseUrl .. "/"
end

globalEnvironment.YHubFramework = Framework
globalEnvironment.YCoreFramework = Framework

--//Source
local function log(message)
\tif loaderConfig.Verbose then
\t\tprint("[Y Hub] " .. tostring(message))
\tend
end

local function fail(message)
\twarn("[Y Hub] bundle start failed: " .. tostring(message))
\treturn nil
end

local function normalizeModulePath(modulePath)
\treturn tostring(modulePath or ""):gsub("\\\\", "/"):gsub("^/+", "")
end

local function cacheBust()
\tif loaderConfig.CacheBust ~= nil then
\t\treturn tostring(loaderConfig.CacheBust)
\tend

\treturn tostring(math.floor(os.clock() * 1000))
end

local function withCacheBust(url)
\tif loaderConfig.NoCacheBust == true then
\t\treturn url
\tend

\tlocal separator = string.find(url, "?", 1, true) and "&" or "?"
\treturn url .. separator .. "v=" .. cacheBust()
end

local function loadLua(source, chunkName)
\tlocal loadedChunk, errorMessage = loadstring(source, chunkName)
\tassert(loadedChunk, errorMessage)
\treturn loadedChunk
end

local function isExternalModule(modulePath)
\tmodulePath = normalizeModulePath(modulePath)

\tfor _, externalPrefix in ipairs(externalPrefixes) do
\t\tif modulePath:sub(1, #externalPrefix) == externalPrefix then
\t\t\treturn true
\t\tend
\tend

\treturn false
end

local function setChunkEnvironment(loadedChunk, moduleEnvironment)
\tif setfenv then
\t\tsetfenv(loadedChunk, moduleEnvironment)
\tend

\treturn loadedChunk
end

function Framework:Fetch(modulePath)
\tmodulePath = normalizeModulePath(modulePath)

\tlocal bundledModule = bundledModules[modulePath]
\tif bundledModule ~= nil then
\t\tlog("bundle fetch " .. modulePath)
\t\treturn bundledModule
\tend

\tif isExternalModule(modulePath) then
\t\tlocal moduleUrl = withCacheBust((self.BaseUrl or "${publicBaseUrl}") .. modulePath)
\t\tlog("external fetch " .. moduleUrl)
\t\treturn game:HttpGet(moduleUrl)
\tend

\terror("missing bundled module: " .. tostring(modulePath))
end

function Framework:FetchUrl(url)
\turl = withCacheBust(tostring(url))

\tlog("fetch " .. url)
\treturn game:HttpGet(url)
end

local function loadBootstrapModule(modulePath)
\tlocal moduleContent = Framework:Fetch(modulePath)
\tlocal loadedChunk

\tif type(moduleContent) == "function" then
\t\tloadedChunk = moduleContent
\telse
\t\tloadedChunk = loadLua(moduleContent, "@" .. modulePath)
\tend

\tlocal moduleEnvironment = setmetatable({
\t\tFramework = Framework,
\t\tyrequire = function(childModulePath, childForceReload)
\t\t\treturn Framework:yrequire(childModulePath, childForceReload)
\t\tend,
\t}, {
\t\t__index = baseEnvironment,
\t})

\tmoduleEnvironment.Require = moduleEnvironment.yrequire
\treturn setChunkEnvironment(loadedChunk, moduleEnvironment)()
end

do
\tlocal assertSuccess, assertModule = pcall(function()
\t\treturn loadBootstrapModule("shared/Framework/Assert.lua")
\tend)

\tif assertSuccess and type(assertModule) == "table" and type(assertModule.Attach) == "function" then
\t\tassertModule.Attach(Framework)
\telse
\t\twarn("[Y Hub] Assert bootstrap failed: " .. tostring(assertModule))
\tend
end

if type(Framework.ReportError) ~= "function" then
\tfunction Framework:ReportError(stage, errorObject)
\t\treturn tostring(errorObject)
\tend
end
if type(Framework.StartErrorWatcher) ~= "function" then
\tfunction Framework:StartErrorWatcher()
\t\treturn false
\tend
end

local function runWithErrorReport(framework, stage, details, callback)
\tif framework and type(framework.RunWithErrorReport) == "function" then
\t\treturn framework:RunWithErrorReport(stage, details, callback)
\tend

\tlocal success, result = xpcall(callback, function(errorObject)
\t\treturn framework:ReportError(stage, errorObject, details)
\tend)

\tif not success then
\t\terror(result, 0)
\tend

\treturn result
end

function Framework:LoadUrl(url, chunkName)
\tlocal resolvedChunkName = chunkName or ("@" .. tostring(url))
\tlocal moduleSource = runWithErrorReport(self, "fetch-url", {
\t\turl = url,
\t\tchunk = resolvedChunkName,
\t}, function()
\t\treturn self:FetchUrl(url)
\tend)
\tlocal loadedChunk = runWithErrorReport(self, "compile-url", {
\t\turl = url,
\t\tchunk = resolvedChunkName,
\t}, function()
\t\treturn loadLua(moduleSource, resolvedChunkName)
\tend)

\tlocal moduleEnvironment = setmetatable({
\t\tFramework = self,
\t\tyrequire = function(childModulePath, childForceReload)
\t\t\treturn self:yrequire(childModulePath, childForceReload)
\t\tend,
\t}, {
\t\t__index = baseEnvironment,
\t})

\tmoduleEnvironment.Require = moduleEnvironment.yrequire

\treturn runWithErrorReport(self, "execute-url", {
\t\turl = url,
\t\tchunk = resolvedChunkName,
\t}, function()
\t\treturn setChunkEnvironment(loadedChunk, moduleEnvironment)()
\tend)
end

function Framework:yrequire(modulePath, forceReload)
\tmodulePath = normalizeModulePath(modulePath)
\tif not forceReload and self.Cache[modulePath] ~= nil then
\t\treturn self.Cache[modulePath]
\tend

\tlocal moduleContent = runWithErrorReport(self, "fetch-module", {
\t\tmodule = modulePath,
\t}, function()
\t\treturn self:Fetch(modulePath)
\tend)
\tlocal loadedChunk

\tloadedChunk = runWithErrorReport(self, "compile-module", {
\t\tmodule = modulePath,
\t}, function()
\t\tif type(moduleContent) == "function" then
\t\t\treturn moduleContent
\t\tend

\t\treturn loadLua(moduleContent, "@" .. modulePath)
\tend)

\tlocal moduleEnvironment = setmetatable({
\t\tFramework = self,
\t\tyrequire = function(childModulePath, childForceReload)
\t\t\treturn self:yrequire(childModulePath, childForceReload)
\t\tend,
\t}, {
\t\t__index = baseEnvironment,
\t})

\tmoduleEnvironment.Require = moduleEnvironment.yrequire

\tlocal moduleResult = runWithErrorReport(self, "execute-module", {
\t\tmodule = modulePath,
\t}, function()
\t\treturn setChunkEnvironment(loadedChunk, moduleEnvironment)()
\tend)
\tif moduleResult == nil then
\t\tmoduleResult = true
\tend

\tself.Cache[modulePath] = moduleResult
\treturn moduleResult
end

Framework.Require = Framework.yrequire
Framework:StartErrorWatcher()

function Framework:StartBundledGame()
\tlocal startSuccess, startResult = xpcall(function()
\t\tlocal gameModule = self:yrequire(${JSON.stringify(selectedEntryPath)}, self.Config.ForceReload == true)

\t\tif type(gameModule) == "table" and type(gameModule.Start) == "function" then
\t\t\treturn gameModule.Start(self)
\t\tend

\t\treturn gameModule
\tend, function(errorObject)
\t\treturn self:ReportError("bundled-game-start", errorObject, {
\t\t\tgame = "${selectedGameId}",
\t\t\tentry = ${JSON.stringify(selectedEntryPath)},
\t\t})
\tend)

\tif not startSuccess then
\t\treturn fail(startResult)
\tend

\tlog("started bundled ${selectedGameId}")
\treturn startResult
end

return Framework:StartBundledGame()
`;
}

function writeOutput(bundleSource) {
	fs.mkdirSync(path.dirname(outputPath), { recursive: true });
	fs.writeFileSync(outputPath, bundleSource, "utf8");
}

function printSummary() {
	console.log(`[Y Hub Builder] Game: ${selectedGameId}`);
	console.log(`[Y Hub Builder] Entry: ${selectedEntryPath}`);
	console.log(`[Y Hub Builder] BundleName: ${selectedBundleName}`);
	console.log(`[Y Hub Builder] Signature: ${releaseSignature || "none"}`);
	console.log(`[Y Hub Builder] Release: ${releaseBuild || fullBuild ? "yes" : "no"}`);
	console.log(`[Y Hub Builder] NativeModules: ${nativeModuleBuild ? "yes" : "no"}`);
	console.log(`[Y Hub Builder] Modules: ${sourceByModulePath.size}`);
	console.log(`[Y Hub Builder] ExternalPrefixes: ${externalPrefixList.length > 0 ? externalPrefixList.join(", ") : "none"}`);
	console.log(`[Y Hub Builder] ExternalModules: ${externalModulePathSet.size}`);
	console.log(`[Y Hub Builder] Output: ${outputPath}`);
}

//--> Build
collectGameModules();
collectModule("shared/Framework/Assert.lua");
collectModule(selectedEntryPath);
writeOutput(createBundleSource());
printSummary();
