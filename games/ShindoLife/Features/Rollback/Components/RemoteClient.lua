--//Imports
local Guard = yrequire("games/ShindoLife/Utilities/Guard.lua")
local RemoteMask = yrequire("games/ShindoLife/Utilities/RemoteMask.lua")

--//Variables
local RemoteClient = {}
RemoteClient.__index = RemoteClient
local unpackValues = table.unpack or unpack

--//Source
function RemoteClient.new(app, rollbackConfig, rollbackState)
	return setmetatable({
		App = app,
		Config = rollbackConfig or {},
		State = rollbackState or {},
		Services = app.Services,
		Mask = RemoteMask.new(app, app.Config.RemoteMask or {}),
	}, RemoteClient)
end

function RemoteClient:GetRemote()
	local localPlayer = self.Services.LocalPlayer
	local remoteName = tostring(self.Config.RemoteName or "startevent")
	local remote = localPlayer and localPlayer:FindFirstChild(remoteName)

	if remote then
		return remote
	end

	local waitSuccess, waitResult = pcall(function()
		return localPlayer and localPlayer:WaitForChild(remoteName, 2)
	end)

	if waitSuccess then
		return waitResult
	end

	return nil
end

function RemoteClient:GetPayloadValue(enabled)
	if enabled == false then
		return tostring(self.Config.OffValue or "0,0,0")
	end

	return tostring(self.Config.OnValue or "0,0,") .. string.char(tonumber(self.Config.OnValueByte) or 255)
end

function RemoteClient:CreatePayload(enabled)
	local payload = {}
	local valueName = tostring(self.Config.ValueName or "beardcolor")
	local value = self:GetPayloadValue(enabled == true)

	if math.random(1, 2) == 1 then
		payload[1] = valueName
		payload[2] = value
	else
		payload[2] = value
		payload[1] = valueName
	end

	return payload
end

function RemoteClient:CheckCooldown()
	local currentTime = os.clock()
	local cooldown = tonumber(self.Config.Cooldown) or 0
	local elapsed = currentTime - (self.State.LastTrigger or 0)

	if cooldown > 0 and elapsed < cooldown then
		return false, string.format("Cooldown %.1fs", cooldown - elapsed)
	end

	return true
end

function RemoteClient:Fire(enabled)
	local cooldownReady, cooldownMessage = self:CheckCooldown()

	if not cooldownReady then
		return false, cooldownMessage
	end

	local remote = self:GetRemote()

	if not remote or typeof(remote.FireServer) ~= "function" then
		return false, "startevent not found"
	end

	local success, result = self.Mask:Run(function()
		local payload = self:CreatePayload(enabled == true)
		return remote:FireServer(unpackValues(payload))
	end, self.Config.Mask)

	if not success then
		if Guard.IsDevelopment(self.App) then
			self.App.Debug:Log("remote-error", {
				error = result,
			})
		end

		return false, Guard.IsDevelopment(self.App) and tostring(result) or nil
	end

	self.State.LastTrigger = os.clock()

	if Guard.IsDevelopment(self.App) then
		self.App.Debug:Log("remote-fired", {
			enabled = enabled == true,
			remote = remote.Name,
			value = self.Config.ValueName,
		})
	end

	return true, enabled and "Rollback enabled" or "Rollback disabled"
end

return RemoteClient
