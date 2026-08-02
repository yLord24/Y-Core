--//Variables
local Debug = {}
Debug.__index = Debug

--//Source
local function formatValue(value)
	if typeof(value) == "Instance" then
		return value:GetFullName()
	elseif typeof(value) == "Vector3" then
		return string.format("%.2f,%.2f,%.2f", value.X, value.Y, value.Z)
	elseif typeof(value) == "CFrame" then
		return formatValue(value.Position)
	end

	return tostring(value)
end

function Debug.new(config)
	return setmetatable({
		Config = config or {},
		Buffer = {},
		LastFlushAt = 0,
	}, Debug)
end

function Debug:Line(message, data)
	local formattedLine = os.date("%H:%M:%S") .. " [" .. string.format("%.3f", os.clock() % 1000) .. "] " .. tostring(message)

	if data then
		local fields = {}

		for key, value in pairs(data) do
			fields[#fields + 1] = tostring(key) .. "=" .. formatValue(value)
		end

		table.sort(fields)

		if #fields > 0 then
			formattedLine = formattedLine .. " | " .. table.concat(fields, " ")
		end
	end

	return formattedLine
end

function Debug:Log(message, data)
	local debuggerConfig = self.Config
	local formattedLine = self:Line(message, data)

	if debuggerConfig.Console then
		print((debuggerConfig.Prefix or "[Y Hub]") .. " " .. formattedLine)
	end

	if not debuggerConfig.Enabled then
		return
	end

	self.Buffer[#self.Buffer + 1] = formattedLine

	local maxLines = tonumber(debuggerConfig.MaxLines) or 2000
	while #self.Buffer > maxLines do
		table.remove(self.Buffer, 1)
	end

	if os.clock() - (self.LastFlushAt or 0) >= (tonumber(debuggerConfig.FlushInterval) or 1) then
		self:Flush()
	end
end

function Debug:Flush()
	local debuggerConfig = self.Config
	if not debuggerConfig.Enabled or typeof(writefile) ~= "function" then
		return
	end

	self.LastFlushAt = os.clock()

	pcall(function()
		if typeof(makefolder) == "function" then
			local folderPath = debuggerConfig.Folder or "Y Hub"
			local currentPath = ""

			for folderName in tostring(folderPath):gmatch("[^/\\]+") do
				currentPath = currentPath == "" and folderName or (currentPath .. "/" .. folderName)
				pcall(makefolder, currentPath)
			end
		end

		writefile(debuggerConfig.File or "Y Hub/Framework.log", table.concat(self.Buffer, "\n"))
	end)
end

return Debug
