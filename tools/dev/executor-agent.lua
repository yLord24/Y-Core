local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Environment = (getgenv and getgenv()) or _G
local BaseUrl = tostring(Environment.YHubDevAgentUrl or Environment.YCoreDevAgentUrl or Environment.PotassiumBridgeURL or "__YCORE_DEV_BASE_URL__")
local PollInterval = tonumber(Environment.YHubDevAgentPollInterval or Environment.YCoreDevAgentPollInterval or 0.2) or 0.2
local MaxLogLines = tonumber(Environment.YHubDevAgentMaxLogs or Environment.YCoreDevAgentMaxLogs or 500) or 500

local Request = (syn and syn.request)
	or http_request
	or request
	or (http and http.request)
	or (fluxus and fluxus.request)

if not Request then
	error("YHubDevAgent: no executor HTTP request function found")
end

if BaseUrl:sub(-1) == "/" then
	BaseUrl = BaseUrl:sub(1, -2)
end

Environment.__YHubDevAgentRunning = false
Environment.__YCoreDevAgentRunning = false
task.wait(0.15)

local SessionId = tostring(math.floor(os.clock() * 1000)) .. "-" .. tostring(math.random(1000, 9999))
local Running = true
local CurrentLogs = {}

Environment.__YHubDevAgentRunning = true
Environment.__YHubDevAgentSession = SessionId
Environment.__YCoreDevAgentRunning = true
Environment.__YCoreDevAgentSession = SessionId

local function urlEncode(value)
	return tostring(value):gsub("[^%w%-%._~]", function(character)
		return string.format("%%%02X", string.byte(character))
	end)
end

local function encode(value)
	local success, result = pcall(function()
		return HttpService:JSONEncode(value)
	end)

	return success and result or "{}"
end

local function decode(value)
	local success, result = pcall(function()
		return HttpService:JSONDecode(value or "")
	end)

	return success and result or nil
end

local function requestHttp(method, route, body)
	local requestData = {
		Url = BaseUrl .. route,
		Method = method,
		Headers = {
			["Content-Type"] = "application/json",
			["Cache-Control"] = "no-cache",
		},
	}

	if body ~= nil then
		requestData.Body = encode(body)
	end

	return Request(requestData)
end

local function pushLog(...)
	local parts = {}

	for index = 1, select("#", ...) do
		parts[index] = tostring(select(index, ...))
	end

	local line = os.date("!%Y-%m-%dT%H:%M:%SZ") .. " " .. table.concat(parts, " ")

	table.insert(CurrentLogs, line)

	if #CurrentLogs > MaxLogLines then
		table.remove(CurrentLogs, 1)
	end

	print("[Y Hub Agent]", table.concat(parts, " "))
end

local function shouldRun()
	return Environment.__YHubDevAgentRunning == true and Environment.__YHubDevAgentSession == SessionId
end

local function serializeResult(value)
	local valueType = typeof(value)

	if valueType == "string" or valueType == "number" or valueType == "boolean" or value == nil then
		return tostring(value)
	end

	local success, json = pcall(function()
		return HttpService:JSONEncode(value)
	end)

	if success then
		return json
	end

	return string.format("<%s>", valueType)
end

local function runCommand(command)
	CurrentLogs = {}

	local startedAt = os.clock()
	local id = tostring(command.id or "unknown")
	local label = tostring(command.label or "command")

	pushLog("command-start", id, label)

	local loadedChunk, loadError = loadstring(tostring(command.code or ""), "YHubDevAgent:" .. id)
	local success = false
	local result = nil

	if not loadedChunk then
		result = "load-error: " .. tostring(loadError)
		pushLog(result)
	else
		success, result = pcall(loadedChunk)

		if not success then
			pushLog("runtime-error", result)
		end
	end

	local payload = {
		id = id,
		label = label,
		ok = success,
		result = serializeResult(result),
		elapsed = os.clock() - startedAt,
		logs = CurrentLogs,
		player = Players.LocalPlayer and Players.LocalPlayer.Name or "unknown",
		placeId = game.PlaceId,
		jobId = game.JobId,
	}

	local posted, postResult = pcall(function()
		return requestHttp("POST", "/result", payload)
	end)

	if not posted then
		warn("[Y Hub Agent] result post failed:", postResult)
	end
end

Environment.YHubDevAgentLog = pushLog
Environment.YCoreDevAgentLog = pushLog
Environment.YHubDevAgentRun = function(code)
	local loadedChunk, loadError = loadstring(tostring(code or ""))

	if not loadedChunk then
		return false, loadError
	end

	return pcall(loadedChunk)
end
Environment.YCoreDevAgentRun = Environment.YHubDevAgentRun
Environment.YHubDevAgentStop = function()
	Environment.__YHubDevAgentRunning = false
	Environment.__YCoreDevAgentRunning = false
end
Environment.YCoreDevAgentStop = Environment.YHubDevAgentStop

-- Compatibility with the older bridge helper names.
Environment.BridgeLog = pushLog
Environment.PotassiumBridgeRun = Environment.YHubDevAgentRun
Environment.PotassiumBridgeStop = Environment.YHubDevAgentStop

task.spawn(function()
	pushLog("agent-online", Players.LocalPlayer and Players.LocalPlayer.Name or "unknown", "session", SessionId)

	while shouldRun() do
		local success, response = pcall(function()
			local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "unknown"
			return requestHttp("GET", "/next?client=" .. urlEncode(playerName))
		end)

		if success and response and tonumber(response.StatusCode) == 200 then
			local command = decode(response.Body)

			if command and command.id then
				runCommand(command)
				task.wait(0.05)
			else
				task.wait(PollInterval)
			end
		else
			warn("[Y Hub Agent] poll failed", response and response.StatusCode or response)
			task.wait(1)
		end
	end

	Running = false
	print("[Y Hub Agent] stopped")
end)

return {
	ok = true,
	session = SessionId,
	url = BaseUrl,
	stop = function()
		Environment.__YHubDevAgentRunning = false
		Environment.__YCoreDevAgentRunning = false
		Running = false
	end,
}
