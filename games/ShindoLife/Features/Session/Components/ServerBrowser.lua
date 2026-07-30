--//Variables
local ServerBrowser = {}
ServerBrowser.__index = ServerBrowser

--//Source
function ServerBrowser.new(app, sessionConfig, sessionState)
	return setmetatable({
		App = app,
		Config = sessionConfig or {},
		State = sessionState or {},
		Services = app.Services,
	}, ServerBrowser)
end

function ServerBrowser:GetPage(cursor)
	local httpService = self.Services.HttpService
	local placeId = tostring(game.PlaceId)
	local requestUrl = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"

	if cursor and cursor ~= "" then
		requestUrl = requestUrl .. "&cursor=" .. httpService:UrlEncode(cursor)
	end

	local requestSuccess, response = pcall(function()
		return game:HttpGet(requestUrl)
	end)

	if not requestSuccess or typeof(response) ~= "string" then
		return nil
	end

	local decodeSuccess, decoded = pcall(function()
		return httpService:JSONDecode(response)
	end)

	if decodeSuccess and type(decoded) == "table" then
		return decoded
	end

	return nil
end

function ServerBrowser:FindHopServer()
	local maxPages = math.max(1, tonumber(self.Config.ServerHopPages) or 5)
	local cursor = nil

	for _ = 1, maxPages do
		local serverPage = self:GetPage(cursor)

		if type(serverPage) ~= "table" then
			return nil
		end

		for _, serverInfo in ipairs(serverPage.data or {}) do
			local serverId = tostring(serverInfo.id or "")
			local playing = tonumber(serverInfo.playing) or 0
			local maxPlayers = tonumber(serverInfo.maxPlayers) or 0

			if serverId ~= "" and serverId ~= tostring(game.JobId) and playing < maxPlayers then
				return serverId
			end
		end

		cursor = serverPage.nextPageCursor
		if not cursor or cursor == "" then
			break
		end

		task.wait(tonumber(self.Config.ServerHopDelay) or 0.15)
	end

	return nil
end

return ServerBrowser
