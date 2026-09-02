--//Variables
local Assert = {}
local REPORT_MARKER = "[YHubErrorReported]"
local LEGACY_REPORT_MARKER = "[YCoreErrorReported]"
local DEFAULT_ERROR_FOLDER = "Y Hub/Errors"
local MAX_ERROR_LOG_BYTES = 768 * 1024
local DEFAULT_LOGSERVICE_DEDUP_SECONDS = 120

local EXTERNAL_LOG_NOISE_PATTERNS = {
	"failed to load materialservice.",
	"failed to load sound rbxassetid://",
	"remote event invocation queue exhausted for replicatedstorage.remotes.server",
	"user is not authorized to access asset",
}

--//Source
local function isReleaseFramework(framework)
	if framework and framework.Release == true then
		return true
	end

	local build = framework and framework.Build
	return type(build) == "table" and build.Release == true
end

local function releaseDiagnosticsEnabled(framework)
	local config = framework and framework.Config or {}
	return config.ReleaseDiagnostics == true
		or config.BridgeReleaseDiagnostics == true
		or config.Verbose == true
end

function Assert.SafeString(value)
	local success, result = pcall(function()
		return tostring(value)
	end)

	return success and result or "<unprintable>"
end

function Assert.SafeFileName(value)
	value = Assert.SafeString(value):gsub("[^%w_%-%.]+", "_")
	return value ~= "" and value or "unknown"
end

function Assert.IsExternalLogNoise(message)
	local lowerMessage = Assert.SafeString(message):lower()
	for _, pattern in ipairs(EXTERNAL_LOG_NOISE_PATTERNS) do
		if lowerMessage:find(pattern, 1, true) then
			return true
		end
	end

	return false
end

function Assert.EnsureFolderTree(folderPath)
	if typeof(makefolder) ~= "function" then
		return
	end

	local currentPath = ""
	for folderName in Assert.SafeString(folderPath):gmatch("[^/\\]+") do
		currentPath = currentPath == "" and folderName or (currentPath .. "/" .. folderName)
		pcall(makefolder, currentPath)
	end
end

function Assert.FormatDetails(details)
	local fields = {}

	if type(details) == "table" then
		for key, value in pairs(details) do
			fields[#fields + 1] = Assert.SafeString(key) .. "=" .. Assert.SafeString(value)
		end
	end

	table.sort(fields)
	return table.concat(fields, " ")
end

function Assert.Traceback(errorObject, stackLevel)
	local message = Assert.SafeString(errorObject)

	if type(debug) == "table" and type(debug.traceback) == "function" then
		local success, trace = pcall(debug.traceback, message, stackLevel or 3)
		if success and type(trace) == "string" then
			return trace
		end
	end

	return message
end

function Assert.AppendFile(path, text, maxBytes)
	if typeof(writefile) ~= "function" then
		return false
	end

	local success = false
	if typeof(appendfile) == "function" then
		success = pcall(function()
			appendfile(path, text)
		end)
		if success then
			return true
		end
	end

	local existing = ""
	if typeof(readfile) == "function" then
		pcall(function()
			existing = readfile(path)
		end)
	end

	local combined = existing .. text
	local limit = tonumber(maxBytes) or MAX_ERROR_LOG_BYTES
	if limit > 0 and #combined > limit then
		combined = combined:sub(#combined - limit + 1)
	end

	return pcall(function()
		writefile(path, combined)
	end)
end

function Assert.WriteErrorFile(config, gameId, entry)
	if typeof(writefile) ~= "function" then
		return false
	end

	local folderPath = Assert.SafeString((config and config.ErrorFolder) or DEFAULT_ERROR_FOLDER)
	local gamePath = folderPath .. "/" .. Assert.SafeFileName(gameId) .. ".log"
	local historyPath = folderPath .. "/History.log"
	local latestPath = folderPath .. "/LatestError.log"

	Assert.EnsureFolderTree(folderPath)

	Assert.AppendFile(gamePath, entry .. "\n\n", MAX_ERROR_LOG_BYTES)
	Assert.AppendFile(historyPath, entry .. "\n\n", MAX_ERROR_LOG_BYTES)

	pcall(function()
		writefile(latestPath, entry .. "\n")
	end)

	return true
end

function Assert.ShouldReport(framework, stage, errorText, details)
	if not framework then
		return true
	end

	local config = framework.Config or {}
	local cooldown = tonumber(config.ErrorDedupSeconds or 8) or 8
	local key = table.concat({
		Assert.SafeString(stage),
		Assert.FormatDetails(details),
		Assert.SafeString(errorText),
	}, "\n")

	framework.ErrorReportCache = framework.ErrorReportCache or {}
	local now = os.clock()
	local cached = framework.ErrorReportCache[key]

	if cached and now - (cached.LastAt or 0) < cooldown then
		cached.Count = (cached.Count or 1) + 1
		cached.LastAt = now
		return false, cached.Count
	end

	framework.ErrorReportCache[key] = {
		LastAt = now,
		Count = 1,
	}

	return true, 1
end

function Assert.Report(framework, stage, errorObject, details)
	local errorText = Assert.SafeString(errorObject)
	if errorText:find(REPORT_MARKER, 1, true) or errorText:find(LEGACY_REPORT_MARKER, 1, true) then
		return errorText
	end

	local shouldReport, duplicateCount = Assert.ShouldReport(framework, stage, errorText, details)
	if not shouldReport then
		return REPORT_MARKER .. "\nDuplicate suppressed: " .. Assert.SafeString(duplicateCount)
	end

	local config = (framework and framework.Config) or {}
	local quietRelease = isReleaseFramework(framework) and not releaseDiagnosticsEnabled(framework)
	if quietRelease then
		return REPORT_MARKER
	end

	local gameId = Assert.SafeString((framework and (framework.GameId or (framework.Config and framework.Config.Game))) or "unknown")
	local trace = Assert.Traceback(errorObject, 3)
	local entry = table.concat({
		"=== Y Hub Error ===",
		"Time: " .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
		"Game: " .. gameId,
		"PlaceId: " .. Assert.SafeString(game and game.PlaceId or "unknown"),
		"JobId: " .. Assert.SafeString(game and game.JobId or "unknown"),
		"Stage: " .. Assert.SafeString(stage),
		"Details: " .. Assert.FormatDetails(details),
		"Error:",
		trace,
	}, "\n")

	Assert.WriteErrorFile(config, gameId, entry)
	warn("[Y Hub] detailed error logged to " .. Assert.SafeString((config and config.ErrorFolder) or DEFAULT_ERROR_FOLDER))

	return REPORT_MARKER .. "\n" .. entry
end

function Assert.Wrap(framework, stage, details, callback)
	local success, result = xpcall(callback, function(errorObject)
		return Assert.Report(framework, stage, errorObject, details)
	end)

	if not success then
		error(result, 0)
	end

	return result
end

function Assert.StartWatcher(framework)
	if not framework then
		return false
	end
	if isReleaseFramework(framework) and not releaseDiagnosticsEnabled(framework) then
		return false
	end
	if framework.ErrorWatcherConnection then
		return true
	end

	local success, logService = pcall(function()
		return game:GetService("LogService")
	end)
	if not success or not logService or not logService.MessageOut then
		return false
	end

	local config = framework.Config or {}
	framework.ErrorMessageCache = framework.ErrorMessageCache or {}
	framework.ErrorWatcherConnection = logService.MessageOut:Connect(function(message, messageType)
		local messageTypeText = Assert.SafeString(messageType)
		local lowerType = messageTypeText:lower()
		local isError = lowerType:find("error", 1, true) ~= nil
		local isWarning = lowerType:find("warning", 1, true) ~= nil and config.LogWarnings == true

		if not isError and not isWarning then
			return
		end

		local text = Assert.SafeString(message)
		if
			text:find("[Y Hub] detailed error logged", 1, true)
			or text:find("[Y Core] detailed error logged", 1, true)
			or text:find(REPORT_MARKER, 1, true)
			or text:find(LEGACY_REPORT_MARKER, 1, true)
		then
			return
		end
		if Assert.IsExternalLogNoise(text) then
			return
		end

		local now = os.clock()
		local cacheKey = messageTypeText .. "\n" .. text
		local logServiceDedupSeconds = tonumber(config.LogServiceDedupSeconds)
			or math.max(tonumber(config.ErrorDedupSeconds or 8) * 15, DEFAULT_LOGSERVICE_DEDUP_SECONDS)
		if now - (framework.ErrorMessageCache[cacheKey] or 0) < logServiceDedupSeconds then
			return
		end
		framework.ErrorMessageCache[cacheKey] = now

		Assert.Report(framework, isError and "logservice-error" or "logservice-warning", text, {
			messageType = messageTypeText,
		})
	end)

	return true
end

function Assert.Attach(framework)
	if not framework then
		return Assert
	end

	framework.Assert = Assert

	function framework:ReportError(stage, errorObject, details)
		return Assert.Report(self, stage, errorObject, details)
	end

	function framework:RunWithErrorReport(stage, details, callback)
		return Assert.Wrap(self, stage, details, callback)
	end

	function framework:StartErrorWatcher()
		return Assert.StartWatcher(self)
	end

	return Assert
end

return Assert
