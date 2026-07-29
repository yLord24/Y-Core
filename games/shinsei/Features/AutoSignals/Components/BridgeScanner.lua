--//Variables
local BridgeScanner = {}
BridgeScanner.__index = BridgeScanner

--//Source
function BridgeScanner.new(context)
	return setmetatable({
		Context = context,
		Env = context.Env,
		Bridge = context.Bridge,
		State = context.State,
	}, BridgeScanner)
end

function BridgeScanner:GetRuntimeEnv()
	if type(getrenv) == "function" then
		local success, runtimeEnvironment = pcall(getrenv)

		if success and type(runtimeEnvironment) == "table" then
			return runtimeEnvironment
		end
	end

	return self.Env
end

function BridgeScanner:GetInfo(targetFunction)
	local debugLibrary = debug

	if debugLibrary and type(debugLibrary.getinfo) == "function" then
		local success, functionInfo = pcall(debugLibrary.getinfo, targetFunction)

		if success then
			return functionInfo
		end
	end

	if type(getinfo) == "function" then
		local success, functionInfo = pcall(getinfo, targetFunction)

		if success then
			return functionInfo
		end
	end

	return nil
end

function BridgeScanner:GetUpvalue(targetFunction, upvalueIndex)
	local debugLibrary = debug

	if debugLibrary and type(debugLibrary.getupvalue) == "function" then
		local success, upvalueName, upvalueValue = pcall(debugLibrary.getupvalue, targetFunction, upvalueIndex)

		if success then
			return upvalueName, upvalueValue
		end
	end

	if type(getupvalue) == "function" then
		local success, upvalueName, upvalueValue = pcall(getupvalue, targetFunction, upvalueIndex)

		if success then
			return upvalueName, upvalueValue
		end
	end

	return nil, nil
end

function BridgeScanner:GetGCList()
	if type(getgc) ~= "function" then
		return {}
	end

	local success, garbageCollectorList = pcall(getgc, true)

	if not success then
		success, garbageCollectorList = pcall(getgc)
	end

	if success and type(garbageCollectorList) == "table" then
		return garbageCollectorList
	end

	return {}
end

function BridgeScanner:LooksLikeActions(value)
	return type(value) == "table"
		and type(rawget(value, "sucessSign")) == "function"
		and type(rawget(value, "randomizeSign")) == "function"
		and type(rawget(value, "finishSignGame")) == "function"
end

function BridgeScanner:LooksLikeState(value)
	return type(value) == "table"
		and type(rawget(value, "Actions")) == "table"
		and (rawget(value, "Menu") ~= nil or rawget(value, "castGameUI") ~= nil)
end

function BridgeScanner:FindStateFromFunction(targetFunction)
	for upvalueIndex = 1, 30 do
		local _, upvalueValue = self:GetUpvalue(targetFunction, upvalueIndex)

		if upvalueValue == nil then
			break
		end

		if self:LooksLikeState(upvalueValue) then
			return upvalueValue
		end
	end

	return nil
end

function BridgeScanner:FindStateFromActions(actions)
	for _, actionValue in pairs(actions) do
		if type(actionValue) == "function" then
			local coreState = self:FindStateFromFunction(actionValue)

			if coreState then
				return coreState
			end
		end
	end

	return nil
end

function BridgeScanner:Scan(force)
	if not force and self.Bridge.Actions and self.Bridge.State and os.clock() - self.Bridge.LastScan < self.State.BridgeRescanDelay then
		return true
	end

	--> Search original cast game functions
	self.Bridge.LastScan = os.clock()

	local runtimeEnv = self:GetRuntimeEnv()
	local actions = rawget(runtimeEnv, "signCastActions") or rawget(self.Env, "signCastActions")
	local removeSign = rawget(runtimeEnv, "removeSign") or rawget(self.Env, "removeSign")
	local activeSign = rawget(runtimeEnv, "activeSign") or rawget(self.Env, "activeSign")

	if not self:LooksLikeActions(actions) then
		actions = nil
	end

	for _, garbageValue in ipairs(self:GetGCList()) do
		if not actions and self:LooksLikeActions(garbageValue) then
			actions = garbageValue
		elseif type(garbageValue) == "function" then
			local functionInfo = self:GetInfo(garbageValue)
			local functionName = functionInfo and functionInfo.name

			if not removeSign and functionName == "removeSign" then
				removeSign = garbageValue
			elseif not activeSign and functionName == "activeSign" then
				activeSign = garbageValue
			end
		end

		if actions and removeSign and activeSign then
			break
		end
	end

	local coreState = actions and self:FindStateFromActions(actions) or nil

	if actions and coreState then
		--> Save bridge
		self.Bridge.Actions = actions
		self.Bridge.State = coreState
		self.Bridge.RemoveSign = removeSign
		self.Bridge.ActiveSign = activeSign
		return true
	end

	self.Context:Log("bridge-scan-failed")
	return false
end

return BridgeScanner
