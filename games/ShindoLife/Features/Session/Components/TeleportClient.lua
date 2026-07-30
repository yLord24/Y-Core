--//Variables
local TeleportClient = {}
TeleportClient.__index = TeleportClient

--//Source
function TeleportClient.new(app, sessionConfig, sessionState, serverBrowser)
	return setmetatable({
		App = app,
		Config = sessionConfig or {},
		State = sessionState or {},
		Browser = serverBrowser,
		Services = app.Services,
	}, TeleportClient)
end

function TeleportClient:TeleportToJob(jobId)
	local teleportService = self.Services.TeleportService
	local localPlayer = self.Services.LocalPlayer

	return pcall(function()
		teleportService:TeleportToPlaceInstance(game.PlaceId, tostring(jobId), localPlayer)
	end)
end

function TeleportClient:Rejoin()
	if game.JobId and tostring(game.JobId) ~= "" then
		local success, result = self:TeleportToJob(game.JobId)

		if success then
			return true, "Rejoining"
		end

		self.App.Debug:Log("rejoin-error", {
			error = result,
		})
	end

	return self:ServerHop()
end

function TeleportClient:ServerHop()
	local teleportService = self.Services.TeleportService
	local localPlayer = self.Services.LocalPlayer
	local serverId = self.Browser and self.Browser:FindHopServer()

	if serverId then
		local success, result = self:TeleportToJob(serverId)

		if success then
			self.State.LastServerId = serverId
			self.State.LastHop = os.clock()
			return true, "Server hop"
		end

		self.App.Debug:Log("serverhop-job-error", {
			error = result,
			job = serverId,
		})
	end

	local fallbackSuccess, fallbackResult = pcall(function()
		teleportService:Teleport(game.PlaceId, localPlayer)
	end)

	if fallbackSuccess then
		self.State.LastHop = os.clock()
		return true, "Teleporting"
	end

	self.App.Debug:Log("serverhop-error", {
		error = fallbackResult,
	})

	return false, tostring(fallbackResult)
end

return TeleportClient
