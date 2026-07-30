--//Variables
local Text = {}

--//Source
function Text.ShortJobId(jobId)
	jobId = tostring(jobId or "")

	if #jobId <= 12 then
		return jobId ~= "" and jobId or "Studio"
	end

	return jobId:sub(1, 8) .. "..."
end

return Text
