--//Variables
local SkillIndex = {}

--//Source
local function chars(text)
	local result = {}

	for index = 1, #text do
		result[#result + 1] = text:sub(index, index)
	end

	return result
end

function SkillIndex.Build(skills)
	local skillByCode = {}
	local skillNameByCode = {}

	for code, skillName in pairs(skills.signCodes or {}) do
		local skillInfo = skills[skillName]

		if type(skillInfo) == "table" then
			skillInfo.Name = skillInfo.Name or skillName
			skillInfo.signCode = skillInfo.signCode or code
			skillInfo.signKeys = skillInfo.signKeys or chars(code)
			skillByCode[code] = skillInfo
			skillNameByCode[code] = skillName
		end
	end

	return {
		ByCode = skillByCode,
		NameByCode = skillNameByCode,
		Chars = chars,
	}
end

return SkillIndex
