--//Variables
local serviceNameList = {
	"Players",
	"ReplicatedStorage",
	"RunService",
	"Workspace",
	"UserInputService",
	"HttpService",
	"ContentProvider",
	"TeleportService",
}

local Services = {}

--//Source
for _, serviceName in ipairs(serviceNameList) do
	Services[serviceName] = game:GetService(serviceName)
end

Services.LocalPlayer = Services.Players.LocalPlayer

return Services
