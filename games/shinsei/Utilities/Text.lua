--//Variables
local Text = {}

--//Source
function Text.StripRichText(value)
	value = tostring(value or "")
	value = value:gsub("<br%s*/>", "\n")
	value = value:gsub("<[^>]->", "")
	return value
end

function Text.Normalize(value)
	value = Text.StripRichText(value):lower()
	value = value:gsub("%s+", "")
	value = value:gsub("[^%w]", "")
	return value
end

function Text.FormatNumber(value, suffixes)
	value = tonumber(value) or 0

	for _, suffixInfo in ipairs(suffixes) do
		local suffixSize = suffixInfo[1]
		local suffixText = suffixInfo[2]

		if suffixSize <= value then
			local shortValue = value / suffixSize

			if shortValue % 1 == 0 then
				return string.format("%.0f%s", shortValue, suffixText)
			end

			return string.format("%.1f%s", shortValue, suffixText)
		end
	end

	return tostring(math.floor(value))
end

function Text.FormatTime(seconds)
	seconds = math.max(tonumber(seconds) or 0, 0)

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor(seconds % 3600 / 60)

	if hours <= 0 then
		return string.format("%dm", math.max(minutes, 0))
	end

	if minutes > 0 then
		return string.format("%dh %dm", hours, minutes)
	end

	return string.format("%dh", hours)
end

return Text
