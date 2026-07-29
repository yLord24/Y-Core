--//Imports
local Text = Require("games/shinsei/Utilities/Text.lua")

--//Variables
local SkillSelector = {}
SkillSelector.__index = SkillSelector

--//Source
function SkillSelector.new(context, statusView)
	return setmetatable({
		Context = context,
		Status = statusView,
		SkillByCode = context.SkillByCode,
		SkillNameByCode = context.SkillNameByCode,
		PointModes = context.Constants.PointsModes,
	}, SkillSelector)
end

function SkillSelector:GetPreviewKeys(skill)
	local previewKeys = {}

	if type(skill.PreviewName) == "table" then
		for _, value in pairs(skill.PreviewName) do
			previewKeys[Text.Normalize(value)] = true
		end
	end

	if skill.Name then
		previewKeys[Text.Normalize(skill.Name)] = true
	end

	return previewKeys
end

function SkillSelector:FindByPreview(previewText)
	local wantedPreview = Text.Normalize(previewText)

	if wantedPreview == "" then
		return nil, nil
	end

	for code, skill in pairs(self.SkillByCode) do
		local previews = self:GetPreviewKeys(skill)

		if previews[wantedPreview] then
			return code, skill
		end
	end

	for code, skill in pairs(self.SkillByCode) do
		for preview in pairs(self:GetPreviewKeys(skill)) do
			if preview ~= "" and (preview:find(wantedPreview, 1, true) or wantedPreview:find(preview, 1, true)) then
				return code, skill
			end
		end
	end

	return nil, nil
end

function SkillSelector:GetCategory(skill)
	if not skill then
		return nil
	end

	if skill.Category == "Ninjutsu" then
		return skill.Ninjutsu or "Shinobi"
	end

	return skill.Category or skill.Ninjutsu
end

function SkillSelector:InferSelected()
	local interface = self.Status:GetInterface()
	local gameSettings = interface and interface:FindFirstChild("gameSettings")
	local scrollingFrame = gameSettings and gameSettings:FindFirstChild("ScrollingFrame")
	local selectedSkills = {}
	local selectedByCode = {}

	--> Read selected skills from original UI
	if scrollingFrame then
		for _, child in ipairs(scrollingFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "baseAbilityFrame" then
				local textButton = child:FindFirstChild("TextButton")
				local enabled = true

				if textButton and (textButton:IsA("TextLabel") or textButton:IsA("TextButton")) then
					enabled = textButton.TextTransparency < 0.75
					local code, skill = self:FindByPreview(textButton.Text)

					if enabled and code and skill and not selectedByCode[code] then
						selectedSkills[#selectedSkills + 1] = {
							Code = code,
							Skill = skill,
							Name = skill.Name or self.SkillNameByCode[code],
							Category = self:GetCategory(skill),
						}
						selectedByCode[code] = true
					end
				end
			end
		end
	end

	if #selectedSkills <= 0 then
		for code, skill in pairs(self.SkillByCode) do
			selectedSkills[#selectedSkills + 1] = {
				Code = code,
				Skill = skill,
				Name = skill.Name or self.SkillNameByCode[code],
				Category = self:GetCategory(skill),
			}
		end
	end

	table.sort(selectedSkills, function(firstSkill, secondSkill)
		return tostring(firstSkill.Name) < tostring(secondSkill.Name)
	end)

	return selectedSkills
end

function SkillSelector:InferPointsMode()
	local interface = self.Status:GetInterface()
	local gameSettings = interface and interface:FindFirstChild("gameSettings")
	local goal = gameSettings and gameSettings:FindFirstChild("PointsGoal")
	local options = goal and goal:FindFirstChild("Options")
	local byName = {
		["1Unlimited"] = "Unlimted",
		["2100Points"] = "100Points",
		["3500Points"] = "500Points",
		["41000Points"] = "1000Points",
	}

	if options then
		for _, child in ipairs(options:GetChildren()) do
			if child:IsA("TextLabel") then
				local gradient = child:FindFirstChild("UIGradient")

				if byName[child.Name] and ((gradient and gradient.Enabled) or child.TextTransparency <= 0.25) then
					return byName[child.Name]
				end
			end
		end
	end

	return "100Points"
end

function SkillSelector:GetTrainingCategories(selected)
	local categories = {}
	local categoryFound = {}

	for _, entry in ipairs(selected) do
		local category = entry.Category

		if category and not categoryFound[category] then
			categories[#categories + 1] = category
			categoryFound[category] = true
		end
	end

	return categories
end

return SkillSelector
