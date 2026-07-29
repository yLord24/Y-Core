--//Variables
local Maid = {}
Maid.__index = Maid

--//Source
function Maid.new()
	return setmetatable({
		Tasks = {},
	}, Maid)
end

function Maid:Give(cleanupTask)
	self.Tasks[#self.Tasks + 1] = cleanupTask
	return cleanupTask
end

function Maid:Cleanup()
	for index = #self.Tasks, 1, -1 do
		local cleanupTask = self.Tasks[index]
		self.Tasks[index] = nil

		if typeof(cleanupTask) == "RBXScriptConnection" then
			pcall(function()
				cleanupTask:Disconnect()
			end)
		elseif typeof(cleanupTask) == "Instance" then
			pcall(function()
				cleanupTask:Destroy()
			end)
		elseif typeof(cleanupTask) == "function" then
			pcall(cleanupTask)
		elseif typeof(cleanupTask) == "table" and typeof(cleanupTask.Destroy) == "function" then
			pcall(function()
				cleanupTask:Destroy()
			end)
		elseif typeof(cleanupTask) == "table" and typeof(cleanupTask.Cleanup) == "function" then
			pcall(function()
				cleanupTask:Cleanup()
			end)
		end
	end
end

Maid.Destroy = Maid.Cleanup

return Maid
