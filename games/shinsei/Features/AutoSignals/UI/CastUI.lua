--//Imports
local Text = Require("games/shinsei/Utilities/Text.lua")

--//Variables
local CastUI = {}
CastUI.__index = CastUI

--//Source
function CastUI.new(context, statusView)
	return setmetatable({
		Context = context,
		Status = statusView,
		Skills = context.Skills,
		SkillByCode = context.SkillByCode,
		SkillNameByCode = context.SkillNameByCode,
		CategoryColors = context.Constants.CategoryColors,
		LocalPlayer = context.LocalPlayer,
	}, CastUI)
end

function CastUI:GetFolder(coreState)
	return self.Status:GetCastUI(coreState)
end

function CastUI:GetGoalInfo(castUI)
	return self.Status:GetGoalInfo(castUI)
end

function CastUI:ExtractCode(castUI)
	local goalInfo = castUI and castUI:FindFirstChild("goalInfo")
	local jutsuLabel = goalInfo and goalInfo:FindFirstChild("2Jutsu")

	if not jutsuLabel then
		return nil
	end

	local jutsuText = Text.StripRichText(jutsuLabel.Text)
	return jutsuText:match("%-%s*([ZXCVBN]+)%s*$")
end

function CastUI:SetJutsuLabel(castUI, skill, code)
	local goalInfo = castUI and castUI:FindFirstChild("goalInfo")
	local jutsuLabel = goalInfo and goalInfo:FindFirstChild("2Jutsu")

	if not jutsuLabel or not jutsuLabel:IsA("TextLabel") then
		return
	end

	local category = skill.Category == "Ninjutsu" and skill.Ninjutsu or skill.Category
	local color = self.CategoryColors[category] or Color3.fromRGB(255, 255, 255)
	local language = self.LocalPlayer:GetAttribute("Language") or "ENG"
	local preview = skill.PreviewName and (skill.PreviewName[language] or skill.PreviewName.ENG) or skill.Name or "Jutsu"

	jutsuLabel.RichText = true
	jutsuLabel.Text = string.format(
		"<font color=\"rgb(%d,%d,%d)\">%s</font> - %s",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255),
		preview,
		code
	)
end

function CastUI:ClearIcons(castUI)
	local castingKeys = castUI and castUI:FindFirstChild("castingKeys")

	if not castingKeys then
		return
	end

	--> Clear old sign icons
	for _, child in ipairs(castingKeys:GetChildren()) do
		if child:IsA("ImageLabel") then
			child:Destroy()
		end
	end
end

function CastUI:AddSignIcon(castUI, coreState, letter)
	local castingKeys = castUI and castUI:FindFirstChild("castingKeys")

	if not castingKeys then
		return
	end

	local signTemplate = coreState and coreState.SignLog

	if not signTemplate then
		signTemplate = castingKeys:FindFirstChild("SignLog")
	end

	local signIcon

	if signTemplate then
		signIcon = signTemplate:Clone()
	else
		signIcon = Instance.new("ImageLabel")
		signIcon.BackgroundTransparency = 1
		signIcon.Size = UDim2.fromScale(1, 1)
		signIcon.ScaleType = Enum.ScaleType.Fit

		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "Key"
		keyLabel.AnchorPoint = Vector2.new(0.5, 0)
		keyLabel.Position = UDim2.fromScale(0.5, 0.6)
		keyLabel.Size = UDim2.fromScale(0.5, 0.5)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Font = Enum.Font.Fondamento
		keyLabel.TextScaled = true
		keyLabel.TextStrokeTransparency = 0.5
		keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		keyLabel.Parent = signIcon
	end

	signIcon.Name = "YAutoSign"
	signIcon.Visible = true
	signIcon.ImageTransparency = 0
	signIcon.Size = UDim2.fromScale(1, 1)

	local keyLabel = signIcon:FindFirstChild("Key")

	if keyLabel and keyLabel:IsA("TextLabel") then
		keyLabel.Text = letter
		keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		keyLabel.TextTransparency = 0
		keyLabel.TextStrokeTransparency = 0.5
	end

	local info = self.Skills.signInfo and self.Skills.signInfo[letter]

	if info and info.Image then
		signIcon.Image = info.Image
	end

	signIcon.Parent = castingKeys
end

function CastUI:ShowClock(castUI, elapsed)
	local castingClock = castUI and castUI:FindFirstChild("castingClock")
	local clockLabel = castingClock and castingClock:FindFirstChild("Label")

	if castingClock then
		castingClock.Visible = true
	end

	if clockLabel and clockLabel:IsA("TextLabel") then
		local language = self.LocalPlayer:GetAttribute("Language") or "ENG"

		if language == "PT" then
			clockLabel.Text = "TEMPO DE EXECUCAO: " .. string.format("%.2f", elapsed)
		else
			clockLabel.Text = "CASTING TIME: " .. string.format("%.2f", elapsed)
		end
	end
end

function CastUI:CountdownReady(castUI)
	local countdown = castUI and castUI:FindFirstChild("Countdown")
	local base = countdown and countdown:FindFirstChild("Base")

	if not base or not base:IsA("TextLabel") then
		return true
	end

	if not base.Visible or base.TextTransparency >= 0.8 then
		return true
	end

	return tostring(base.Text):upper() == "GO!"
end

return CastUI
