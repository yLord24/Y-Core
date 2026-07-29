--//Imports
local Text = Require("games/shinsei/Utilities/Text.lua")

--//Variables
local RewardsSync = {}
RewardsSync.__index = RewardsSync

--//Source
function RewardsSync.new(context, statusView)
	local constants = context.Constants

	return setmetatable({
		Context = context,
		Status = statusView,
		State = context.State,
		LocalPlayer = context.LocalPlayer,
		GetRewards = context.GetRewards,
		RewardsInfo = context.RewardsInfo,
		RewardOrder = constants.RewardOrder,
		RewardText = constants.RewardText,
		RewardKeepVisible = constants.RewardKeepVisible,
		Suffixes = constants.NumberSuffixes,
	}, RewardsSync)
end

function RewardsSync:GetDisplayData()
	if not self.State.LastRewardData then
		return nil
	end

	local elapsedTime = math.max(os.clock() - self.State.LastRewardClock, 0)
	local displayData = {}

	for key, value in pairs(self.State.LastRewardData) do
		displayData[key] = value
	end

	local isPlaytimeBoosted = (tonumber(displayData.PlaytimeBoost) or 0) >= 1
	local playtimeMultiplier = isPlaytimeBoosted and 1.5 or 1

	displayData.Playtime = (tonumber(displayData.Playtime) or 0) + elapsedTime * playtimeMultiplier
	displayData.RewardPlaytime = (tonumber(displayData.RewardPlaytime) or 0) + elapsedTime * playtimeMultiplier
	displayData.PlaytimeBoost = math.max((tonumber(displayData.PlaytimeBoost) or 0) - elapsedTime, 0)

	return displayData
end

function RewardsSync:UpdateUI(rewardData)
	local interface = self.Status:GetInterface()
	local menu = interface and interface:FindFirstChild("rewardsMenu")
	local rewardsInfo = menu and menu:FindFirstChild("rewardsInfo")

	if not rewardsInfo then
		return false
	end

	local buyPlaytime = menu:FindFirstChild("buyPlaytime")
	local remainingBoost = buyPlaytime and buyPlaytime:FindFirstChild("remainingBoost")

	if remainingBoost and remainingBoost:IsA("TextLabel") then
		remainingBoost.Text = Text.FormatTime(rewardData.PlaytimeBoost)
	end

	--> Hide default rewards rows
	for _, child in ipairs(rewardsInfo:GetChildren()) do
		if child:IsA("GuiObject") and not self.RewardKeepVisible[child.Name] then
			child.Visible = false
		end
	end

	local language = self.LocalPlayer:GetAttribute("Language") or "ENG"
	local basicSeconds = self.RewardsInfo.basicReward and self.RewardsInfo.basicReward.Seconds or 9000

	for _, key in ipairs(self.RewardOrder) do
		local info = self.RewardText[key]
		local rewardValue = rewardData[key]

		if rewardValue ~= nil and info then
			local label = rewardsInfo:FindFirstChild(info.rewardInstance)

			if label and label:IsA("TextLabel") then
				label.RichText = true

				local labelText = info[language] or info.ENG or key
				local displayValue

				if key == "Points" or key == "Ryo" then
					displayValue = Text.FormatNumber(rewardValue, self.Suffixes)
				elseif key == "RewardPlaytime" then
					displayValue = Text.FormatTime(basicSeconds - (tonumber(rewardValue) or 0))
				elseif key == "Playtime" then
					displayValue = Text.FormatTime(rewardValue)
				else
					displayValue = tostring(rewardValue)
				end

				if key == "Ryo" or key == "AppearanceSpin" or key == "ClanSpin" then
					label.Text = "<font color=\"rgb(255, 224, 70)\">" .. Text.FormatNumber(rewardValue, self.Suffixes) .. "</font> " .. string.upper(labelText)
				else
					label.Text = string.upper(labelText) .. displayValue
				end

				label.Visible = true
			end
		end
	end

	return true
end

function RewardsSync:Refresh()
	if not self.State.RefreshRewards then
		return false
	end

	local refreshSuccess, rewardData = pcall(function()
		return self.GetRewards:InvokeServer()
	end)

	if not refreshSuccess or type(rewardData) ~= "table" then
		self.Context:Log("rewards-refresh-failed", {
			error = rewardData,
		})
		return false
	end

	self.State.LastRewardData = rewardData
	self.State.LastRewardClock = os.clock()
	self:UpdateUI(rewardData)

	return true
end

return RewardsSync
