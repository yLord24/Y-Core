--//Imports
local Text = Require("games/shinsei/Utilities/Text.lua")

--//Variables
local Objectives = {}
Objectives.__index = Objectives

--//Source
function Objectives.new(context, statusView)
	local constants = context.Constants

	return setmetatable({
		Context = context,
		Status = statusView,
		State = context.State,
		RemoteSession = context.RemoteSession,
		RegisterCastGame = context.RegisterCastGame,
		RewardsInfo = context.RewardsInfo,
		ActionNames = constants.ActionNames,
		ActionColors = constants.ActionColors,
		ObjectivePool = constants.ObjectivePool,
		LocalPlayer = context.LocalPlayer,
	}, Objectives)
end

function Objectives:DetectFromUI(castUI)
	if not self.State.AutoObjectives then
		return nil
	end

	local goalInfo = self.Status:GetGoalInfo(castUI)
	local descriptionLabel = goalInfo and goalInfo:FindFirstChild("3Desc")

	if not self.Status:VisibleGui(descriptionLabel) then
		return nil
	end

	local descriptionText = Text.StripRichText(descriptionLabel.Text):lower()

	if descriptionText:find("sprinting", 1, true) or descriptionText:find("correndo", 1, true) then
		return "Sprinting"
	end

	if descriptionText:find("walking", 1, true) or descriptionText:find("andando", 1, true) then
		return "Walking"
	end

	if descriptionText:find("dashing", 1, true) or descriptionText:find("impulsionando", 1, true) then
		return "Dash"
	end

	if descriptionText:find("falling", 1, true) or descriptionText:find("caindo", 1, true) then
		return "Falling"
	end

	if descriptionText:find("jumping", 1, true) or descriptionText:find("pulando", 1, true) then
		return "Jumping"
	end

	if descriptionText:find("standing", 1, true) or descriptionText:find("parado", 1, true) then
		return "Standing"
	end

	return nil
end

function Objectives:SetRemote(castUI, objective)
	self.RemoteSession.CurrentObjective = objective

	local goalInfo = self.Status:GetGoalInfo(castUI)
	local descriptionLabel = goalInfo and goalInfo:FindFirstChild("3Desc")

	if objective then
		self.RegisterCastGame:FireServer(5, true)
	else
		self.RegisterCastGame:FireServer(5)
	end

	if not descriptionLabel or not descriptionLabel:IsA("TextLabel") then
		return
	end

	if not objective then
		descriptionLabel.Visible = false
		return
	end

	local language = self.Status:GetLanguage()
	local actionInfo = self.ActionNames[objective] or self.ActionNames.Standing
	local actionText = actionInfo[language] or actionInfo.ENG or objective
	local color = self.ActionColors[objective] or Color3.fromRGB(255, 255, 255)

	descriptionLabel.RichText = true

	if language == "PT" then
		descriptionLabel.Text = string.format(
			"DESAFIO DE PONTOS!\nFaca o jutsu enquanto esta <font color=\"rgb(%d,%d,%d)\">%s</font>",
			math.floor(color.R * 255),
			math.floor(color.G * 255),
			math.floor(color.B * 255),
			actionText
		)
	else
		descriptionLabel.Text = string.format(
			"EXTRA POINTS OBJECTIVE!\nExecute the jutsu while <font color=\"rgb(%d,%d,%d)\">%s</font>",
			math.floor(color.R * 255),
			math.floor(color.G * 255),
			math.floor(color.B * 255),
			actionText
		)
	end

	descriptionLabel.Visible = true
	descriptionLabel.TextTransparency = 0
	descriptionLabel.Size = UDim2.fromScale(1, 0.5)

	local shadow = descriptionLabel:FindFirstChild("UISHADOW")

	if shadow and shadow:IsA("ImageLabel") then
		shadow.ImageTransparency = 0.6
	end
end

function Objectives:MaybeRoll(castUI)
	if not self.State.AutoObjectives then
		return
	end

	self.RemoteSession.RandomObjectiveCast = self.RemoteSession.RandomObjectiveCast + 1

	if self.RemoteSession.RandomObjectiveCast < (self.RewardsInfo.randomObjectiveCasts or 8) then
		return
	end

	self.RemoteSession.RandomObjectiveCast = 0

	if math.random(1, 3) >= 2 then
		self:SetRemote(castUI, self.ObjectivePool[math.random(1, #self.ObjectivePool)])
	else
		self:SetRemote(castUI, nil)
	end
end

function Objectives:ForceCore(coreState)
	if not self.State.AutoObjectives or not coreState or not coreState.signStateObjective then
		return false
	end

	local objective = coreState.signStateObjective
	coreState.charAction = objective

	if coreState.charActionUI and coreState.charActionUI.Parent then
		local language = self.LocalPlayer:GetAttribute("Language") or "ENG"
		local actionText = self.ActionNames[objective]
		local actionLabel = coreState.charActionUI:FindFirstChild("Action")

		if actionLabel and actionLabel:IsA("TextLabel") then
			actionLabel.Text = actionText and (actionText[language] or actionText.ENG) or objective

			if coreState.Actions and coreState.Actions[objective] then
				actionLabel.TextColor3 = coreState.Actions[objective]
			end
		end
	end

	return true
end

return Objectives
