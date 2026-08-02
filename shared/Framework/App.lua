--//Imports
local Services = yrequire("shared/Framework/Services.lua")
local Maid = yrequire("shared/Framework/Maid.lua")
local Debug = yrequire("shared/Framework/Debug.lua")

--//Variables
local App = {}
App.__index = App

--//Source
local function reportAppError(framework, stage, errorObject, details)
	if framework and type(framework.ReportError) == "function" then
		return framework:ReportError(stage, errorObject, details)
	end

	local message = tostring(errorObject)
	if type(debug) == "table" and type(debug.traceback) == "function" then
		local success, trace = pcall(debug.traceback, message, 3)
		if success and type(trace) == "string" then
			return trace
		end
	end

	return message
end

function App.new(framework, config)
	return setmetatable({
		Framework = framework,
		Config = config or {},
		Services = Services,
		Maid = Maid.new(),
		Debug = Debug.new((config and config.Debug) or {}),
		Modules = {},
	}, App)
end

function App:StartModules(moduleSpecs)
	for _, moduleInfo in ipairs(moduleSpecs) do
		local modulePath = moduleInfo.Path or moduleInfo[1]
		local moduleName = moduleInfo.Name or moduleInfo[2] or modulePath
		local requiredModule = yrequire(modulePath, moduleInfo.ForceReload == true)
		local moduleInstance = requiredModule

		if type(requiredModule) == "table" and type(requiredModule.new) == "function" then
			moduleInstance = requiredModule.new(self)
		end

		self.Modules[moduleName] = moduleInstance

		if type(moduleInstance) == "table" and type(moduleInstance.Start) == "function" then
			local startSuccess, startResult = xpcall(function()
				return moduleInstance:Start()
			end, function(errorObject)
				return reportAppError(self.Framework, "app-module-start", errorObject, {
					module = moduleName,
					path = modulePath,
				})
			end)

			if startSuccess then
				self.Modules[moduleName] = startResult or moduleInstance
			else
				self.Debug:Log("module-start-error", {
					module = moduleName,
					error = startResult,
				})
			end
		end
	end

	return self
end

function App:Destroy()
	for _, moduleInstance in pairs(self.Modules) do
		if type(moduleInstance) == "table" and type(moduleInstance.Stop) == "function" then
			pcall(function()
				moduleInstance:Stop()
			end)
		elseif type(moduleInstance) == "table" and type(moduleInstance.Destroy) == "function" then
			pcall(function()
				moduleInstance:Destroy()
			end)
		end
	end

	self.Maid:Cleanup()
end

return App
