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
		FlushedLines = 0,
		NeedsRewrite = true,
		FlushRunning = false,
		FlushQueued = false,
		BufferGeneration = 0,
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
	if debuggerConfig.Console ~= true and debuggerConfig.Enabled ~= true then
		return
	end

	local formattedLine = self:Line(message, data)

	if debuggerConfig.Console then
		print((debuggerConfig.Prefix or "[Y Hub]") .. " " .. formattedLine)
	end

	if not debuggerConfig.Enabled then
		return
	end

	self.Buffer[#self.Buffer + 1] = formattedLine

	local maxLines = tonumber(debuggerConfig.MaxLines) or 2000
	if #self.Buffer > maxLines then
		local oldCount = #self.Buffer
		local trimCount = math.min(oldCount, math.max(oldCount - maxLines, math.max(64, math.floor(maxLines * 0.2))))
		table.move(self.Buffer, trimCount + 1, oldCount, 1)
		for index = oldCount - trimCount + 1, oldCount do
			self.Buffer[index] = nil
		end
		self.FlushedLines = math.max(0, (self.FlushedLines or 0) - trimCount)
		self.NeedsRewrite = true
		self.BufferGeneration = (self.BufferGeneration or 0) + 1
	end

	if os.clock() - (self.LastFlushAt or 0) >= (tonumber(debuggerConfig.FlushInterval) or 1) then
		self:Flush(false)
	end
end

function Debug:Flush(force)
	local debuggerConfig = self.Config
	if not debuggerConfig.Enabled or typeof(writefile) ~= "function" then
		return false
	end
	if self.FlushRunning then
		self.FlushQueued = true
		return false
	end

	local lineCount = #self.Buffer
	if (self.FlushedLines or 0) > lineCount then
		self.FlushedLines = 0
		self.NeedsRewrite = true
		self.BufferGeneration = (self.BufferGeneration or 0) + 1
	end

	local canAppend = typeof(appendfile) == "function"
	local rewrite = self.NeedsRewrite == true or not canAppend or (self.FlushedLines or 0) <= 0
	local firstLine = rewrite and 1 or ((self.FlushedLines or 0) + 1)
	if firstLine > lineCount and not (rewrite and lineCount == 0) then
		self.LastFlushAt = os.clock()
		return true
	end

	local lines = table.create(math.max(lineCount - firstLine + 1, 0))
	for index = firstLine, lineCount do
		lines[#lines + 1] = self.Buffer[index]
	end
	local payload = table.concat(lines, "\n")
	if not rewrite and payload ~= "" then
		payload = "\n" .. payload
	end

	local generation = self.BufferGeneration or 0
	self.FlushRunning = true
	self.FlushQueued = false
	self.LastFlushAt = os.clock()

	local function writeSnapshot()
		local success = pcall(function()
			if typeof(makefolder) == "function" then
				local folderPath = debuggerConfig.Folder or "Y Hub"
				local currentPath = ""

				for folderName in tostring(folderPath):gmatch("[^/\\]+") do
					currentPath = currentPath == "" and folderName or (currentPath .. "/" .. folderName)
					pcall(makefolder, currentPath)
				end
			end

			local filePath = debuggerConfig.File or "Y Hub/Framework.log"
			if rewrite then
				writefile(filePath, payload)
			else
				appendfile(filePath, payload)
			end
		end)

		if success and generation == (self.BufferGeneration or 0) then
			self.FlushedLines = lineCount
			self.NeedsRewrite = false
		elseif generation ~= (self.BufferGeneration or 0) then
			self.NeedsRewrite = true
		end
		self.FlushRunning = false

		if self.FlushQueued then
			self.FlushQueued = false
			task.defer(function()
				self:Flush(false)
			end)
		end
		return success
	end

	if force == true then
		return writeSnapshot()
	end
	task.spawn(writeSnapshot)
	return true
end

return Debug
